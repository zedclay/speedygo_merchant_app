package com.speedygo.speedygo_merchant_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureNewOrderChannel()
    }

    /** High-importance channel for new-order pushes (id shared with backend). */
    private fun ensureNewOrderChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(NEW_ORDER_CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                NEW_ORDER_CHANNEL_ID,
                "Nouvelles commandes",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alertes pour les nouvelles commandes à accepter"
            },
        )
    }

    private companion object {
        const val NEW_ORDER_CHANNEL_ID = "merchant_new_orders"
    }
}
