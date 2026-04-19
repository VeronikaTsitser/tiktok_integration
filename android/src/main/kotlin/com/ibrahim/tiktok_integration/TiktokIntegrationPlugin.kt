package com.ibrahim.tiktok_integration

import android.content.Context
import androidx.annotation.NonNull
import com.tiktok.TikTokBusinessSdk

import org.json.JSONObject
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** TiktokIntegrationPlugin */
class TiktokIntegrationPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tiktok_integration")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initializeSdk" -> initializeSdk(call, result)
      "identify" -> identify(call, result)
      "logout" -> logout(result)
      "trackEvent" -> trackEvent(call, result)
      "isSdkDebugMode" -> isSdkDebugMode(result)
      "getSdkTestEventCode" -> getSdkTestEventCode(result)
      else -> result.notImplemented()
    }
  }

  private fun parseLogLevel(level: String?): TikTokBusinessSdk.LogLevel? {
    if (level == null) return null
    return when (level.lowercase()) {
      "none" -> TikTokBusinessSdk.LogLevel.NONE
      "info" -> TikTokBusinessSdk.LogLevel.INFO
      "warn" -> TikTokBusinessSdk.LogLevel.WARN
      "debug" -> TikTokBusinessSdk.LogLevel.DEBUG
      else -> null
    }
  }

  private fun initializeSdk(call: MethodCall, result: Result) {
    val appId = call.argument<String>("appId")
    val ttAppId = call.argument<String>("ttAppId")
    val appSecret = call.argument<String>("appSecret")
    if (appId != null && ttAppId != null && appSecret != null) {
      val debugMode = call.argument<Boolean>("debugMode") ?: false
      val logLevelArg = parseLogLevel(call.argument<String>("logLevel"))
      val ttConfig = TikTokBusinessSdk.TTConfig(context, appSecret)
        .setAppId(appId)
        .setTTAppId(ttAppId)

      if (debugMode) {
        ttConfig.openDebugMode()
      }
      val effectiveLogLevel = logLevelArg
        ?: if (debugMode) TikTokBusinessSdk.LogLevel.DEBUG else null
      if (effectiveLogLevel != null) {
        ttConfig.setLogLevel(effectiveLogLevel)
      }

      TikTokBusinessSdk.initializeSdk(ttConfig)
      result.success("TikTok SDK initialized successfully")
    } else {
      result.error("INVALID_ARGUMENT", "App ID and TT App ID are required", null)
    }
  }

  private fun identify(call: MethodCall, result: Result) {
    val externalId = call.argument<String>("externalId")
    if (externalId.isNullOrBlank()) {
      result.error("INVALID_ARGUMENT", "externalId is required", null)
      return
    }
    val externalUserName = call.argument<String>("externalUserName")
    val phoneNumber = call.argument<String>("phoneNumber")
    val email = call.argument<String>("email")
    TikTokBusinessSdk.identify(externalId, externalUserName, phoneNumber, email)
    result.success("User identified successfully")
  }

  private fun logout(result: Result) {
    TikTokBusinessSdk.logout()
    result.success("User logged out successfully")
  }

  private fun trackEvent(call: MethodCall, result: Result) {
    val eventName = call.argument<String>("eventName")
    val eventId = call.argument<String>("eventId")
    val eventParams = call.argument<Map<String, Any>>("eventParams")

    if (eventName != null) {
      if (eventId != null) {
        // Use the first trackEvent signature
        TikTokBusinessSdk.trackEvent(eventName, eventId)
        result.success("Event $eventName with ID $eventId tracked successfully")
      } else if (eventParams != null) {
        // Use the second trackEvent signature with JSONObject
        val jsonObject = JSONObject(eventParams)
        TikTokBusinessSdk.trackEvent(eventName, jsonObject)
        result.success("Event $eventName with parameters tracked successfully")
      } else {
        result.error("INVALID_ARGUMENT", "Either eventId or eventParams is required", null)
      }
    } else {
      result.error("INVALID_ARGUMENT", "Event name is required", null)
    }
  }

  private fun isSdkDebugMode(result: Result) {
    result.success(TikTokBusinessSdk.isInSdkDebugMode())
  }

  private fun getSdkTestEventCode(result: Result) {
    result.success(TikTokBusinessSdk.getTestEventCode())
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
