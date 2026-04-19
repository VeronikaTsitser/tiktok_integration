import 'package:flutter/services.dart';

/// Log level for the TikTok Business SDK on Android (`TikTokBusinessSdk.LogLevel`).
enum TikTokSdkLogLevel {
  none,
  info,
  warn,
  debug,
}

String _logLevelChannelName(TikTokSdkLogLevel level) {
  switch (level) {
    case TikTokSdkLogLevel.none:
      return 'none';
    case TikTokSdkLogLevel.info:
      return 'info';
    case TikTokSdkLogLevel.warn:
      return 'warn';
    case TikTokSdkLogLevel.debug:
      return 'debug';
  }
}

class TiktokIntegration {
  static const MethodChannel _channel = MethodChannel('tiktok_integration');

  /// Initializes the TikTok SDK with [appId], [ttAppId] and [appSecret].
  ///
  /// [debugMode] enables the SDK debug / test-event2s mode (`TTConfig.openDebugMode()`).
  /// [logLevel] sets native log verbosity; if omitted and [debugMode] is `true`,
  /// [TikTokSdkLogLevel.debug] is applied by default on Android.
  ///
  /// See the [Android integration guide](https://business-api.tiktok.com/portal/docs/android-integration-steps/v1.3).
  static Future<void> initializeSdk(
    String appId,
    String ttAppId, {
    required String appSecret,
    bool debugMode = false,
    TikTokSdkLogLevel? logLevel,
  }) async {
    try {
      final args = <String, dynamic>{
        'appId': appId,
        'ttAppId': ttAppId,
        'appSecret': appSecret,
        'debugMode': debugMode,
      };
      if (logLevel != null) {
        args['logLevel'] = _logLevelChannelName(logLevel);
      }
      await _channel.invokeMethod('initializeSdk', args);
    } on PlatformException catch (e) {
      print("Error initializing TikTok SDK: ${e.message}");
    }
  }

  /// Whether the SDK is in debug mode after initialization (`TikTokBusinessSdk.isInSdkDebugMode()`).
  static Future<bool> isSdkDebugMode() async {
    try {
      final value = await _channel.invokeMethod<bool>('isSdkDebugMode');
      return value ?? false;
    } on PlatformException catch (e) {
      print("Error reading TikTok SDK debug mode: ${e.message}");
      return false;
    }
  }

  /// Test-events code when debug mode is on (`TikTokBusinessSdk.getTestEventCode()`).
  static Future<String> getSdkTestEventCode() async {
    try {
      final value = await _channel.invokeMethod<String>('getSdkTestEventCode');
      return value ?? '';
    } on PlatformException catch (e) {
      print("Error reading TikTok SDK test event code: ${e.message}");
      return '';
    }
  }

  /// Binds the current app session to a user in TikTok Events Manager.
  ///
  /// Вызывайте при входе, регистрации, обновлении профиля (при смене аккаунта —
  /// сначала [logout], затем [identify]), при восстановлении сохранённой сессии.
  static Future<void> identify(
    String externalId, {
    String? externalUserName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final args = <String, dynamic>{'externalId': externalId};
      if (externalUserName != null) {
        args['externalUserName'] = externalUserName;
      }
      if (phoneNumber != null) {
        args['phoneNumber'] = phoneNumber;
      }
      if (email != null) {
        args['email'] = email;
      }
      await _channel.invokeMethod('identify', args);
    } on PlatformException catch (e) {
      print("Error identifying TikTok user: ${e.message}");
    }
  }

  /// Сбрасывает привязку пользователя (выход, смена аккаунта). Затем вызовите [identify].
  static Future<void> logout() async {
    try {
      await _channel.invokeMethod('logout');
    } on PlatformException catch (e) {
      print("Error TikTok SDK logout: ${e.message}");
    }
  }

  static Future<void> trackEvent(String eventName,
      {String? eventId, Map<String, dynamic>? eventParams}) async {
    try {
      if (eventId != null) {
        await _channel.invokeMethod('trackEvent', {
          'eventName': eventName,
          'eventId': eventId,
        });
      } else if (eventParams != null) {
        await _channel.invokeMethod('trackEvent', {
          'eventName': eventName,
          'eventParams': eventParams,
        });
      }
    } on PlatformException catch (e) {
      print("Error tracking event: ${e.message}");
    }
  }
}
