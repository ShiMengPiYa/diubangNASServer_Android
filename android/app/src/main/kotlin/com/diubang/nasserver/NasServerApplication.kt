package com.diubang.nasserver

import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class NasServerApplication : FlutterApplication() {
    companion object {
        const val ENGINE_ID = "diubang_nasserver_engine"
    }

    lateinit var nativeBridge: NasServerNativeBridge
        private set
    private lateinit var foregroundTaskLifecycleListener: NasForegroundTaskLifecycleListener

    override fun onCreate() {
        super.onCreate()
        nativeBridge = NasServerNativeBridge(applicationContext)
        foregroundTaskLifecycleListener = NasForegroundTaskLifecycleListener(this)
        FlutterForegroundTaskPlugin.addTaskLifecycleListener(foregroundTaskLifecycleListener)
    }

    fun registerMainFlutterEngine(flutterEngine: FlutterEngine) {
        nativeBridge.registerChannels(flutterEngine)
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
    }

    fun registerBackgroundFlutterEngine(flutterEngine: FlutterEngine) {
        nativeBridge.registerChannels(flutterEngine)
    }
}
