import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.locationName,
    required this.todayMin,
    required this.todayMax,
    required this.tomorrowMin,
    required this.tomorrowMax,
    required this.precipitationProbability,
    required this.currentTemperature,
    required this.humidity,
    required this.condition,
    required this.fetchedAt,
  });

  final String locationName;
  final double todayMin;
  final double todayMax;
  final double? tomorrowMin;
  final double? tomorrowMax;
  final int precipitationProbability;
  final double currentTemperature;
  final int humidity;
  final String condition;
  final DateTime fetchedAt;

  bool get hasRisk =>
      todayMax >= 35 ||
      (tomorrowMin != null && todayMin - tomorrowMin! >= 5) ||
      precipitationProbability >= 70;

  String get headline => '${currentTemperature.round()}°C · $condition';

  String get description {
    final next = tomorrowMin == null || tomorrowMax == null
        ? ''
        : ' 随后 24 小时 ${tomorrowMin!.round()}–${tomorrowMax!.round()}°C。';
    return '$locationName · 未来 24 小时 '
        '${todayMin.round()}–${todayMax.round()}°C，湿度 $humidity%。'
        '$next${hasRisk ? '建议检查温湿度、通风与饮水。' : '天气平稳，按日常计划照护。'}';
  }
}

class WeatherService {
  static const _knownCities = <String, (double, double)>{
    '上海': (31.2304, 121.4737),
    '北京': (39.9042, 116.4074),
    '广州': (23.1291, 113.2644),
    '深圳': (22.5431, 114.0579),
    '成都': (30.5728, 104.0668),
    '杭州': (30.2741, 120.1551),
    '南京': (32.0603, 118.7969),
    '武汉': (30.5928, 114.3055),
    '西安': (34.3416, 108.9398),
    '重庆': (29.5630, 106.5516),
    '天津': (39.0842, 117.2009),
    '苏州': (31.2989, 120.5853),
  };
  static WeatherSnapshot? _cache;
  static String? _cacheCity;
  static DateTime? _cacheTime;
  static Future<WeatherSnapshot?>? _inFlight;
  static String? _inFlightCity;
  static final Map<String, (double, double)> _coordinateCache = {};

