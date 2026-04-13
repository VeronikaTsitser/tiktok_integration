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

  /// Initializes the TikTok SDK with [appId] and [ttAppId].
  ///
  /// [debugMode] enables the SDK debug / test-events mode (`TTConfig.openDebugMode()`).
  /// [logLevel] sets native log verbosity; if omitted and [debugMode] is `true`,
  /// [TikTokSdkLogLevel.debug] is applied by default on Android.
  ///
  /// See the [Android integration guide](https://business-api.tiktok.com/portal/docs/android-integration-steps/v1.3).
  static Future<void> initializeSdk(
    String appId,
    String ttAppId, {
    bool debugMode = false,
    TikTokSdkLogLevel? logLevel,
  }) async {
    try {
      final args = <String, dynamic>{
        'appId': appId,
        'ttAppId': ttAppId,
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
