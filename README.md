# zego_pip

A Flutter Picture-in-Picture (PIP) plugin based on `zego_express_engine`, supporting iOS and Android platforms.

[English](README.md) | [中文](README_CN.md)

## Demo

### iOS Platform

![iOS PIP Demo](https://media-resource.spreading.io/docuo/workspace741/896bc39e2e65b82d5670b01b7c131c30/f4d7ee5447.gif)
### Android Platform

![Android PIP Demo](https://media-resource.spreading.io/docuo/workspace741/896bc39e2e65b82d5670b01b7c131c30/c7d1bf500a.gif)

## Features

- 🎥 **Cross-platform Support**: Supports iOS 15.0+ and Android 8.0+
- 🚀 **Ready to Use**: Zero configuration, one-click PIP enablement
- 🔄 **Auto Switching**: Intelligent PIP mode switching
- 🎯 **Performance Optimized**: Built-in video rendering optimization and memory management

## Installation

### 1. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  zego_pip: ^0.0.1
  zego_express_engine: ^3.21.0
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. iOS Configuration

Set minimum version in `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

Then run:

```bash
cd ios
pod install
cd ..
```

### 4. Android Configuration

Ensure `minSdkVersion` in `android/app/build.gradle` is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

Add `android:supportsPictureInPicture="true"` to the `<activity>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
  <application>
    <activity
      android:name=".MainActivity"
      android:supportsPictureInPicture="true"
      ...
    />
  </application>
</manifest>
```

#### Android Permissions

The plugin automatically adds the following necessary permissions to your app:

| Permission Category                      | Permission Name                                            | Purpose                               | Minimum API Level |
| ---------------------------------------- | ---------------------------------------------------------- | ------------------------------------- | ----------------- |
| **Network Permissions**            | `android.permission.INTERNET`                            | Network access for video streaming    | API 1             |
|                                          | `android.permission.ACCESS_NETWORK_STATE`                | Network state access                  | API 1             |
|                                          | `android.permission.ACCESS_WIFI_STATE`                   | WiFi state access                     | API 1             |
| **Audio Permissions**              | `android.permission.RECORD_AUDIO`                        | Audio recording for audio capture     | API 1             |
|                                          | `android.permission.MODIFY_AUDIO_SETTINGS`               | Audio settings modification           | API 1             |
| **Camera Permissions**             | `android.permission.CAMERA`                              | Camera access for video capture       | API 1             |
| **Foreground Service Permissions** | `android.permission.FOREGROUND_SERVICE`                  | Foreground service for background PIP | API 26            |
|                                          | `android.permission.FOREGROUND_SERVICE_MICROPHONE`       | Foreground service microphone         | API 34            |
|                                          | `android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION` | Foreground service media projection   | API 34            |
| **System Permissions**             | `android.permission.SYSTEM_ALERT_WINDOW`                 | System overlay for PIP window display | API 1             |

## Quick Start

### 1. Initialize

#### Method 1: zego_pip Internal Engine Creation 

```dart
import 'package:zego_pip/zego_pip.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ZegoPIP().init(
    /// zego_pip internally creates the express engine, listens for events, and logs into the room
    expressConfig: ZegoPIPExpressConfig(
      create: ZegoPIPExpressCreateConfig(
        // Please fill in your own app id
        appID: 1234567890,
        // Please fill in your own app sign
        appSign: 'your_app_sign_here',
      ),
      room: ZegoPIPExpressRoomConfig(
        // Please fill in your own room id
        roomID: 'test_room_id',
        // Please fill in your own room login user info
        userID: 'test_user_id',
        userName: 'test_user_name',
      ),
    ),
  );

  runApp(
    const MaterialApp(
      home: Scaffold(
        // Please fill in your own stream id
        body: Center(child: ZegoPIPVideoView(streamID: 'test_stream_id')),
      ),
    ),
  );
}
```

#### Method 2: External Engine Creation(Recommended)

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_pip/zego_pip.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ZegoExpressManager().init();

  /// Before ZegoPIP.init, you must first create the express engine
  await ZegoPIP().init(
    expressConfig: ZegoPIPExpressConfig(
      event: ZegoExpressManager().pipExpressEvent,
    ),
  );

  /// ZegoPIPVideoView can only be rendered after logging into the room from other parts of the app
  await ZegoExpressManager().loginRoom();

  runApp(
    const MaterialApp(
      home: Scaffold(
        /// Please fill in your own stream id
        body: Center(child: ZegoPIPVideoView(streamID: 'test_stream_id')),
      ),
    ),
  );
}

class ZegoExpressManager {
  factory ZegoExpressManager() {
    return shared;
  }

  static final ZegoExpressManager shared = ZegoExpressManager._internal();
  ZegoExpressManager._internal();

  var pipExpressEvent = ZegoPIPExpressEvent();

  Future<void> init() async {
    ZegoExpressEngine.onEngineStateUpdate = onEngineStateUpdate;
    ZegoExpressEngine.onDebugError = onDebugError;
    ZegoExpressEngine.onRoomStreamUpdate = onRoomStreamUpdate;
    ZegoExpressEngine.onRoomStateChanged = onRoomStateChanged;
    ZegoExpressEngine.onPlayerStateUpdate = onPlayerStateUpdate;
    ZegoExpressEngine.onRemoteCameraStateUpdate = onRemoteCameraStateUpdate;
    ZegoExpressEngine.onRemoteMicStateUpdate = onRemoteMicStateUpdate;

    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(
        1234567890,
        ZegoScenario.Default,
        appSign: 'your app sign',
        /// Please ensure that `enablePlatformView` is set to true
        enablePlatformView: true,
      ),
    );
  }

  Future<bool> loginRoom() async {
    final result = await ZegoExpressEngine.instance.loginRoom(
      /// Please fill in your own room id
      'test_room_id',
      ZegoUser(
        /// Please fill in your own room login user info
        'test_user_id',
        'test_user_name',
      ),
      config: ZegoRoomConfig(0, true, ''),
    );

    return 0 == result.errorCode;
  }

  /// Forward express event to zego_pip
  void onEngineStateUpdate(ZegoEngineState state) {
    pipExpressEvent.onEngineStateUpdate?.call(state);
  }

  void onDebugError(int errorCode, String funcName, String info) {
    pipExpressEvent.onDebugError?.call(errorCode, funcName, info);
  }

  void onRoomStreamUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoStream> streamList,
    Map<String, dynamic> extendedData,
  ) {
    pipExpressEvent.onRoomStreamUpdate?.call(
      roomID,
      updateType,
      streamList,
      extendedData,
    );
  }

  void onRoomStateChanged(
    String roomID,
    ZegoRoomStateChangedReason reason,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    pipExpressEvent.onRoomStateChanged?.call(
      roomID,
      reason,
      errorCode,
      extendedData,
    );
  }

  void onPlayerStateUpdate(
    String streamID,
    ZegoPlayerState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    pipExpressEvent.onPlayerStateUpdate?.call(
      streamID,
      state,
      errorCode,
      extendedData,
    );
  }

  void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    pipExpressEvent.onRemoteCameraStateUpdate?.call(streamID, state);
  }

  void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    pipExpressEvent.onRemoteMicStateUpdate?.call(streamID, state);
  }
}
```

