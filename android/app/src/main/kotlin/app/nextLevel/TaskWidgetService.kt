package app.nextlevel

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = TaskViewsFactory(applicationContext)

    class TaskViewsFactory(private val context: Context) : RemoteViewsFactory {
        private data class TaskDetail(
            val id: Int,
            val title: String,
            val type: String,
            val currentCount: Int,
            val targetCount: Int,
            val currentDurationSec: Int,
            val targetDurationSec: Int,
            val isTimerActive: Boolean
        )

        private var tasks: List<TaskDetail> = emptyList()
        private val handler = Handler(Looper.getMainLooper())
        private val refresher = object : Runnable {
            override fun run() {
                val hasActive = tasks.any { it.type == "TIMER" && it.isTimerActive }
                if (hasActive) {
                    // Ask AppWidgetManager to refresh list
                    val mgr = AppWidgetManager.getInstance(context)
                    val cn = ComponentName(context, TaskWidgetProvider::class.java)
                    val ids = mgr.getAppWidgetIds(cn)
                    for (id in ids) {
                        mgr.notifyAppWidgetViewDataChanged(id, R.id.task_list)
                    }
                    handler.postDelayed(this, 1000)
                }
            }
        }

        override fun onCreate() {}

        override fun onDataSetChanged() {
            try {
                val data = HomeWidgetPlugin.getData(context)
                val detailsJson = data.getString("taskDetails", "[]")
                val arr = JSONArray(detailsJson)
                val list = ArrayList<TaskDetail>(arr.length())
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    list.add(
                        TaskDetail(
                            id = o.optInt("id"),
                            title = o.optString("title"),
                            type = o.optString("type"),
                            currentCount = o.optInt("currentCount"),
                            targetCount = o.optInt("targetCount"),
                            currentDurationSec = o.optInt("currentDurationSec"),
                            targetDurationSec = o.optInt("targetDurationSec"),
                            isTimerActive = o.optBoolean("isTimerActive")
                        )
                    )
                }
                tasks = list
            } catch (e: Exception) {
                // Keep previous list on parse/read failure to avoid flicker/empty state
                e.printStackTrace()
            } finally {
                // Start/stop periodic refresh based on active timers
                handler.removeCallbacks(refresher)
                if (tasks.any { it.type == "TIMER" && it.isTimerActive }) {
                    handler.post(refresher)
                }
            }
        }

        override fun onDestroy() {
            tasks = emptyList()
            handler.removeCallbacks(refresher)
        }

        override fun getCount(): Int = tasks.size

        override fun getViewAt(position: Int): RemoteViews? {
            if (position < 0 || position >= tasks.size) return null
            val rv = RemoteViews(context.packageName, R.layout.task_widget_item)
            val item = tasks[position]
            rv.setTextViewText(R.id.task_item_title, item.title)

            // Icon per type
            when (item.type) {
                "CHECKBOX" -> {
                    rv.setImageViewResource(R.id.task_item_icon, android.R.drawable.checkbox_off_background)
                    rv.setInt(R.id.task_item_icon, "setColorFilter", 0xFFAED581.toInt())
                }
                "COUNTER" -> {
                    rv.setImageViewResource(R.id.task_item_icon, android.R.drawable.ic_menu_sort_by_size)
                    rv.setInt(R.id.task_item_icon, "setColorFilter", 0xFFFFF176.toInt())
                }
                "TIMER" -> {
                    val icon = if (item.isTimerActive) android.R.drawable.ic_media_play else android.R.drawable.ic_media_pause
                    val color = if (item.isTimerActive) 0xFF64B5F6.toInt() else 0xFF90A4AE.toInt()
                    rv.setImageViewResource(R.id.task_item_icon, icon)
                    rv.setInt(R.id.task_item_icon, "setColorFilter", color)
                }
            }

            // Subtitle + progress
            var sub = ""
            var progress = 0
            var max = 100
            // Hide timer badge by default
            rv.setViewVisibility(R.id.task_item_timer_badge, android.view.View.GONE)
            when (item.type) {
                "COUNTER" -> {
                    val tgt = if (item.targetCount > 0) item.targetCount else 1
                    progress = ((item.currentCount.coerceAtLeast(0) * 100.0) / tgt).toInt().coerceIn(0, 100)
                    sub = "${item.currentCount}/${tgt}"
                }
                "TIMER" -> {
                    val tgt = if (item.targetDurationSec > 0) item.targetDurationSec else 1
                    progress = ((item.currentDurationSec.coerceAtLeast(0) * 100.0) / tgt).toInt().coerceIn(0, 100)
                    val ss = item.currentDurationSec % 60
                    val mm = (item.currentDurationSec / 60) % 60
                    val hh = item.currentDurationSec / 3600
                    sub = String.format("%02d:%02d:%02d", hh, mm, ss)
                    if (item.isTimerActive) {
                        rv.setTextViewText(R.id.task_item_timer_badge, "ACTIVE")
                        rv.setViewVisibility(R.id.task_item_timer_badge, android.view.View.VISIBLE)
                    }
                }
                else -> {
                    // Checkbox
                    sub = ""
                }
            }
            rv.setTextViewText(R.id.task_item_sub, sub)
            rv.setProgressBar(R.id.task_item_progress, max, progress, false)

            // Set fill-in intent for item click
            val fillIn = Intent()
            val action = when (item.type) {
                "CHECKBOX" -> "toggleCheckbox"
                "COUNTER" -> "incrementCounter"
                "TIMER" -> "toggleTimer"
                else -> "noop"
            }
            // Use data Uri so it becomes available as queryParameters in Dart callback
            val safeTitle = java.net.URLEncoder.encode(item.title, "UTF-8")
            val dataUri = android.net.Uri.parse("homewidget://task?action=${action}&taskId=${item.id}&title=${safeTitle}")
            fillIn.data = dataUri
            rv.setOnClickFillInIntent(R.id.task_item_root, fillIn)
            return rv
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount(): Int = 1

        override fun getItemId(position: Int): Long = position.toLong()

        override fun hasStableIds(): Boolean = true
    }
}
