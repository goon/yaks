import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

QtObject {
    id: root

    property bool loaded: false
    property int notificationMode: 0 // 0: Normal, 1: DND (Silent)

    property string weatherLat: "51.50853"
    property string weatherLong: "-0.12574"
    property string weatherLocationName: "London, England, United Kingdom"
    property string weatherUnit: "celsius" // "celsius" or "fahrenheit"
    property bool gowallEnabled: false // Global Toggle
    property string customAvatar: ""
    property double wallpaperParallaxStrength: 20.0

    property double backgroundOpacity: 0.5
    property double surfaceOpacity: 0.7
    property double themedAppsOpacity: 1.0
    property bool islandOutline: true
    // Theme Configuration
    property string currentTheme: "solaris"
    property string themeMode: "dark"
    // Bar Configuration
    property string barPosition: "top"
    property string shellFont: "Outfit Medium"
    property int barDensity: 1 // 0: Compact, 1: Default, 2: Comfortable
    property int notificationDensity: 1 // 0: Compact, 1: Comfortable
    property int workspaceStyle: 0 // 0: Arabic, 1: Roman, 2: Kanji
    property int popoutTrigger: 0 // 0: Click, 1: Hover
    property int workspaceCount: 10

    // State Persistence (Shared with Theme/Wallpaper services)
    property var currentThemeColors: ({})
    property string currentWallpaper: ""

    // Indicators Block Settings & Reordering
    property bool indicatorsShowWifi: true
    property bool indicatorsShowBluetooth: true
    property bool indicatorsShowVolume: true
    property bool indicatorsShowNotifications: true
    property bool indicatorsShowTray: true
    property bool indicatorsTrayExpanded: false
    property var indicatorsOrder: ["wifi", "bluetooth", "volume", "notifications"]

    property int barHeight: 55
    property int barMarginTop: 10
    property int barMarginSide: 10
    property int cornerRadius: 28
    property int popoutMargin: 8
    property bool barFitToContent: true
    property var barLeftComponents: []
    property var barCenterComponents: ["workspaces", "dock", "indicators", "clock"]

    property var barRightComponents: []
    property var themedApps: ({
        "gtk": false,
        "kitty": false,
        "vesktop": false,
        "obsidian": false,
        "nvim": false,
        "firefox": false,
        "gowall": true,
        "steam": false,
        "vscodium": false
    })

    // Functional Configuration
    property string webSearchUrl: Config.webSearchUrl
    property string terminal: Config.terminal
    property string wallpaperDirectory: ""
    property string launcherGlobalPrefix: ">"
    property bool launcherShowAppDescriptions: false

    
    // Presets Configuration
    property var presets: ({})

    readonly property string prefsFile: Config.prefsFile
    // Native file reading for preferences
    property FileView prefsFileView
    // Safety fallback: if file doesn't exist or load fails, assume defaults and enable saving
    property Timer safetyTimer


    // Save settings to disk (Internal debounced call)
    function save() {
        if (!loaded)
            return ;

        var data = {
            "notificationMode": root.notificationMode,

            "weatherLat": root.weatherLat,
            "weatherLong": root.weatherLong,
            "weatherLocationName": root.weatherLocationName,
            "weatherUnit": root.weatherUnit,
            "gowallEnabled": root.gowallEnabled,
            "customAvatar": root.customAvatar,
            "wallpaperParallaxStrength": root.wallpaperParallaxStrength,

            "backgroundOpacity": root.backgroundOpacity,
            "surfaceOpacity": root.surfaceOpacity,
            "themedAppsOpacity": root.themedAppsOpacity,
            "islandOutline": root.islandOutline,
            "currentTheme": root.currentTheme,
            "themeMode": root.themeMode,
            "barPosition": root.barPosition,
            "shellFont": root.shellFont,
            "barDensity": root.barDensity,
            "notificationDensity": root.notificationDensity,
            "popoutTrigger": root.popoutTrigger,
            "barHeight": root.barHeight,

            "barMarginTop": root.barMarginTop,
            "barMarginSide": root.barMarginSide,
            "cornerRadius": root.cornerRadius,
            "popoutMargin": root.popoutMargin,
            "barFitToContent": root.barFitToContent,
            "barLeftComponents": root.barLeftComponents,
            "barCenterComponents": root.barCenterComponents,
            "barRightComponents": root.barRightComponents,
            "themedApps": root.themedApps,
            "webSearchUrl": root.webSearchUrl,
            "terminal": root.terminal,
            "wallpaperDirectory": root.wallpaperDirectory,
            "launcherGlobalPrefix": root.launcherGlobalPrefix,
            "launcherShowAppDescriptions": root.launcherShowAppDescriptions,

            "currentThemeColors": root.currentThemeColors,
            "currentWallpaper": root.currentWallpaper,
            "workspaceStyle": root.workspaceStyle,
            "workspaceCount": root.workspaceCount,

            "presets": root.presets,
            "indicatorsShowWifi": root.indicatorsShowWifi,
            "indicatorsShowBluetooth": root.indicatorsShowBluetooth,
            "indicatorsShowVolume": root.indicatorsShowVolume,
            "indicatorsShowNotifications": root.indicatorsShowNotifications,
            "indicatorsOrder": root.indicatorsOrder,
            "indicatorsShowTray": root.indicatorsShowTray,
            "indicatorsTrayExpanded": root.indicatorsTrayExpanded
        };

        // Atomic write: Write to temp file then move to original
        // This prevents file corruption if the shell crashes during writing
        const jsonContent = JSON.stringify(data, null, 2);
        const tempFile = root.prefsFile + ".tmp";
        const cmd = `printf '%s' "$1" > "$2" && mv "$2" "$3"`;

        ProcessService.runDetached([
            "sh", "-c", cmd,
            "--",
            jsonContent,
            tempFile,
            root.prefsFile
        ]);
    }
    
    function savePreset(name) {
        if (!name || name.trim() === "") return;
        
        var newPresets = JSON.parse(JSON.stringify(root.presets));
        newPresets[name] = {
            "currentTheme": root.currentTheme,
            "shellFont": root.shellFont,
            "cornerRadius": root.cornerRadius,

            "barPosition": root.barPosition,
            "barFitToContent": root.barFitToContent,
            "barDensity": root.barDensity,
            "barMarginTop": root.barMarginTop,
            "barMarginSide": root.barMarginSide,
            "notificationDensity": root.notificationDensity,
            "barLeftComponents": JSON.parse(JSON.stringify(root.barLeftComponents)),
            "barCenterComponents": JSON.parse(JSON.stringify(root.barCenterComponents)),
            "barRightComponents": JSON.parse(JSON.stringify(root.barRightComponents)),

            "backgroundOpacity": root.backgroundOpacity,
            "surfaceOpacity": root.surfaceOpacity,
            "themedAppsOpacity": root.themedAppsOpacity,
            "islandOutline": root.islandOutline
        };
        root.presets = newPresets;
        requestSave("savePreset");
    }

    function loadPreset(name) {
        var preset = root.presets[name];
        if (!preset) return;

        if (preset.hasOwnProperty("currentTheme")) {
            // Use ThemeService to apply theme properly
            ThemeService.setTheme(preset.currentTheme);
        }
        
        if (preset.hasOwnProperty("shellFont")) root.shellFont = preset.shellFont;
        if (preset.hasOwnProperty("cornerRadius")) root.cornerRadius = preset.cornerRadius;

        if (preset.hasOwnProperty("barPosition")) root.barPosition = preset.barPosition;
        if (preset.hasOwnProperty("barFitToContent")) root.barFitToContent = preset.barFitToContent;
        if (preset.hasOwnProperty("barDensity")) root.barDensity = preset.barDensity;
        if (preset.hasOwnProperty("barMarginTop")) root.barMarginTop = preset.barMarginTop;
        if (preset.hasOwnProperty("barMarginSide")) root.barMarginSide = preset.barMarginSide;
        if (preset.hasOwnProperty("notificationDensity")) root.notificationDensity = preset.notificationDensity;
        
        if (preset.hasOwnProperty("barLeftComponents")) root.barLeftComponents = preset.barLeftComponents;
        if (preset.hasOwnProperty("barCenterComponents")) root.barCenterComponents = preset.barCenterComponents;
        if (preset.hasOwnProperty("barRightComponents")) root.barRightComponents = preset.barRightComponents;

        if (preset.hasOwnProperty("backgroundOpacity")) root.backgroundOpacity = preset.backgroundOpacity;
        if (preset.hasOwnProperty("surfaceOpacity")) root.surfaceOpacity = preset.surfaceOpacity;
        if (preset.hasOwnProperty("themedAppsOpacity")) root.themedAppsOpacity = preset.themedAppsOpacity;
        if (preset.hasOwnProperty("islandOutline")) root.islandOutline = preset.islandOutline;
        
        requestSave("loadPreset");
    }

    function deletePreset(name) {
        if (!root.presets[name]) return;
        
        var newPresets = JSON.parse(JSON.stringify(root.presets));
        delete newPresets[name];
        root.presets = newPresets;
        requestSave("deletePreset");
    }
    


    property Timer saveTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: root.save()
    }

    function requestSave(reason) {
        if (loaded) {
            saveTimer.restart();
        }
    }

    onThemedAppsChanged: requestSave("themedApps")
    onNotificationModeChanged: requestSave("notificationMode")

    onWeatherLatChanged: requestSave("weatherLat")
    onWeatherLongChanged: requestSave("weatherLong")
    onWeatherLocationNameChanged: requestSave("weatherLocationName")
    onWeatherUnitChanged: requestSave("weatherUnit")
    onGowallEnabledChanged: requestSave("gowallEnabled")
    onCustomAvatarChanged: requestSave("customAvatar")
    onWallpaperParallaxStrengthChanged: requestSave("wallpaperParallaxStrength")

    onBackgroundOpacityChanged: requestSave("backgroundOpacity")
    onSurfaceOpacityChanged: requestSave("surfaceOpacity")
    onThemedAppsOpacityChanged: requestSave("themedAppsOpacity")
    onIslandOutlineChanged: requestSave("islandOutline")
    onCurrentThemeChanged: requestSave("currentTheme")
    onThemeModeChanged: requestSave("themeMode")
    onBarPositionChanged: requestSave("barPosition")
    onShellFontChanged: requestSave("shellFont")
    onBarDensityChanged: {
        if (barDensity === 0) root.barHeight = 50;
        else if (barDensity === 1) root.barHeight = 55;
        else if (barDensity === 2) root.barHeight = 60;
        requestSave("barDensity");
    }
    onNotificationDensityChanged: requestSave("notificationDensity")
    onWorkspaceStyleChanged: requestSave("workspaceStyle")
    onWorkspaceCountChanged: requestSave("workspaceCount")

    onPopoutTriggerChanged: requestSave("popoutTrigger")

    onBarHeightChanged: requestSave("barHeight")
    onBarMarginTopChanged: requestSave("barMarginTop")
    onBarMarginSideChanged: requestSave("barMarginSide")
    onCornerRadiusChanged: requestSave("cornerRadius")
    onPopoutMarginChanged: requestSave("popoutMargin")
    onBarFitToContentChanged: requestSave("barFitToContent")
    onBarLeftComponentsChanged: requestSave("barLeftComponents")
    onBarCenterComponentsChanged: requestSave("barCenterComponents")
    onBarRightComponentsChanged: requestSave("barRightComponents")
    onWebSearchUrlChanged: requestSave("webSearchUrl")
    onTerminalChanged: requestSave("terminal")
    onWallpaperDirectoryChanged: requestSave("wallpaperDirectory")
    onLauncherGlobalPrefixChanged: requestSave("launcherGlobalPrefix")
    onLauncherShowAppDescriptionsChanged: requestSave("launcherShowAppDescriptions")

    onCurrentThemeColorsChanged: requestSave("currentThemeColors")
    onCurrentWallpaperChanged: requestSave("currentWallpaper")
    onIndicatorsShowWifiChanged: requestSave("indicatorsShowWifi")
    onIndicatorsShowBluetoothChanged: requestSave("indicatorsShowBluetooth")
    onIndicatorsShowNotificationsChanged: requestSave("indicatorsShowNotifications")
    onIndicatorsOrderChanged: requestSave("indicatorsOrder")
    onIndicatorsShowTrayChanged: requestSave("indicatorsShowTray")
    onIndicatorsShowVolumeChanged: requestSave("indicatorsShowVolume")
    onIndicatorsTrayExpandedChanged: requestSave("indicatorsTrayExpanded")
    Component.onCompleted: {
        prefsFileView.reload();
    }

    safetyTimer: Timer {
        interval: 10000 
        running: true
        repeat: false
        onTriggered: {
            if (!root.loaded) {
                console.warn("[Preferences] Load timed out, assuming defaults. Manual changes will now be allowed.");
                root.loaded = true;
                // CRITICAL FIX: Do NOT automatically save here. 
                // Only allow the user to trigger a save by changing a setting.
            }
        }
    }

    prefsFileView: FileView {
        path: root.prefsFile
        watchChanges: false
        onLoadedChanged: {
            if (loaded) {
                const rawText = text();
                if (rawText.trim().length === 0) {
                    console.log("[Preferences] File is empty, skipping parse.");
                    safetyTimer.stop();
                    root.loaded = true;
                    return;
                }

                try {
                    var data = JSON.parse(rawText);
                    if (!data || typeof data !== "object") throw new Error("Invalid JSON");
                    if (data.hasOwnProperty("notificationMode"))
                        root.notificationMode = data.notificationMode;


                    if (data.hasOwnProperty("weatherLat"))
                        root.weatherLat = data.weatherLat;

                    if (data.hasOwnProperty("weatherLong"))
                        root.weatherLong = data.weatherLong;

                    if (data.hasOwnProperty("weatherLocationName"))
                        root.weatherLocationName = data.weatherLocationName;

                    if (data.hasOwnProperty("weatherUnit"))
                        root.weatherUnit = data.weatherUnit;

                    if (data.hasOwnProperty("gowallEnabled"))
                        root.gowallEnabled = data.gowallEnabled;

                    if (data.hasOwnProperty("customAvatar"))
                        root.customAvatar = data.customAvatar;

                    if (data.hasOwnProperty("wallpaperParallaxStrength"))
                        root.wallpaperParallaxStrength = data.wallpaperParallaxStrength;



                    if (data.hasOwnProperty("backgroundOpacity"))
                        root.backgroundOpacity = data.backgroundOpacity;

                    if (data.hasOwnProperty("surfaceOpacity"))
                        root.surfaceOpacity = data.surfaceOpacity;

                    if (data.hasOwnProperty("themedAppsOpacity"))
                        root.themedAppsOpacity = data.themedAppsOpacity;

                    if (data.hasOwnProperty("islandOutline"))
                        root.islandOutline = data.islandOutline;

                    if (data.hasOwnProperty("currentTheme"))
                        root.currentTheme = data.currentTheme;

                    if (data.hasOwnProperty("themeMode"))
                        root.themeMode = data.themeMode;

                    if (data.hasOwnProperty("barPosition"))
                        root.barPosition = data.barPosition;

                    if (data.hasOwnProperty("shellFont"))
                        root.shellFont = data.shellFont;

                    if (data.hasOwnProperty("barDensity"))
                        root.barDensity = data.barDensity;

                    if (data.hasOwnProperty("notificationDensity"))
                        root.notificationDensity = data.notificationDensity;

                    if (data.hasOwnProperty("popoutTrigger"))
                        root.popoutTrigger = data.popoutTrigger;


                    if (data.hasOwnProperty("barHeight"))
                        root.barHeight = data.barHeight;

                    if (data.hasOwnProperty("barMarginTop"))
                        root.barMarginTop = data.barMarginTop;

                    if (data.hasOwnProperty("barMarginSide"))
                        root.barMarginSide = data.barMarginSide;

                    if (data.hasOwnProperty("cornerRadius"))
                        root.cornerRadius = data.cornerRadius;

                    if (data.hasOwnProperty("popoutMargin"))
                        root.popoutMargin = data.popoutMargin;

                    if (data.hasOwnProperty("barFitToContent"))
                        root.barFitToContent = data.barFitToContent;

                    if (data.hasOwnProperty("barLeftComponents")) {
                        let arr = data.barLeftComponents;
                        let migrated = [];
                        let hasIndicators = false;
                        for (let i = 0; i < arr.length; i++) {
                            let c = arr[i];
                            if (c === "connectivity" || c === "status" || c === "indicators") {
                                if (!hasIndicators) { migrated.push("indicators"); hasIndicators = true; }
                            } else if (c === "tray" || c === "notifications" || c === "volume") {
                                // filter out
                            } else {
                                migrated.push(c);
                            }
                        }
                        if (!hasIndicators && (arr.includes("tray") || arr.includes("volume"))) {
                            let idx = arr.indexOf("tray");
                            if (idx === -1) idx = arr.indexOf("volume");
                            migrated.splice(idx, 0, "indicators");
                        }
                        root.barLeftComponents = migrated;
                    }

                    if (data.hasOwnProperty("barCenterComponents")) {
                        let arr = data.barCenterComponents;
                        let migrated = [];
                        let hasIndicators = false;
                        for (let i = 0; i < arr.length; i++) {
                            let c = arr[i];
                            if (c === "connectivity" || c === "status" || c === "indicators") {
                                if (!hasIndicators) { migrated.push("indicators"); hasIndicators = true; }
                            } else if (c === "tray" || c === "notifications" || c === "volume") {
                                // filter out
                            } else {
                                migrated.push(c);
                            }
                        }
                        if (!hasIndicators && (arr.includes("tray") || arr.includes("volume"))) {
                            let idx = arr.indexOf("tray");
                            if (idx === -1) idx = arr.indexOf("volume");
                            migrated.splice(idx, 0, "indicators");
                        }
                        root.barCenterComponents = migrated;
                    }

                    if (data.hasOwnProperty("barRightComponents")) {
                        let arr = data.barRightComponents;
                        let migrated = [];
                        let hasIndicators = false;
                        for (let i = 0; i < arr.length; i++) {
                            let c = arr[i];
                            if (c === "connectivity" || c === "status" || c === "indicators") {
                                if (!hasIndicators) { migrated.push("indicators"); hasIndicators = true; }
                            } else if (c === "tray" || c === "notifications" || c === "volume") {
                                // filter out
                            } else {
                                migrated.push(c);
                            }
                        }
                        if (!hasIndicators && (arr.includes("tray") || arr.includes("volume"))) {
                            let idx = arr.indexOf("tray");
                            if (idx === -1) idx = arr.indexOf("volume");
                            migrated.splice(idx, 0, "indicators");
                        }
                        root.barRightComponents = migrated;
                    }

                    if (data.hasOwnProperty("indicatorsShowWifi"))
                        root.indicatorsShowWifi = data.indicatorsShowWifi;
                    else if (data.hasOwnProperty("statusShowWifi"))
                        root.indicatorsShowWifi = data.statusShowWifi;
                    else if (data.hasOwnProperty("connectivityShowWifi"))
                        root.indicatorsShowWifi = data.connectivityShowWifi;

                    if (data.hasOwnProperty("indicatorsShowBluetooth"))
                        root.indicatorsShowBluetooth = data.indicatorsShowBluetooth;
                    else if (data.hasOwnProperty("statusShowBluetooth"))
                        root.indicatorsShowBluetooth = data.statusShowBluetooth;
                    else if (data.hasOwnProperty("connectivityShowBluetooth"))
                        root.indicatorsShowBluetooth = data.connectivityShowBluetooth;

                    if (data.hasOwnProperty("indicatorsShowNotifications"))
                        root.indicatorsShowNotifications = data.indicatorsShowNotifications;
                    else if (data.hasOwnProperty("statusShowNotifications"))
                        root.indicatorsShowNotifications = data.statusShowNotifications;
                    else if (data.hasOwnProperty("connectivityShowNotifications"))
                        root.indicatorsShowNotifications = data.connectivityShowNotifications;

                    if (data.hasOwnProperty("indicatorsShowVolume"))
                        root.indicatorsShowVolume = data.indicatorsShowVolume;

                    if (data.hasOwnProperty("indicatorsOrder") || data.hasOwnProperty("statusOrder")) {
                        let order = data.hasOwnProperty("indicatorsOrder") ? data.indicatorsOrder : data.statusOrder;
                        let defaults = ["wifi", "bluetooth", "volume", "notifications"];
                        order = order.filter(function(x) { return x !== "tray"; });
                        for (let j = 0; j < defaults.length; j++) {
                            if (!order.includes(defaults[j])) {
                                order.push(defaults[j]);
                            }
                        }
                        root.indicatorsOrder = order;
                    }

                    if (data.hasOwnProperty("indicatorsShowTray"))
                        root.indicatorsShowTray = data.indicatorsShowTray;

                    if (data.hasOwnProperty("indicatorsTrayExpanded"))
                        root.indicatorsTrayExpanded = data.indicatorsTrayExpanded;

                    if (data.hasOwnProperty("themedApps")) {
                        // Merge with defaults to ensure new app keys are present
                        let merged = JSON.parse(JSON.stringify(root.themedApps));
                        for (let k in data.themedApps) {
                            // Migration: gtk4 -> gtk
                            if (k === "gtk4") {
                                if (!data.themedApps.hasOwnProperty("gtk")) {
                                    merged["gtk"] = data.themedApps[k];
                                }
                                continue;
                            }
                            merged[k] = data.themedApps[k];
                        }
                        root.themedApps = merged;
                    }

                    if (data.hasOwnProperty("webSearchUrl"))
                        root.webSearchUrl = data.webSearchUrl;

                    if (data.hasOwnProperty("terminal"))
                        root.terminal = data.terminal;

                    if (data.hasOwnProperty("wallpaperDirectory"))
                        root.wallpaperDirectory = data.wallpaperDirectory;

                    if (data.hasOwnProperty("launcherGlobalPrefix"))
                        root.launcherGlobalPrefix = data.launcherGlobalPrefix;

                    if (data.hasOwnProperty("launcherShowAppDescriptions"))
                        root.launcherShowAppDescriptions = data.launcherShowAppDescriptions;



                    if (data.hasOwnProperty("currentThemeColors"))
                        root.currentThemeColors = data.currentThemeColors;

                    if (data.hasOwnProperty("currentWallpaper"))
                        root.currentWallpaper = data.currentWallpaper;

                    if (data.hasOwnProperty("workspaceStyle"))
                        root.workspaceStyle = data.workspaceStyle;
                    else if (data.hasOwnProperty("romanNumerals") && data.romanNumerals === true)
                        root.workspaceStyle = 1;


                    if (data.hasOwnProperty("workspaceCount"))
                        root.workspaceCount = data.workspaceCount;

                    if (data.hasOwnProperty("presets"))
                        root.presets = data.presets;

                    safetyTimer.stop();
                    root.loaded = true;
                } catch (e) {
                    console.error("[Preferences] Failed to parse preferences file:", e.message);
                }
            }
        }
    }

}