### 2. Use Video Component

```dart
class VideoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Room')),
      body: ZegoPIPVideoView(
        streamID: 'stream_id',
        // PIP functionality automatically enabled
      ),
    );
  }
}
```

### 3. Manual PIP Control (Optional)

```dart
class PIPController {
  final zegoPIP = ZegoPIP();
  
  // Enable PIP
  Future<void> enablePIP() async {
    await zegoPIP.enable();
  }
  
  // Update PIP source
  Future<void> updatePIPSource(String streamID) async {
    await zegoPIP.updateIOSPIPSource(streamID);
  }
  
  // Stop PIP
  Future<bool> stopPIP() async {
    return await zegoPIP.stopPIP();
  }
  
  // Check if in PIP mode
  Future<bool> isInPIP() async {
    return await zegoPIP.isInPIP();
  }
}
```

📖 **[API Documentation](https://pub.dev/documentation/zego_pip/latest/topics/APIs-topic.html)**

## Platform Support

### iOS

- **Minimum Version**: iOS 13.0
- **PIP Support**: iOS 15.0+
- **Features**: Native AVPictureInPictureController support

### Android

- **Minimum Version**: Android 8.0 (API 26)
- **PIP Support**: Android 8.0+
- **Features**: Native PictureInPicture mode support

## FAQ

### Q: Why doesn't PIP functionality work?

A: Please check:

1. Whether the plugin is properly initialized
2. Whether iOS version supports PIP (iOS 15.0+)
3. Whether Android version supports PIP (Android 8.0+)
4. Whether `zego_express_engine` dependency is added

### Q: How to handle PIP mode switching?

A: The plugin automatically handles mode switching, no manual intervention required.

### Q: How to customize PIP interface?

- Android: You can use ZegoPIPVideoView as a normal Widget in your widget tree.
- iOS: Currently the plugin uses system default PIP interface, customization is not supported yet.

## Known Issues

- When the remote stream camera is not enabled and ZegoPIPVideoView is rendered, the first desktop minimization after the remote stream enables camera will not show PIP window

## Contributing

Issues and Pull Requests are welcome!

## License

This project is licensed under the MIT License.
