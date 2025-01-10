package com.dev.bigwings

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.socket.client.IO
import io.socket.client.Socket
import org.json.JSONObject
import java.net.URI

class LocationService : Service() {

    private var socket: Socket? = null
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback

    override fun onCreate() {
        super.onCreate()

        Log.d("LocationService", "onCreate: Service started")

        // Initialize FusedLocationProviderClient for Location Updates
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        // Initialize the location request
        locationRequest = LocationRequest.create().apply {
            interval = 5000  // 5 seconds interval for location updates
            fastestInterval = 2000  // 2 seconds fastest interval
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }

        // Initialize the location callback
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(p0: LocationResult) {
                super.onLocationResult(p0)
                p0.let {
                    it.locations.forEach { location ->
//                        emitLocationData(location)
                    }
                }
            }
        }

        // Create a notification to keep the service running in the foreground
        val notificationId = 1
        val notificationChannelId = "service_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationChannelId,
                "Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setContentTitle("Service Running")
            .setContentText("Location service is active.")
            .setSmallIcon(R.mipmap.ic_launcher)  // Use your app's icon
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notificationId, notification, FOREGROUND_SERVICE_TYPE_LOCATION)
        }else{
            startForeground(notificationId, notification)
        }

    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()

        // Stop location updates and disconnect the socket
        fusedLocationClient.removeLocationUpdates(locationCallback)
        socket?.disconnect()
        socket?.off()

        Log.d("LocationService", "Service stopped")
    }

    override fun onBind(arg0: Intent?): IBinder? {
        return LocalBinder()
    }

    // Binder to allow clients to bind to the service
    inner class LocalBinder : Binder() {
        fun getService(): LocationService = this@LocationService
    }
}
