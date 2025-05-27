package app.nextlevel

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews("app.nextlevel", R.layout.task_widget)

            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val taskCount = widgetData.getInt("taskCount", 0)
                val taskTitlesJson = widgetData.getString("taskTitles", "[]")

                // Set header
                views.setTextViewText(R.id.header_text, "Today's Tasks")

                // Set task count
                views.setTextViewText(R.id.task_count_text, taskCount.toString())

                // Parse and display task titles
                val taskTitles = JSONArray(taskTitlesJson)
                if (taskTitles.length() == 0) {
                    views.setTextViewText(R.id.empty_state, "🎉 No tasks for today!")
                } else {
                    val taskListText = StringBuilder()
                    for (i in 0 until taskTitles.length()) {
                        val taskTitle = taskTitles.getString(i)
                        taskListText.append("• $taskTitle")
                        if (i < taskTitles.length() - 1) {
                            taskListText.append("\n")
                        }
                    }
                    views.setTextViewText(R.id.empty_state, taskListText.toString())
                }

            } catch (e: Exception) {
                // Fallback to default values if there's an error
                views.setTextViewText(R.id.header_text, "Today's Tasks")
                views.setTextViewText(R.id.task_count_text, "0")
                views.setTextViewText(R.id.empty_state, "Error loading tasks")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}