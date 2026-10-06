@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not in PATH.
  pause
  exit /b 1
)
if not exist android\app (
  call flutter create --org com.sabroso --project-name sabroso_rider --platforms android,ios .
  if errorlevel 1 goto fail
)
if not exist setup\android\AndroidManifest.xml (
  echo ERROR: setup\android\AndroidManifest.xml is missing. Restore it and run again.
  goto fail
)
copy /Y setup\android\AndroidManifest.xml android\app\src\main\AndroidManifest.xml >nul
findstr /C:"android.permission.INTERNET" android\app\src\main\AndroidManifest.xml >nul
if errorlevel 1 (
  echo ERROR: AndroidManifest.xml must have the INTERNET permission. Fix it and run again.
  goto fail
)
findstr /C:"android:usesCleartextTraffic=\"true\"" android\app\src\main\AndroidManifest.xml >nul
if errorlevel 1 (
  echo ERROR: AndroidManifest.xml must have android:usesCleartextTraffic="true". Fix it and run again.
  goto fail
)
echo Manifest OK: INTERNET + cleartext
call flutter pub get
if errorlevel 1 goto fail
call flutter build apk --release
if errorlevel 1 goto fail
if not exist output mkdir output
copy /Y build\app\outputs\flutter-apk\app-release.apk output\SabrosoRider.apk >nul
echo.
echo APK ready: %cd%\output\SabrosoRider.apk
pause
exit /b 0
:fail
echo.
echo Build failed. Scroll up to see the error.
pause
exit /b 1
