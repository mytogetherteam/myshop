package com.mytogether.myshop

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat

class ActiveCallService : Service() {

    companion object {
        const val CHANNEL_ID      = "active_call_channel_v2"
        const val NOTIFICATION_ID = 2001
        const val ACTION_END_CALL = "com.mytogether.myshop.ACTION_END_CALL"

        var isRunning    = false
        private var callerName   = "Ongoing Call"
        private var callBaseTime = 0L
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_END_CALL) {
            stopSelf()
            return START_NOT_STICKY
        }

        callerName   = intent?.getStringExtra("callerName") ?: "Ongoing Call"
        val baseTime = intent?.getLongExtra("baseTime", 0L) ?: 0L
        callBaseTime = if (baseTime > 0) baseTime else SystemClock.elapsedRealtime()

        if (!isRunning) {
            isRunning = true
            val notification = buildNotification()
            promoteToForeground(notification)
        } else {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification())
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPi = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val endCallIntent = Intent(this, ActiveCallService::class.java).apply {
            action = ACTION_END_CALL
        }
        val endCallPi = PendingIntent.getService(
            this, 1, endCallIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val messengerGreen = Color.parseColor("#22C55E")

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(callerName)
            .setContentText("Voice call in progress")
            .setSubText("My Shop")
            .setUsesChronometer(true)
            .setChronometerCountDown(false)
            .setWhen(System.currentTimeMillis() - (SystemClock.elapsedRealtime() - callBaseTime))
            .setShowWhen(true)
            .setSmallIcon(android.R.drawable.sym_action_call)
            .setColor(messengerGreen)
            .setColorized(true)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(contentPi)
            .setAutoCancel(false)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "End Call",
                endCallPi
            )
            .build()
    }

    private fun promoteToForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
            } else {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            }
            try {
                startForeground(NOTIFICATION_ID, notification, type)
            } catch (e: Exception) {
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Active Calls",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows ongoing VoIP calls"
                lightColor  = Color.parseColor("#22C55E")
                enableLights(true)
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
}