  static Future<WeatherSnapshot?> fetchForCity(String city) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Future.value(null);
    }
    if (_cache != null &&
        _cacheCity == city &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < const Duration(minutes: 20)) {
      return Future.value(_cache);
    }
    if (_inFlight != null && _inFlightCity == city) return _inFlight!;
    final future = _fetch(city);
    _inFlight = future;
    _inFlightCity = city;
    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
        _inFlightCity = null;
      }
    });
    return future;
  }

  static Future<WeatherSnapshot?> _fetch(String city) async {
    final parts = city.split('·').map((item) => item.trim()).toList();
    final name = parts.last.replaceFirst(RegExp(r'市$'), '');
    final province = parts.length > 1 ? parts.first : null;
    final coordinate = await _resolveCoordinate(name, province: province);
    if (coordinate == null) return null;
    try {
      final response = await http
          .get(
            Uri.https(
              'api.met.no',
              '/weatherapi/locationforecast/2.0/compact',
              {
                'lat': coordinate.$1.toStringAsFixed(4),
                'lon': coordinate.$2.toStringAsFixed(4),
              },
            ),
            headers: const {
              'User-Agent': 'JinlingYouji/1.0 contact@petcare.local',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final timeseries =
          (data['properties'] as Map<String, dynamic>?)?['timeseries']
              as List<dynamic>?;
      if (timeseries == null || timeseries.isEmpty) return null;
      final now = DateTime.now();
      final entries = timeseries
          .map((item) => _MetEntry.fromJson(item as Map<String, dynamic>))
          .whereType<_MetEntry>()
          .toList();
      if (entries.isEmpty) return null;
      final current =
          entries.where((entry) => !entry.time.isAfter(now)).lastOrNull ??
          entries.first;
      final middle = now.add(const Duration(hours: 24));
      final end = now.add(const Duration(hours: 48));
      final firstRange = entries
          .where(
            (entry) => !entry.time.isBefore(now) && entry.time.isBefore(middle),
          )
          .toList();
      final secondRange = entries
          .where(
            (entry) => !entry.time.isBefore(middle) && entry.time.isBefore(end),
          )
          .toList();
      if (firstRange.isEmpty) return null;
      final firstTemperatures = firstRange.map((entry) => entry.temperature);
      final secondTemperatures = secondRange.map((entry) => entry.temperature);
      final rainHours = firstRange.where(
        (entry) => entry.precipitation >= 0.1 || _isRain(entry.symbolCode),
      );
      final maxRain = firstRange.fold<double>(
        0,
        (value, entry) =>
            entry.precipitation > value ? entry.precipitation : value,
      );
      final rainChance = rainHours.isEmpty
          ? 0
          : (35 + rainHours.length * 7 + maxRain * 12).round().clamp(35, 95);
      final snapshot = WeatherSnapshot(
        locationName: name,
        todayMin: firstTemperatures.reduce((a, b) => a < b ? a : b),
        todayMax: firstTemperatures.reduce((a, b) => a > b ? a : b),
        tomorrowMin: secondTemperatures.isEmpty
            ? null
            : secondTemperatures.reduce((a, b) => a < b ? a : b),
        tomorrowMax: secondTemperatures.isEmpty
            ? null
            : secondTemperatures.reduce((a, b) => a > b ? a : b),
        precipitationProbability: rainChance,
        currentTemperature: current.temperature,
        humidity: current.humidity,
        condition: _condition(current.symbolCode),
        fetchedAt: DateTime.now(),
      );
      _cache = snapshot;
      _cacheCity = city;
      _cacheTime = DateTime.now();
      return snapshot;
    } on Object {
      return null;
    }
  }

  static Future<(double, double)?> _resolveCoordinate(
    String name, {
    String? province,
  }) async {
    final known = _knownCities[name];
    if (known != null) return known;
    final cacheKey = '${province ?? ''}:$name';
    final cached = _coordinateCache[cacheKey];
    if (cached != null) return cached;
    final hasSpecialSuffix =
        name.endsWith('地区') || name.endsWith('自治州') || name.endsWith('盟');
    final candidates = hasSpecialSuffix ? [name] : ['$name市', name];
    for (final candidate in candidates) {
      try {
        final response = await http
            .get(
              Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
                'name': candidate,
                'count': '10',
                'language': 'zh',
                'format': 'json',
                'countryCode': 'CN',
              }),
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawResults = data['results'] as List<dynamic>?;
        if (rawResults == null || rawResults.isEmpty) continue;
        final results = rawResults
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry('$key', value)))
            .toList();
        final matching = province == null
            ? results
            : results.where((item) {
                final admin = item['admin1']?.toString() ?? '';
                return admin.contains(province) || province.contains(admin);
              }).toList();
        if (matching.isEmpty) continue;
        matching.sort((a, b) {
          final aAdmin = (a['feature_code']?.toString() ?? '').startsWith(
            'PPLA',
          );
          final bAdmin = (b['feature_code']?.toString() ?? '').startsWith(
            'PPLA',
          );
          if (aAdmin != bAdmin) return aAdmin ? -1 : 1;
          return ((b['population'] as num?) ?? 0).compareTo(
            (a['population'] as num?) ?? 0,
          );
        });
        final first = matching.first;
        final latitude = (first['latitude'] as num?)?.toDouble();
        final longitude = (first['longitude'] as num?)?.toDouble();
        if (latitude == null || longitude == null) continue;
        final coordinate = (latitude, longitude);
        _coordinateCache[cacheKey] = coordinate;
        return coordinate;
      } on Object {
        continue;
      }
    }
    return null;
  }

  static bool _isRain(String symbolCode) {
    final code = symbolCode.toLowerCase();
    return code.contains('rain') ||
        code.contains('drizzle') ||
        code.contains('thunder');
  }

  static String _condition(String symbolCode) {
    final code = symbolCode.toLowerCase();
    if (code.contains('thunder')) return '雷雨';
    if (code.contains('snow')) return '降雪';
    if (code.contains('rain') || code.contains('drizzle')) return '有雨';
    if (code.contains('fog')) return '有雾';
    if (code.contains('cloudy')) {
      return code.contains('partly') ? '多云' : '阴';
    }
    if (code.contains('fair')) return '晴间多云';
    if (code.contains('clearsky')) return '晴';
    return '天气';
  }
}

class _MetEntry {
  const _MetEntry({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.symbolCode,
  });

  final DateTime time;
  final double temperature;
  final int humidity;
  final double precipitation;
  final String symbolCode;

  static _MetEntry? fromJson(Map<String, dynamic> raw) {
    final time = DateTime.tryParse(raw['time']?.toString() ?? '')?.toLocal();
    final data = raw['data'] as Map<String, dynamic>?;
    final details =
        (data?['instant'] as Map<String, dynamic>?)?['details']
            as Map<String, dynamic>?;
    final temperature = (details?['air_temperature'] as num?)?.toDouble();
    if (time == null || temperature == null) return null;
    final next =
        data?['next_1_hours'] as Map<String, dynamic>? ??
        data?['next_6_hours'] as Map<String, dynamic>? ??
        data?['next_12_hours'] as Map<String, dynamic>?;
    final nextDetails = next?['details'] as Map<String, dynamic>?;
    final summary = next?['summary'] as Map<String, dynamic>?;
    return _MetEntry(
      time: time,
      temperature: temperature,
      humidity: (details?['relative_humidity'] as num?)?.round() ?? 0,
      precipitation:
          (nextDetails?['precipitation_amount'] as num?)?.toDouble() ?? 0,
      symbolCode: summary?['symbol_code']?.toString() ?? '',
    );
  }
}
