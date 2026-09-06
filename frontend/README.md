# BetterRoute Flutter app

## Setup

```bash
flutter pub get
flutter run
```

The API defaults to `http://10.0.2.2:8080`, which is the Android Emulator alias for your host machine.

For a physical Android device, change `baseUrl` in `lib/services/api.dart` to your computer's LAN IP, for example `http://192.168.1.10:8080`.

MapLibre uses the public demo style in this MVP. For production, use a proper tile/style provider and follow its attribution/usage terms.
