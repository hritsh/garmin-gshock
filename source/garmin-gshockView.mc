import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application;
import Toybox.Weather;

class garmin_gshockView extends WatchUi.WatchFace {
    private var _bgBitmap;
    private var _tinyFont;
    private var _lcdMediumFont;
    private var _dotSmallFont;
    private var _tech3Font;
    
    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        
        // Load fonts
        _tinyFont = WatchUi.loadResource(Rez.Fonts.tiny);
        _lcdMediumFont = WatchUi.loadResource(Rez.Fonts.lcd_medium);
        _dotSmallFont = WatchUi.loadResource(Rez.Fonts.dot_small);
        _tech3Font = WatchUi.loadResource(Rez.Fonts.tech3);
        
        // Load background based on color setting
        var colorTheme = Application.Properties.getValue("ColorTheme");
        if (colorTheme == 1) {
            _bgBitmap = WatchUi.loadResource(Rez.Drawables.gshock_red_bg);
        } else if (colorTheme == 2) {
            _bgBitmap = WatchUi.loadResource(Rez.Drawables.gshock_green_bg);
        } else {
            _bgBitmap = WatchUi.loadResource(Rez.Drawables.gshock_original_bg);
        }
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get screen dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw background
        if (_bgBitmap != null) {
            dc.drawBitmap(0, 0, _bgBitmap);
        }
        
        // Get current time and date
        var clockTime = System.getClockTime();
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        
        // Get activity and system info
        var activityInfo = ActivityMonitor.getInfo();
        var activityData = Activity.getActivityInfo();
        var stats = System.getSystemStats();
        var deviceSettings = System.getDeviceSettings();
        
        // ============== TOP ROW ==============
        
        // Battery in days (tiny font - left side, ~y:62)
        var batteryDays = (stats.battery / 100.0 * 14).toNumber(); // Assuming ~14 days max
        var batteryString = "B-BATTERY " + batteryDays.toString() + "D";
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(18, 62, _tinyFont, batteryString, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Day of week (lcd_medium - center, ~y:58)
        var dayNames = ["", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var dayOfWeek = dayNames[info.day_of_week];
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 5, 58, _lcdMediumFont, dayOfWeek, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Date (dot_small - right side, ~y:60)
        var dateString = Lang.format("$1$-$2$", [info.month.format("%02d"), info.day.format("%02d")]);
        dc.drawText(width - 58, 60, _dotSmallFont, dateString, Graphics.TEXT_JUSTIFY_RIGHT);
        
        // ============== MIDDLE ROW ==============
        
        // AM/PM indicator (dot_small - left of time, ~y:105)
        if (clockTime.hour >= 12 && !deviceSettings.is24Hour) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(42, 105, _dotSmallFont, "P", Graphics.TEXT_JUSTIFY_LEFT);
        }
        
        // Time (tech3 - large in center, ~y:100)
        var hours = clockTime.hour;
        if (!deviceSettings.is24Hour) {
            hours = hours % 12;
            if (hours == 0) { hours = 12; }
        }
        var timeString = Lang.format("$1$:$2$", [hours.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 100, _tech3Font, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Notification indicator (filled circle - right side, ~x:width-65, y:118)
        if (deviceSettings.notificationCount > 0) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(width - 65, 118, 3);
        }
        
        // Bluetooth indicator (filled circle - right side, ~x:width-52, y:118)
        if (deviceSettings.phoneConnected) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(width - 52, 118, 3);
        }
        
        // Seconds (lcd_medium - right side, ~y:132)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 35, 132, _lcdMediumFont, clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_RIGHT);
        
        // ============== BOTTOM ROW ==============
        
        // World time EST with icon (dot_small - left, ~y:168)
        var estOffset = new Time.Duration(-5 * 3600); // EST is UTC-5
        var estTime = now.add(estOffset);
        var estInfo = Gregorian.info(estTime, Time.FORMAT_SHORT);
        var estHour = estInfo.hour;
        if (!deviceSettings.is24Hour) {
            estHour = estHour % 12;
            if (estHour == 0) { estHour = 12; }
        }
        var estString = Lang.format("$1$:$2$", [estHour.format("%02d"), estInfo.min.format("%02d")]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(30, 168, _dotSmallFont, estString, Graphics.TEXT_JUSTIFY_LEFT);
        
        // World time icon/label (tiny font)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(18, 166, _tinyFont, "EST", Graphics.TEXT_JUSTIFY_LEFT);
        
        // Heart rate with icon (dot_small - center, ~y:168)
        var hrString = "--";
        if (activityData != null && activityData.currentHeartRate != null) {
            hrString = activityData.currentHeartRate.toString();
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, 168, _dotSmallFont, hrString, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Heart icon label (tiny font)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 20, 166, _tinyFont, "HR", Graphics.TEXT_JUSTIFY_LEFT);
        
        // Steps with icon (dot_small - right, ~y:168)
        var steps = 0;
        if (activityInfo != null && activityInfo.steps != null) {
            steps = activityInfo.steps;
        }
        var stepsString = steps.toString();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 25, 168, _dotSmallFont, stepsString, Graphics.TEXT_JUSTIFY_RIGHT);
        
        // Steps icon label (tiny font)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 58, 166, _tinyFont, "STEP", Graphics.TEXT_JUSTIFY_LEFT);
        
        // ============== BOTTOM BORDER ==============
        
        // Body battery percentage (tiny font - left bottom)
        var bodyBatteryValue = 95;
        if (activityInfo has :bodyBattery && activityInfo.bodyBattery != null) {
            bodyBatteryValue = activityInfo.bodyBattery;
        }
        var bodyBatteryString = "B-BATTERY " + bodyBatteryValue.toString() + "%";
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(12, height - 42, _tinyFont, bodyBatteryString, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Steps progress bar (right bottom)
        var stepsGoal = 10000;
        if (activityInfo != null && activityInfo.stepGoal != null) {
            stepsGoal = activityInfo.stepGoal;
        }
        var stepsProgress = steps.toFloat() / stepsGoal.toFloat();
        if (stepsProgress > 1.0) { stepsProgress = 1.0; }
        
        // Draw progress bar (positioned in bottom right)
        var barX = width - 55;
        var barY = height - 48;
        var barWidth = 42;
        var barHeight = 6;
        
        // Outline
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(barX, barY, barWidth, barHeight);
        
        // Fill
        var fillWidth = ((barWidth - 2) * stepsProgress).toNumber();
        if (fillWidth > 0) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX + 1, barY + 1, fillWidth, barHeight - 2);
        }
        
        // ============== WEATHER (BOTTOM RIGHT) ==============
        
        // Weather temperature (tiny font - bottom right)
        var temp = 34;
        var feelsLike = 40;
        var conditions = Weather.getCurrentConditions();
        if (conditions != null && conditions.temperature != null) {
            temp = conditions.temperature;
            feelsLike = conditions.feelsLikeTemperature;
            if (feelsLike == null) { feelsLike = temp; }
        }
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - 12, height - 38, _tinyFont, temp.toString() + "°C", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(width - 12, height - 30, _tinyFont, feelsLike.toString() + "°C", Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
    }

    // The user has just looked at their watch
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates
    function onEnterSleep() as Void {
    }
}
