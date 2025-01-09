package com.dev.bigwings

import android.app.NotificationManager
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import java.util.Locale

class MyFirebaseMessagingService : FirebaseMessagingService(), TextToSpeech.OnInitListener {

    private var mTts: TextToSpeech? = null

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Extract notification data
        val title = remoteMessage.data["title"]
        val body = remoteMessage.data["body"]

        // Log the message received (optional)
        println("onMessageReceived: Title = $title, Body = $body")


        Handler(Looper.getMainLooper()).post {
            MainActivity.methodChannel.invokeMethod("onMessageReceived", remoteMessage.data)
        }


        // Create a notification and display it
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        val notificationBuilder = NotificationCompat.Builder(this, "service_channel")
            .setSmallIcon(R.mipmap.ic_launcher) // Your app icon
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)

        notificationManager.notify(0, notificationBuilder.build())

        // Start Foreground Service to handle TTS
        Log.d("TAG", "onMessageReceived: $title")

        // Initialize TTS Engine only once
        if (mTts == null) {
            mTts = TextToSpeech(this, this)
        }

        // Ensure that TTS initialization happens on the main thread
        Handler(Looper.getMainLooper()).postDelayed({
            body?.let {
                // Set TTS language and speak the text
                mTts?.setLanguage(Locale.US)
                mTts?.speak(it, TextToSpeech.QUEUE_FLUSH, null, null)
            }
        }, 500)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
    }

    override fun onInit(status: Int) {
        if (status != TextToSpeech.SUCCESS) {
            Log.e("TTS", "Text-to-Speech initialization failed")
        }
    }
}
