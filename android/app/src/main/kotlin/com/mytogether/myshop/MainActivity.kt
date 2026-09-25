package com.mytogether.myshop

import android.os.Bundle
import android.content.Intent
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge for Android 15+ (required to avoid Play Console warning)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mytogether/active_call").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val callerName = call.argument<String>("callerName") ?: "Ongoing Call"
                    val baseTime   = call.argument<Long>("baseTime") ?: 0L
                    val intent = Intent(this, ActiveCallService::class.java).apply {
                        putExtra("callerName", callerName)
                        putExtra("baseTime",   baseTime)
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "update" -> {
                    val callerName = call.argument<String>("callerName") ?: "Ongoing Call"
                    val baseTime   = call.argument<Long>("baseTime") ?: 0L
                    val intent = Intent(this, ActiveCallService::class.java).apply {
                        putExtra("callerName", callerName)
                        putExtra("baseTime",   baseTime)
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stop" -> {
                    val intent = Intent(this, ActiveCallService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
