package app.nextlevel

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity: FlutterActivity() {
	private val CHANNEL = "app.nextlevel/timezone"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"getLocalTimezone" -> {
					try {
						// Try to provide an IANA-like ID where possible
						val tz: String = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
							// getID returns an Olson/IANA TZ on Android (e.g., Europe/Istanbul)
							TimeZone.getDefault().id
						} else {
							TimeZone.getDefault().id
						}
						result.success(tz)
					} catch (e: Exception) {
						result.error("TZ_ERROR", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
