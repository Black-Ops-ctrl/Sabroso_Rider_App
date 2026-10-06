#!/bin/bash
set -e
cd "$(dirname "$0")/../.."
P=ios/Runner/Info.plist
B=/usr/libexec/PlistBuddy
add() { $B -c "Delete :$1" "$P" 2>/dev/null || true; $B -c "Add :$1 $2 $3" "$P"; }
add CFBundleDisplayName string "Sabroso Rider App"
add UIStatusBarHidden bool false
add UIViewControllerBasedStatusBarAppearance bool true
add NSLocationWhenInUseUsageDescription string "Your location is shared with the shop while you are on duty."
add NSLocationAlwaysAndWhenInUseUsageDescription string "Your location is shared with the shop while you are on duty, even when the app is in the background."
add NSLocationAlwaysUsageDescription string "Your location is shared with the shop while you are on duty, even when the app is in the background."
$B -c "Delete :UIBackgroundModes" "$P" 2>/dev/null || true
$B -c "Add :UIBackgroundModes array" "$P"
$B -c "Add :UIBackgroundModes:0 string location" "$P"
$B -c "Add :UIBackgroundModes:1 string fetch" "$P"
$B -c "Add :UIBackgroundModes:2 string processing" "$P"
$B -c "Delete :NSAppTransportSecurity" "$P" 2>/dev/null || true
$B -c "Add :NSAppTransportSecurity dict" "$P"
$B -c "Add :NSAppTransportSecurity:NSAllowsArbitraryLoads bool true" "$P"
$B -c "Delete :LSApplicationQueriesSchemes" "$P" 2>/dev/null || true
$B -c "Add :LSApplicationQueriesSchemes array" "$P"
$B -c "Add :LSApplicationQueriesSchemes:0 string tel" "$P"
$B -c "Add :LSApplicationQueriesSchemes:1 string https" "$P"
$B -c "Add :LSApplicationQueriesSchemes:2 string comgooglemaps" "$P"
$B -c "Delete :BGTaskSchedulerPermittedIdentifiers" "$P" 2>/dev/null || true
$B -c "Add :BGTaskSchedulerPermittedIdentifiers array" "$P"
$B -c "Add :BGTaskSchedulerPermittedIdentifiers:0 string dev.flutter.background.refresh" "$P"
if [ ! -f ios/Podfile ]; then
  flutter build ios --config-only --no-codesign >/dev/null 2>&1 || true
fi
if [ -f ios/Podfile ] && ! grep -q PERMISSION_NOTIFICATIONS ios/Podfile; then
  perl -0pi -e 's/(flutter_additional_ios_build_settings\(target\)\n)/$1    target.build_configurations.each do |config|\n      config.build_settings["GCC_PREPROCESSOR_DEFINITIONS"] ||= ["\$(inherited)", "PERMISSION_LOCATION=1", "PERMISSION_NOTIFICATIONS=1"]\n    end\n/' ios/Podfile
fi
echo "iOS Info.plist and Podfile updated"
