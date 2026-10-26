package com.pongo.korean_cards

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Home-screen widget: streak, cards due, today's session steps and the word of the day. */
class KoreanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.korean_widget).apply {
                setTextViewText(R.id.widget_streak, "🔥 " + widgetData.getString("streak", "0"))
                setTextViewText(R.id.widget_due, widgetData.getString("due", "Open the app to start"))
                setTextViewText(R.id.widget_steps, widgetData.getString("steps", "○○○"))
                setTextViewText(R.id.widget_word, widgetData.getString("word", "안녕하세요"))
                setTextViewText(R.id.widget_gloss, widgetData.getString("gloss", "hello"))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("koreancards://today")),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
