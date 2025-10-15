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
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        android.util.Log.d("TaskWidgetService", "=== onGetViewFactory called ===")
        return TaskViewsFactory(applicationContext)
    }

    class TaskViewsFactory(private val context: Context) : RemoteViewsFactory {
        private data class TaskDetail(
            val id: Int,
            val title: String,
            val type: String,
            val currentCount: Int,
            val targetCount: Int,
            val currentDurationSec: Int,
            val targetDurationSec: Int,
            val isTimerActive: Boolean,
            val section: String = "TASKS"
        )

        // List item can be either a header or a task
        private sealed class ListItem {
            data class Header(val title: String) : ListItem()
            data class Task(val detail: TaskDetail) : ListItem()
        }

        private var tasks: List<TaskDetail> = emptyList()
        private var listItems: List<ListItem> = emptyList()
        private val handler = Handler(Looper.getMainLooper())
        private val refresher = object : Runnable {
            override fun run() {
                val hasActive = tasks.any { it.type == "TIMER" && it.isTimerActive }
                if (hasActive) {
                    // Ask AppWidgetManager to refresh list every second when timer is active
                    val mgr = AppWidgetManager.getInstance(context)
                    val cn = ComponentName(context, TaskWidgetProvider::class.java)
                    val ids = mgr.getAppWidgetIds(cn)
                    for (id in ids) {
                        mgr.notifyAppWidgetViewDataChanged(id, R.id.task_list)
                    }
                    // Refresh every second to show live timer updates
                    handler.postDelayed(this, 1000)
                }
            }
        }

        override fun onCreate() {
            android.util.Log.d("TaskWidgetService", "onCreate called")
        }

        override fun onDataSetChanged() {
            android.util.Log.d("TaskWidgetService", "=== onDataSetChanged ===")
            try {
                val data = HomeWidgetPlugin.getData(context)
                val detailsJson = data.getString("taskDetails", "[]")
                android.util.Log.d("TaskWidgetService", "Task details JSON: $detailsJson")
                val arr = JSONArray(detailsJson)
                android.util.Log.d("TaskWidgetService", "JSON array length: ${arr.length()}")
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
                            isTimerActive = o.optBoolean("isTimerActive"),
                            section = o.optString("section", "TASKS")
                        )
                    )
                }
                tasks = list

                // Build list items with section headers
                val items = mutableListOf<ListItem>()
                var currentSection: String? = null

                for (task in tasks) {
                    // Add section header if section changed
                    if (task.section != currentSection) {
                        val headerTitle = when (task.section) {
                            "OVERDUE" -> "⚠️ OVERDUE"
                            "PINNED" -> "📌 PINNED"
                            "TASKS" -> "📋 TASKS"
                            "ROUTINES" -> "🔄 ROUTINES"
                            else -> task.section
                        }
                        items.add(ListItem.Header(headerTitle))
                        currentSection = task.section
                    }
                    items.add(ListItem.Task(task))
                }

                listItems = items
                android.util.Log.d("TaskWidgetService", "Tasks count: ${tasks.size}")
                android.util.Log.d("TaskWidgetService", "List items count: ${listItems.size}")
            } catch (e: Exception) {
                // Keep previous list on parse/read failure to avoid flicker/empty state
                android.util.Log.e("TaskWidgetService", "Error parsing task details", e)
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
            listItems = emptyList()
            handler.removeCallbacks(refresher)
        }

        override fun getCount(): Int {
            android.util.Log.d("TaskWidgetService", "getCount called: ${listItems.size}")
            return listItems.size
        }

        override fun getViewAt(position: Int): RemoteViews? {
            android.util.Log.d("TaskWidgetService", "getViewAt called for position: $position")
            if (position < 0 || position >= listItems.size) {
                android.util.Log.w("TaskWidgetService", "Invalid position: $position (size: ${listItems.size})")
                return null
            }

            return when (val listItem = listItems[position]) {
                is ListItem.Header -> {
                    android.util.Log.d("TaskWidgetService", "Creating header view: ${listItem.title}")
                    // Create section header view
                    val rv = RemoteViews(context.packageName, R.layout.task_widget_section_header)
                    rv.setTextViewText(R.id.section_header_title, listItem.title)
                    android.util.Log.d("TaskWidgetService", "Header view created successfully")
                    rv
                }
                is ListItem.Task -> {
                    android.util.Log.d("TaskWidgetService", "Creating task view: ${listItem.detail.title}")
                    // Create task item view
                    val rv = RemoteViews(context.packageName, R.layout.task_widget_item)
                    val item = listItem.detail

                    // Set title (no emoji prefix, header already shows section)
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
                            // When timer is active, show pause icon (user can pause it)
                            // When timer is inactive, show play icon (user can start it)
                            val icon = if (item.isTimerActive) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
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
                                rv.setTextViewText(R.id.task_item_timer_badge, "RUNNING")
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
                    fillIn.action = "es.antonborri.home_widget.action.BACKGROUND"
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
                    // Also add as extra for HomeWidget plugin
                    fillIn.putExtra("url", dataUri.toString())
                    android.util.Log.d("TaskWidgetService", "Task click intent set: action=$action, taskId=${item.id}, uri=$dataUri")
                    rv.setOnClickFillInIntent(R.id.task_item_root, fillIn)
                    // Also attach to common child views for better hit area
                    rv.setOnClickFillInIntent(R.id.task_item_title, fillIn)
                    rv.setOnClickFillInIntent(R.id.task_item_icon, fillIn)
                    android.util.Log.d("TaskWidgetService", "Task view created successfully")
                    rv
                }
            }
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount(): Int = 2  // Header and Task

        override fun getItemId(position: Int): Long = position.toLong()

        override fun hasStableIds(): Boolean = true
    }
}
