package com.example.nutrilens_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            FlutterLocalNotificationsPlugin.rescheduleNotifications(context)
        }
    }
}
