# Run from the BetterRoute root after installing Flutter.
# This creates the standard Android/iOS/Web platform folders without replacing the app source.
Set-Location "$PSScriptRoot\..\frontend"
flutter create --platforms=android,ios,web .
Write-Host "Flutter platform folders created. Run: flutter pub get"
Write-Host "For Android emulator, the app already points to http://10.0.2.2:8080."
Write-Host "For a physical phone, edit lib/services/api.dart and use your PC LAN IP."
