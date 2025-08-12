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
        private var tasks: List<String> = emptyList()

        override fun onCreate() {}

        override fun onDataSetChanged() {
            val data = HomeWidgetPlugin.getData(context)
            val taskTitlesJson = data.getString("taskTitles", "[]")
            val arr = JSONArray(taskTitlesJson)
            val list = ArrayList<String>(arr.length())
            for (i in 0 until arr.length()) {
                list.add(arr.getString(i))
            }
            tasks = list
        }

        override fun onDestroy() { tasks = emptyList() }

        override fun getCount(): Int = tasks.size

        override fun getViewAt(position: Int): RemoteViews? {
            if (position < 0 || position >= tasks.size) return null
            val rv = RemoteViews(context.packageName, R.layout.task_widget_item)
            rv.setTextViewText(R.id.task_item_title, tasks[position])
            return rv
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount(): Int = 1

        override fun getItemId(position: Int): Long = position.toLong()

        override fun hasStableIds(): Boolean = true
    }
}
