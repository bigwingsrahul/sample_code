package com.dev.bigwings

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import com.google.firebase.messaging.FirebaseMessaging

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.yourapp/fcm"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)


        methodChannel = MethodChannel(flutterEngine.dartExecutor, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeFCM" -> {
                    // Initialize FCM or perform other setup as needed
                    result.success(null)
                }
                "getToken" -> {
                    FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                        if (!task.isSuccessful) {
                            result.error("UNAVAILABLE", "FCM token not available", null)
                            return@addOnCompleteListener
                        }
                        result.success(task.result)
                    }
                }
                "onMessageReceived" -> {
                    result.success(call.arguments)
                }
                "startLocationService" -> {
                    val serviceIntent = Intent(this, LocationService::class.java)
                    startService(serviceIntent)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    companion object {
        lateinit var methodChannel: MethodChannel
        lateinit var activity: MainActivity
//        var methodChannel: MethodChannel? = null
    }
}
