package app.nextlevel

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = TaskViewsFactory(applicationContext)

    class TaskViewsFactory(private val context: Context) : RemoteViewsFactory {
        private data class TaskDetail(
            val title: String,
            val type: String,
            val currentCount: Int,
            val targetCount: Int,
            val currentDurationSec: Int,
            val targetDurationSec: Int,
            val isTimerActive: Boolean
        )

        private var tasks: List<TaskDetail> = emptyList()

        override fun onCreate() {}

        override fun onDataSetChanged() {
            val data = HomeWidgetPlugin.getData(context)
            val detailsJson = data.getString("taskDetails", "[]")
            val arr = JSONArray(detailsJson)
            val list = ArrayList<TaskDetail>(arr.length())
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                list.add(
                    TaskDetail(
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
        }

        override fun onDestroy() { tasks = emptyList() }

        override fun getCount(): Int = tasks.size

        override fun getViewAt(position: Int): RemoteViews? {
            if (position < 0 || position >= tasks.size) return null
            val rv = RemoteViews(context.packageName, R.layout.task_widget_item)
            val item = tasks[position]
            rv.setTextViewText(R.id.task_item_title, item.title)

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
            return rv
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount(): Int = 1

        override fun getItemId(position: Int): Long = position.toLong()

        override fun hasStableIds(): Boolean = true
    }
}
