#!/bin/bash
set -e
cd "$(dirname "$0")"
if [ ! -d android/app ]; then
  flutter create --org com.sabroso --project-name sabroso_rider --platforms android,ios .
fi
M=android/app/src/main/AndroidManifest.xml
if [ ! -f setup/android/AndroidManifest.xml ]; then
  echo "ERROR: setup/android/AndroidManifest.xml is missing. Restore it and run again."
  exit 1
fi
cp setup/android/AndroidManifest.xml "$M"
if ! grep -q 'android.permission.INTERNET' "$M" || ! grep -q 'android:usesCleartextTraffic="true"' "$M"; then
  echo "ERROR: $M must have the INTERNET permission and android:usesCleartextTraffic=\"true\". Fix it and run again."
  exit 1
fi
echo "Manifest OK: INTERNET + cleartext"
flutter pub get
flutter build apk --release
mkdir -p output
cp build/app/outputs/flutter-apk/app-release.apk output/SabrosoRider.apk
echo "APK ready: $(pwd)/output/SabrosoRider.apk"
