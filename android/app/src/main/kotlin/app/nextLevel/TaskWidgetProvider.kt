package app.nextlevel

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundService
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
            val views = RemoteViews(context.packageName, R.layout.task_widget)

            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val taskCount = widgetData.getInt("taskCount", 0)
                val taskTitlesJson = widgetData.getString("taskTitles", "[]")
                val taskDetailsJson = widgetData.getString("taskDetails", "[]")
                val totalWorkSec = widgetData.getInt("totalWorkSec", 0)
                val hideCompleted = widgetData.getBoolean("hideCompleted", false)

                android.util.Log.d("TaskWidgetProvider", "=== WIDGET UPDATE ===")
                android.util.Log.d("TaskWidgetProvider", "Task count: $taskCount")
                android.util.Log.d("TaskWidgetProvider", "Task titles: $taskTitlesJson")
                android.util.Log.d("TaskWidgetProvider", "Task details length: ${taskDetailsJson?.length ?: 0}")

                // Header and count
                val hh = totalWorkSec / 3600
                val mm = (totalWorkSec / 60) % 60
                val totalStr = if (totalWorkSec > 0) String.format("%d:%02d", hh, mm) else "0:00"
                views.setTextViewText(R.id.header_text, "Today's Tasks  •  $totalStr")
                views.setTextViewText(R.id.task_count_text, taskCount.toString())
                // Set toggle icon state (use different builtin icons)
                val toggleIcon = if (hideCompleted) android.R.drawable.checkbox_on_background else android.R.drawable.checkbox_off_background
                views.setImageViewResource(R.id.hide_completed_checkbox, toggleIcon)

                // Wire click to toggle
                val toggleIntent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java)
                toggleIntent.action = "es.antonborri.home_widget.action.BACKGROUND"
                // Put action in data Uri so it's available as queryParameters in Dart
                toggleIntent.data = Uri.parse("homewidget://action?action=toggleHideCompleted&appWidgetId=${appWidgetId}")
                val togglePi = PendingIntent.getBroadcast(
                    context,
                    1001,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                // Make both the icon and the row clickable
                views.setOnClickPendingIntent(R.id.hide_completed_checkbox, togglePi)
                views.setOnClickPendingIntent(R.id.hide_completed_row, togglePi)

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

                    // Set a PendingIntent template so each item can fill in specifics
                    val clickIntent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java)
                    clickIntent.action = "es.antonborri.home_widget.action.BACKGROUND"
                    // action and taskId will be filled per item
                    val templatePi = PendingIntent.getBroadcast(
                        context,
                        1002,
                        clickIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                    )
                    views.setPendingIntentTemplate(R.id.task_list, templatePi)

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