# Sabroso Rider (Flutter)

Rider app for the Sabroso Home Delivery Control Centre.

## Build the APK (Windows)

1. Install Flutter (stable, 3.24 or newer) and Android Studio (Android SDK). Check with `flutter doctor`.
2. Double-click `build_apk.bat`.
3. Install `output\SabrosoRider.apk` on the phone (allow "Install unknown apps").

The first run executes `flutter create` (creates the `android` and `ios` folders) and then copies
`setup/android/AndroidManifest.xml` into `android/app/src/main/AndroidManifest.xml`. The copy runs on every build.

Linux / macOS: `bash build_apk.sh`.

## Build on GitHub (no setup on the PC)

Push this folder to a GitHub repo. The workflow `.github/workflows/build-apk.yml` builds the APK;
download it from **Actions → latest run → Artifacts → SabrosoRider-apk**.

## iPhone (testing)

On a Mac with Xcode:

1. `flutter create --org com.sabroso --project-name sabroso_rider --platforms android,ios .`
2. `bash setup/ios/ios_setup.sh` (adds location "Always" texts, background modes `location` + `fetch` + `processing`, cleartext HTTP, tel/https/Google Maps URL schemes, and the permission_handler Podfile flags).
3. Open `ios/Runner.xcworkspace`, pick your Apple ID team, then in **Signing & Capabilities** add **Background Modes** and tick **Location updates** (the script writes the Info.plist keys; the capability tick keeps Xcode in sync).
4. Run on the phone.

## Server address

Default: `http://84.16.235.111:2193/api` (`lib/core/config.dart`).
Another server without editing code: `flutter build apk --release --dart-define=API_URL=http://host:port/api`.

## Rider login

Username and password are set on the web in **Riders → Add / Edit rider**.

## How it works

- Splash loads the brand (logo, name), the app colours (`GET /app-theme`) and checks the saved session.
- Login keeps the session until the rider logs out, or until the web makes the rider inactive (the app then returns to Login).
- The setup screen shows until GPS, Location "Allow all the time", Notifications and Battery "No restrictions" are all enabled.
- While on duty a foreground service ("Sabroso Rider · On duty") sends the location every 10 seconds, also when the app is closed.
  Points are queued on the phone when there is no internet and sent later in batches.
- Web changes arrive through one live connection (`/rider/live`); the profile is also re-checked every 60 seconds.

## Code layout

```
lib/
  main.dart, app.dart            start-up, providers, navigator, toast host
  core/                          api client, live (SSE) client, store, models, formatting, polyline
  theme/                         app colours (web-overridable keys), brand provider, scaling helpers
  services/                      permissions, url launcher, notification (push token) service
  tracking/                      background location service and tracker
  widgets/                       shared UI: toast pill, slide button, cards, routes, header
  features/
    splash/  auth/  setup/  shell/  home/  orders/  history/  order_detail/  settings/
```
