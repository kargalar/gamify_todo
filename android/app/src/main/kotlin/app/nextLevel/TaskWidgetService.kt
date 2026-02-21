package app.nextlevel

import android.content.Context
import android.content.Intent
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
            val section: String = "TASKS",
            val isDone: Boolean = false,
            val currentCount: Int = 0,
            val targetCount: Int = 0,
            val currentDurationSec: Int = 0,
            val targetDurationSec: Int = 0
        )

        // List item can be either a header or a task
        private sealed class ListItem {
            data class Header(val title: String) : ListItem()
            data class Task(val detail: TaskDetail) : ListItem()
        }

        private var tasks: List<TaskDetail> = emptyList()
        private var listItems: List<ListItem> = emptyList()

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
                            section = o.optString("section", "TASKS"),
                            isDone = o.optBoolean("isDone", false),
                            currentCount = o.optInt("currentCount"),
                            targetCount = o.optInt("targetCount"),
                            currentDurationSec = o.optInt("currentDurationSec"),
                            targetDurationSec = o.optInt("targetDurationSec")
                        )
                    )
                }
                tasks = list

                // Build list items with section headers
                val items = mutableListOf<ListItem>()
                var currentSection: String? = null

                for (task in tasks) {
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
                android.util.Log.e("TaskWidgetService", "Error parsing task details", e)
                e.printStackTrace()
            }
        }

        override fun onDestroy() {
            tasks = emptyList()
            listItems = emptyList()
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
                    val rv = RemoteViews(context.packageName, R.layout.task_widget_section_header)
                    rv.setTextViewText(R.id.section_header_title, listItem.title)
                    rv
                }
                is ListItem.Task -> {
                    android.util.Log.d("TaskWidgetService", "Creating task view: ${listItem.detail.title}")
                    val rv = RemoteViews(context.packageName, R.layout.task_widget_item)
                    val item = listItem.detail

                    // Set title
                    rv.setTextViewText(R.id.task_item_title, item.title)

                    // Status dot color based on section and completion
                    val dotDrawable = when {
                        item.isDone -> R.drawable.status_dot_done
                        item.section == "OVERDUE" -> R.drawable.status_dot_overdue
                        else -> R.drawable.status_dot_pending
                    }
                    rv.setImageViewResource(R.id.task_status_dot, dotDrawable)

                    // Title styling for completed tasks
                    if (item.isDone) {
                        rv.setTextColor(R.id.task_item_title, 0xFF555566.toInt())
                    } else {
                        rv.setTextColor(R.id.task_item_title, 0xFFE0E0E8.toInt())
                    }

                    // Subtitle — show progress info only
                    var sub = ""
                    when (item.type) {
                        "COUNTER" -> {
                            val tgt = if (item.targetCount > 0) item.targetCount else 1
                            sub = "${item.currentCount}/$tgt"
                        }
                        "TIMER" -> {
                            val ss = item.currentDurationSec % 60
                            val mm = (item.currentDurationSec / 60) % 60
                            val hh = item.currentDurationSec / 3600
                            sub = String.format("%02d:%02d:%02d", hh, mm, ss)
                        }
                    }
                    rv.setTextViewText(R.id.task_item_sub, sub)
                    if (sub.isEmpty()) {
                        rv.setViewVisibility(R.id.task_item_sub, android.view.View.GONE)
                    } else {
                        rv.setViewVisibility(R.id.task_item_sub, android.view.View.VISIBLE)
                    }

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
