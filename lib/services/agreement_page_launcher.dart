import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

abstract final class AgreementPageLauncher {
  static Future<bool> open(String protocolKey) async {
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        AppConfig.agreementPageUrl.trim().isEmpty) {
      return false;
    }
    final base = Uri.tryParse(AppConfig.agreementPageUrl.trim());
    if (base == null || !base.hasScheme) return false;
    final identity = AppConfig.agreementIdentity;
    final uri = base.replace(
      queryParameters: {
        ...base.queryParameters,
        'type': protocolKey,
        'dy': 'ios',
        if (identity.operatorName.isNotEmpty) 'operator': identity.operatorName,
        if (identity.contactEmail.isNotEmpty) 'email': identity.contactEmail,
      },
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } on Object {
      return false;
    }
  }
}
