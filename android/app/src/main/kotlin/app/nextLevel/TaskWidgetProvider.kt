package app.nextlevel

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews("app.nextlevel", R.layout.task_widget)
            
            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val taskCount = widgetData.getInt("taskCount", 0)
                val taskTitlesJson = widgetData.getString("taskTitles", "[]")

                // Debug logging - İlk adım: veri alımını kontrol edelim
                android.util.Log.d("TaskWidget", "=== WIDGET DEBUG ===")
                android.util.Log.d("TaskWidget", "Task count received: $taskCount")
                android.util.Log.d("TaskWidget", "Task titles JSON: $taskTitlesJson")

                // Set header
                views.setTextViewText(R.id.header_text, "Today's Tasks")

                // Set task count
                views.setTextViewText(R.id.task_count_text, taskCount.toString())                // Parse and display task titles
                val taskTitles = JSONArray(taskTitlesJson)
                
                if (taskTitles.length() == 0) {
                    // Hide all task containers and show empty state
                    views.setViewVisibility(R.id.task_1, View.GONE)
                    views.setViewVisibility(R.id.task_2, View.GONE)
                    views.setViewVisibility(R.id.task_3, View.GONE)
                    views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                    views.setTextViewText(R.id.empty_state, "🎉 No tasks for today!")
                } else {
                    // Hide empty state
                    views.setViewVisibility(R.id.empty_state, View.GONE)
                    
                    // Show up to 3 tasks in separate containers
                    val maxTasks = 3
                    val tasksToShow = minOf(taskTitles.length(), maxTasks)
                    
                    val taskViews = arrayOf(R.id.task_1, R.id.task_2, R.id.task_3)
                    
                    // Show tasks in individual containers
                    for (i in 0 until tasksToShow) {
                        val taskTitle = taskTitles.getString(i)
                        views.setViewVisibility(taskViews[i], View.VISIBLE)
                        views.setTextViewText(taskViews[i], taskTitle)
                        android.util.Log.d("TaskWidget", "Showing task $i: $taskTitle")
                    }
                    
                    // Hide unused containers
                    for (i in tasksToShow until maxTasks) {
                        views.setViewVisibility(taskViews[i], View.GONE)
                    }
                    
                    // Show remaining count if there are more tasks
                    if (taskTitles.length() > maxTasks) {
                        val remainingTasks = taskTitles.length() - maxTasks
                        views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                        views.setTextViewText(R.id.empty_state, "... and $remainingTasks more tasks")
                    }
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