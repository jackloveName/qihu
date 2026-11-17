import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/china_cities.dart';
import 'app_widgets.dart';

class CitySelectionField extends StatelessWidget {
  const CitySelectionField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = ChinaCities.match(value);
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.hair),
      ),
      child: InkWell(
        onTap: () async {
          final city = await CityPickerSheet.show(context, current: value);
          if (city != null) onChanged(city.value);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.location_city_outlined,
                color: AppColors.muted,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  selected?.label ?? value,
                  style: AppText.body(13.5),
                ),
              ),
              const Icon(
                Icons.search_rounded,
                color: AppColors.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({super.key, required this.current});

  final String? current;

  static Future<ChinaCity?> show(BuildContext context, {String? current}) {
    return showModalBottomSheet<ChinaCity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x70121C18),
      builder: (_) => CityPickerSheet(current: current),
    );
  }

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final _searchController = TextEditingController();
  List<ChinaCity> _results = ChinaCities.all;
  late final ChinaCity? _selected = ChinaCities.match(widget.current ?? '');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_search);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_search)
      ..dispose();
    super.dispose();
  }

  void _search() {
    setState(() => _results = ChinaCities.search(_searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    final groupedResults = <String, List<ChinaCity>>{};
    for (final city in _results) {
      groupedResults.putIfAbsent(city.province, () => []).add(city);
    }
    final groups = groupedResults.entries.toList();
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.86,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hair2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('选择城市', style: AppText.display(20)),
                      const SizedBox(height: 2),
                      Text(
                        '2025–2026 行政区划 · ${ChinaCities.all.length} 个城市',
                        style: AppText.body(9.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: Icons.close_rounded,
                  size: 32,
                  onPressed: () => Navigator.pop(context),
                  foreground: AppColors.muted,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              key: const ValueKey('city-search-field'),
              controller: _searchController,
              style: AppText.body(13.5),
              decoration: const InputDecoration(
                hintText: '搜索城市或省份',
                prefixIcon: Icon(Icons.search_rounded, size: 19),
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const EmptyState(title: '没有找到城市', message: '请尝试输入城市名称或所属省份。')
                : ListView.builder(
                    key: const ValueKey('city-search-results'),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.paddingOf(context).bottom + 18,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? 2 : 15,
                              bottom: 8,
                              left: 3,
                            ),
                            child: Text(
                              group.key,
                              style: AppText.body(
                                10,
                                color: AppColors.brass,
                                weight: FontWeight.w700,
                                spacing: 0.8,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              for (final city in group.value)
                                Builder(
                                  builder: (context) {
                                    final active =
                                        city.value == _selected?.value;
                                    return Material(
                                      color: active
                                          ? AppColors.brandWash
                                          : AppColors.paper2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        side: BorderSide(
                                          color: active
                                              ? AppColors.brandLine
                                              : AppColors.hair,
                                        ),
                                      ),
                                      child: InkWell(
                                        key: ValueKey(
                                          'city-option-${city.province}-${city.name}',
                                        ),
                                        onTap: () =>
                                            Navigator.pop(context, city),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            city.name,
                                            style: AppText.body(
                                              11.5,
                                              color: active
                                                  ? AppColors.brand
                                                  : AppColors.ink2,
                                              weight: active
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
