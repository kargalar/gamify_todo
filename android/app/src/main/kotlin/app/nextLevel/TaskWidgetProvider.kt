package app.nextlevel

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetProvider : AppWidgetProvider() {
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        // Re-render on size change
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.task_list)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews("app.nextlevel", R.layout.task_widget)

            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val taskCount = widgetData.getInt("taskCount", 0)
                val taskTitlesJson = widgetData.getString("taskTitles", "[]")

                // Header and count
                views.setTextViewText(R.id.header_text, "Today's Tasks")
                views.setTextViewText(R.id.task_count_text, taskCount.toString())

                val taskTitles = JSONArray(taskTitlesJson)

                if (taskTitles.length() == 0) {
                    // Show empty state, hide list
                    views.setViewVisibility(R.id.task_list, View.GONE)
                    views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                    views.setTextViewText(R.id.empty_state, "🎉 No tasks for today!")
                } else {
                    // Bind ListView to RemoteViewsService to show all tasks
                    val svcIntent = Intent(context, TaskWidgetService::class.java)
                    svcIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    svcIntent.data = Uri.parse(svcIntent.toUri(Intent.URI_INTENT_SCHEME))
                    views.setRemoteAdapter(R.id.task_list, svcIntent)
                    views.setEmptyView(R.id.task_list, R.id.empty_state)

                    views.setViewVisibility(R.id.task_list, View.VISIBLE)
                    views.setViewVisibility(R.id.empty_state, View.GONE)
                    appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.task_list)
                }
            } catch (e: Exception) {
                // Fallback to default values if there's an error
                views.setTextViewText(R.id.header_text, "Today's Tasks")
                views.setTextViewText(R.id.task_count_text, "0")
                views.setViewVisibility(R.id.task_list, View.GONE)
                views.setViewVisibility(R.id.empty_state, View.VISIBLE)
                views.setTextViewText(R.id.empty_state, "Error updating widget")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}