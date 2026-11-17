import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jlyj.makcabxa02y.icu',
  );

  static const resourceBaseUrl = String.fromEnvironment(
    'RESOURCE_BASE_URL',
    defaultValue: '',
  );

  static const appBrand = String.fromEnvironment(
    'APP_BRAND',
    defaultValue: '金灵优记',
  );

  static const agreementPageUrl = String.fromEnvironment(
    'AGREEMENT_PAGE_URL',
    defaultValue: '',
  );

  static const agreementOperatorName = String.fromEnvironment(
    'AGREEMENT_OPERATOR_NAME',
    defaultValue: '',
  );

  static const agreementContactEmail = String.fromEnvironment(
    'AGREEMENT_CONTACT_EMAIL',
    defaultValue: '',
  );

  static ({String operatorName, String contactEmail}) get agreementIdentity {
    return (
      operatorName: agreementOperatorName,
      contactEmail: agreementContactEmail,
    );
  }

  static String get platformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      _ => defaultTargetPlatform.name,
    };
  }
}
