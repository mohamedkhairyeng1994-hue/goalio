# iOS Home-Screen Widget — Setup

The Swift sources, Info.plist, entitlements, and assets for the WidgetKit
extension are in this folder. They are **not yet registered as a target in
the Xcode project**, because target wiring has to be done from Xcode (the
`project.pbxproj` is too easy to corrupt by hand).

This document is the one-time wiring procedure. After that, day-to-day work
happens in Swift the same way as the Android widget happens in Kotlin.

## 1. Add the Widget Extension target

1. Open `ios/Runner.xcworkspace` in Xcode (not `Runner.xcodeproj` — the
   workspace pulls in CocoaPods).
2. **File → New → Target → Widget Extension** → Next.
3. Product Name: `GoalioWidget`.
4. Team: same team as Runner (`S749H4KDZQ`).
5. Bundle Identifier: leave Xcode's suggestion — it should look like
   `<Runner bundle id>.GoalioWidget`.
6. **Uncheck** "Include Configuration Intent" and **uncheck** "Include Live
   Activity". Click Finish.
7. When prompted "Activate `GoalioWidget` scheme?", click **Activate**.

Xcode will scaffold a folder called `GoalioWidget` inside `ios/`. **Delete
every file Xcode generated** in that folder (the placeholder
`GoalioWidget.swift`, `GoalioWidgetBundle.swift`, `Assets.xcassets`,
`Info.plist`, `GoalioWidget.entitlements`) — the working copies live next
to this README and the Xcode-generated stubs would conflict.

## 2. Add the real sources to the target

In Xcode's project navigator:

1. Right-click the `GoalioWidget` group → **Add Files to "Runner"…**
2. Navigate to `ios/GoalioWidget/` and select these files (Cmd-click to
   multi-select):

   ```
   GoalioWidgetBundle.swift
   GoalioWidget.swift
   Models.swift
   MatchAPI.swift
   Theme.swift
   Views.swift
   Intents.swift
   SharedConfig.swift
   Info.plist
   GoalioWidget.entitlements
   Assets.xcassets
   ```

3. In the dialog: **Copy items if needed = OFF**, **Create groups**, and
   under "Add to targets" tick **only `GoalioWidget`** (not Runner).
4. Click Add.

Then in the GoalioWidget target's Build Settings:

- Set **Info.plist File** to `GoalioWidget/Info.plist`.
- Set **Code Signing Entitlements** to
  `GoalioWidget/GoalioWidget.entitlements`.
- Set **iOS Deployment Target** to `17.0` (interactive widgets need iOS 17).

## 3. App Group capability

The widget reads the auth token from a shared App Group. It must exist on
**both** the Runner target and the GoalioWidget target.

1. Select the `Runner` target → Signing & Capabilities → **+ Capability**
   → App Groups → add `group.com.example.goalFixturesApp`.
2. Select the `GoalioWidget` target → Signing & Capabilities → **+
   Capability** → App Groups → add the same `group.com.example.goalFixturesApp`.
3. In the Apple Developer portal (or via Xcode's automatic signing), make
   sure both provisioning profiles have the App Group added.

If you change the App Group ID, update **all three** of these places to
match:

- [Runner.entitlements](../Runner/Runner.entitlements)
- [GoalioWidget.entitlements](GoalioWidget.entitlements)
- [SharedConfig.swift](SharedConfig.swift) (`SharedConfig.appGroup`) and
  [WidgetBridge.swift](../Runner/WidgetBridge.swift) (`WidgetBridge.appGroup`)

## 4. Build & run

1. Stop any running build.
2. Select the **Runner** scheme and run on a simulator/device. This
   installs both the app and the widget extension.
3. Long-press the home screen → tap **+** → search "Goalio" → add the
   medium or large widget.
4. Open the Goalio app and sign in. The auth token is mirrored into the
   App Group via the `com.goalio.widget/bridge` method channel
   ([widget_bridge.dart](../../lib/core/services/widget_bridge.dart) →
   [WidgetBridge.swift](../Runner/WidgetBridge.swift)).
5. The widget refreshes within ~30 seconds (or tap the refresh icon).

## 5. Deep links

The widget already wires `goalio://home` and `goalio://match?id=…` URLs
via SwiftUI `Link` and `widgetURL`. The URL scheme `goalio` is registered
in [Runner/Info.plist](../Runner/Info.plist).

To handle them in the Flutter app, add a deep-link handler (e.g.
`app_links` package) that listens for incoming URLs and routes:
- `goalio://home` → home screen
- `goalio://match?id=<id>` → match details for that id

Until that handler exists the OS will simply launch the app to its last
state, which is also acceptable behaviour for v1.

## 6. App icon for the extension (cosmetic)

Xcode's widget gallery uses the extension's `AppIcon`. Drop your 1024×1024
square icon into `Assets.xcassets/AppIcon.appiconset/` (Xcode can generate
this when you double-click the assets catalog). The widget body itself
already shows the app logo via `WidgetLogo.imageset` (already populated
with `goalio_logo.png`).

## Architecture mirror

| Concern              | Android (Glance)                                  | iOS (WidgetKit)                                |
| -------------------- | ------------------------------------------------- | ---------------------------------------------- |
| Entry point          | `GoalioWidgetReceiver`                            | `GoalioWidgetBundle` + `GoalioWidget`          |
| Periodic refresh     | `WidgetUpdateWorker` every 30 min                 | `Timeline(policy: .after(+30 min))`            |
| Manual refresh       | `RefreshAction` (Glance ActionCallback)           | `RefreshIntent` (AppIntent, iOS 17+)           |
| Pagination           | `NextPageAction`/`PrevPageAction` + DataStore     | `NextPageIntent`/`PrevPageIntent` + UserDefaults |
| Auth token           | `AuthTokenReader` reads `FlutterSharedPreferences` | `MatchAPI` reads `UserDefaults(suiteName:)`    |
| Logo download        | `BitmapLoader` (96 px)                            | `MatchAPI.preloadLogos` (96 px)                |
| Deep link to match   | `OpenMatchAction` → `goalio://match?id=`          | `Link(destination: goalio://match?id=)`        |
| Deep link to home    | Whole-widget click → `goalio://home`              | Outer `Link(destination: goalio://home)`       |
| Theme colors         | `WidgetTheme.kt`                                  | `Theme.swift`                                  |
| Backend endpoint     | `https://goalio.site/api/widget/matches`          | same                                           |

Same JSON contract on both sides:
`{ yesterday[], today[], tomorrow[], has_favorites }` — see
[WidgetController.php](../../../goalio_backend/app/Http/Controllers/Api/WidgetController.php).
