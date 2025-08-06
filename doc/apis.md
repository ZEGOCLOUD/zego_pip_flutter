# ZegoPIP API Documentation

## Table of Contents

- [ZegoPIP API Documentation](#zegopip-api-documentation)
  - [Table of Contents](#table-of-contents)
  - [ZegoPIP](#zegopip)
    - [init](#init)
    - [uninit](#uninit)
    - [version](#version)
    - [enable](#enable)
    - [enableWhenBackground](#enablewhenbackground)
    - [cancelBackground](#cancelbackground)
  - [ZegoPIPConfig](#zegopipconfig)
  - [ZegoPIPExpressConfig](#zegopipexpressconfig)
  - [ZegoPIPExpressCreateConfig](#zegopipexpresscreateconfig)
  - [ZegoStreamInfo](#zegostreaminfo)
  - [ZegoPIPExpressEvent](#zegopipexpressevent)
  - [ZegoPipPlatform](#zegopipplatform)
  - [Usage Examples](#usage-examples)
    - [Basic Usage](#basic-usage)
    - [Using ZegoPIPVideoView Component](#using-zegopipvideoview-component)
    - [Advanced Usage with External Engine](#advanced-usage-with-external-engine)

---

## [ZegoPIP](../lib/core/zego_pip.dart)

> ZegoPIP is a singleton class for managing Picture-in-Picture (PIP) functionality.
>
> You can access the instance via `ZegoPIP()` and call its APIs.

### init

> Initialize the PIP functionality.
>
> This method must be called before using any other PIP features.
> It sets up the ZEGO Express engine and configures the PIP system.
>
> If `expressConfig` is provided, it will automatically create the ZEGO Express engine and register related events.
> If not provided, you need to create the engine externally and call `ZegoPip.instance.event` after listening to express events.
>
> - Function signature:
>
> ```dart
> Future<bool> init({
>   ZegoPIPConfig config = const ZegoPIPConfig(),
>   ZegoPIPExpressConfig? expressConfig,
> }) async
> ```
>
> - Parameters:
>   - `config`: PIP configuration including aspect ratio and other settings
>   - `expressConfig`: ZEGO Express engine configuration. If null, it means the client has already created the express engine;
>                     If not null, zego_pip will internally create the express engine and register related express events.
>                     The expressConfig contains create, room, and event configurations.
>
> - Returns: `true` if initialization is successful, `false` otherwise.
>
> - Example:
>
> ```dart
> final success = await ZegoPIP().init(
>   config: ZegoPIPConfig(aspectWidth: 9, aspectHeight: 16),
>   expressConfig: ZegoPIPExpressConfig(
>     create: ZegoPIPExpressCreateConfig(
>       appID: yourAppID,
>       appSign: yourAppSign,
>     ),
>     room: ZegoPIPExpressRoomConfig(
>       roomID: 'test_room_id',
>       userID: 'test_user_id',
>       userName: 'test_user_name',
>     ),
>   ),
> );
> ```

### uninit

> Deinitialize the PIP functionality.
>
> This method cleans up all resources and stops the PIP system.
> It should be called when the app is shutting down or when PIP is no longer needed.
>
> - Function signature:
>
> ```dart
> Future<void> uninit() async
> ```
>
> - Example:
>
> ```dart
> await ZegoPIP().uninit();
> ```

### version

> Get the current version number.
>
> - Function signature:
>
> ```dart
> String get version
> ```
>
> - Example:
>
> ```dart
> final version = ZegoPIP().version;
> ```

### enable

> Actively enable PIP mode.
>
> This method enables Picture-in-Picture mode for the current video stream.
> The user can then minimize the app and continue watching the video in a floating window.
>
> - Function signature:
>
> ```dart
> Future<PiPStatus> enable() async
> ```
>
> - Returns: The current [PiPStatus] indicating whether PIP was successfully enabled.
>
> - Example:
>
> ```dart
> final status = await ZegoPIP().enable();
> ```

### enableWhenBackground

> Enable PIP mode when the app goes to background.
>
> This method configures the system to automatically enter PIP mode
> when the user switches to another app or minimizes the current app.
>
> - Function signature:
>
> ```dart
> Future<PiPStatus> enableWhenBackground() async
> ```
>
> - Returns: The current [PiPStatus] indicating whether background PIP was successfully enabled.
>
> - Example:
>
> ```dart
> final status = await ZegoPIP().enableWhenBackground();
> ```

### cancelBackground

> Actively cancel background PIP mode.
>
> This method disables the automatic PIP mode that was enabled by [enableWhenBackground].
> After calling this method, the app will no longer automatically enter PIP mode when going to background.
>
> - Function signature:
>
> ```dart
> Future<void> cancelBackground() async
> ```
>
> - Example:
>
> ```dart
> await ZegoPIP().cancelBackground();
> ```

---

## [ZegoPIPConfig](../lib/core/defines.dart)

> Configuration class for PIP settings.
>
> This class contains the basic configuration parameters for Picture-in-Picture functionality,
> such as aspect ratio settings.
>
> - Class signature:
>
> ```dart
> class ZegoPIPConfig {
>   const ZegoPIPConfig({
>     this.aspectWidth = 9,
>     this.aspectHeight = 16,
>   });
>
>   final int aspectWidth;
>   final int aspectHeight;
> }
> ```
>
> - Parameters:
>   - `aspectWidth`: Width aspect ratio for the PIP window (default: 9)
>   - `aspectHeight`: Height aspect ratio for the PIP window (default: 16)
>
> - Example:
>
> ```dart
> const config = ZegoPIPConfig(aspectWidth: 16, aspectHeight: 9);
> ```

---

## [ZegoPIPExpressConfig](../lib/core/defines.dart)

> Configuration class for ZEGO Express engine integration.
>
> This class contains all the configuration parameters needed to initialize
> the ZEGO Express engine and set up room connections.
>
> - Class signature:
>
> ```dart
> class ZegoPIPExpressConfig {
>   ZegoPIPExpressConfig({
>     this.create,
>     this.room,
>     this.event,
>   });
>
>   ZegoPIPExpressCreateConfig? create;
>   ZegoPIPExpressRoomConfig? room;
>   ZegoPIPExpressEvent? event;
> }
> ```
>
> - Parameters:
>   - `create`: Configuration for creating ZEGO Express engine. If provided, zego_pip will internally create the express engine.
>   - `room`: Configuration for automatic room login. If provided, zego_pip will automatically login to the specified room.
>   - `event`: Express event callbacks. If the express engine is created externally, the client needs to actively listen to express events 
>             and forward them to zego_pip. This interface defines all the callback methods that can be implemented.
>
> - Example:
>
> ```dart
> final config = ZegoPIPExpressConfig(
>   create: ZegoPIPExpressCreateConfig(
>     appID: 1234567890,
>     appSign: 'your_app_sign',
>   ),
>   room: ZegoPIPExpressRoomConfig(
>     roomID: 'test_room_id',
>     userID: 'test_user_id',
>     userName: 'test_user_name',
>   ),
> );
> ```

---

## [ZegoPIPExpressCreateConfig](../lib/core/defines.dart)

> Configuration class for creating ZEGO Express engine.
>
> This class contains the configuration parameters needed to create the ZEGO Express engine.
>
> - Class signature:
>
> ```dart
> class ZegoPIPExpressCreateConfig {
>   ZegoPIPExpressCreateConfig({
>     required this.appID,
>     required this.appSign,
>     this.scenario = ZegoScenario.Default,
>   });
>
>   int appID;
>   String appSign;
>   ZegoScenario scenario;
> }
> ```
>
> - Parameters:
>   - `appID`: ZEGO application ID, obtained from ZEGO console
>   - `appSign`: ZEGO application signature, obtained from ZEGO console
>   - `scenario`: ZEGO scenario configuration. This determines the optimization strategy for the ZEGO Express engine
>
> - Example:
>
> ```dart
> final createConfig = ZegoPIPExpressCreateConfig(
>   appID: 1234567890,
>   appSign: 'your_app_sign',
>   scenario: ZegoScenario.Default,
> );
> ```
>
> ---
>
> ## [ZegoPIPExpressRoomConfig](../lib/core/defines.dart)
>
> Configuration class for automatic room login.
>
> This class contains the configuration parameters needed for automatic room login.
>
> - Class signature:
>
> ```dart
> class ZegoPIPExpressRoomConfig {
>   ZegoPIPExpressRoomConfig({
>     required this.roomID,
>     required this.userID,
>     required this.userName,
>   });
>
>   String roomID;
>   String userID;
>   String userName;
> }
> ```
>
> - Parameters:
>   - `roomID`: Room ID for automatic login. The system will automatically login to this room
>   - `userID`: User ID for room login. This is the unique identifier for the user in the room
>   - `userName`: User name for room login. This is the display name for the user in the room
>
> - Properties:
>   - `canLoginRoom`: Whether the configuration is complete for automatic room login (returns true if roomID, userID, and userName are all provided and not empty)
>
> - Example:
>
> ```dart
> final roomConfig = ZegoPIPExpressRoomConfig(
>   roomID: 'test_room_id',
>   userID: 'test_user_id',
>   userName: 'test_user_name',
> );
> ```
>
> ---
>
> ## [ZegoPIPVideoView](../lib/components/zego_video_view.dart)

> A Flutter widget that displays video streams with automatic PIP support.
>
> This widget automatically handles video rendering and PIP mode switching.
> It can be used as a drop-in replacement for regular video views in your app.
>
> The widget hierarchy (from bottom to top) is:
> 1. background view
> 2. video view
> 3. foreground view
>
> - Class signature:
>
> ```dart
> class ZegoPIPVideoView extends StatefulWidget {
>   const ZegoPIPVideoView({
>     super.key,
>     required this.streamID,
>     this.loadingBuilder,
>     this.userViewNullBuilder,
>   });
>
>   final String streamID;
>   final Widget Function(BuildContext context)? loadingBuilder;
>   final Widget Function(BuildContext context)? userViewNullBuilder;
> }
> ```
>
> - Parameters:
>   - `streamID`: The unique identifier for the video stream to display
>   - `loadingBuilder`: Optional builder for the loading state. If provided, this widget will be shown while the video is loading
>   - `userViewNullBuilder`: Optional builder for when the user view is null. If provided, this widget will be shown when there's no video content to display
>
> - Example:
>
> ```dart
> ZegoPIPVideoView(
>   streamID: 'stream123',
>   loadingBuilder: (context) => CircularProgressIndicator(),
>   userViewNullBuilder: (context) => Text('No video available'),
> )
> ```

---

## [ZegoStreamInfo](../lib/core/private/defines.dart)

> Information class for managing video stream data.
>
> This class contains all the information needed to manage a video stream,
> including stream ID, device states, player state, and view information.
>
> - Class signature:
>
> ```dart
> class ZegoStreamInfo {
>   String streamID = '';
>   ValueNotifier<bool> camera = ValueNotifier<bool>(true);
>   ValueNotifier<bool> microphone = ValueNotifier<bool>(true);
>   ValueNotifier<ZegoPlayerState> stateNotifier = ValueNotifier(ZegoPlayerState.NoPlay);
>   ValueNotifier<int?> viewIDNotifier = ValueNotifier<int?>(-1);
>   ValueNotifier<Widget?> viewNotifier = ValueNotifier<Widget?>(null);
>   ValueNotifier<Size> viewSizeNotifier = ValueNotifier<Size>(const Size(360, 640));
> }
> ```
>
> - Properties:
>   - `streamID`: Unique identifier for the video stream
>   - `camera`: Camera state for the stream. Default enabled, will receive event notification if disabled
>   - `microphone`: Microphone state for the stream. Default enabled, will receive event notification if disabled
>   - `stateNotifier`: Current player state for the stream
>   - `viewIDNotifier`: View ID for the stream's video view
>   - `viewNotifier`: Widget for the stream's video view
>   - `viewSizeNotifier`: Size of the video view
>
> - Methods:
>   - `clear()`: Clear all stream information and reset to default values
>
> - Example:
>
> ```dart
> final streamInfo = ZegoStreamInfo.empty();
> streamInfo.streamID = 'stream123';
> ```

---

## [ZegoPIPExpressEvent](../lib/core/defines.dart)

> Event callback interface for ZEGO Express engine events.
>
> If the express engine is created externally, the client needs to actively listen to express events 
> and forward them to zego_pip. This interface defines all the callback methods that can be implemented.
>
> - Class signature:
>
> ```dart
> class ZegoPIPExpressEvent {
>   Function(ZegoEngineState state)? onEngineStateUpdate;
>   Function(int errorCode, String funcName, String info)? onDebugError;
>   Function(String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData)? onRoomStreamUpdate;
>   Function(String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData)? onRoomStateChanged;
>   Function(String streamID, ZegoPlayerState state, int errorCode, Map<String, dynamic> extendedData)? onPlayerStateUpdate;
>   Function(String streamID, ZegoRemoteDeviceState state)? onRemoteCameraStateUpdate;
>   Function(String streamID, ZegoRemoteDeviceState state)? onRemoteMicStateUpdate;
> }
> ```
>
> - Events:
>   - `onEngineStateUpdate`: Engine state update event
>   - `onDebugError`: Debug error event
>   - `onRoomStreamUpdate`: Room stream update event
>   - `onRoomStateChanged`: Room state change event
>   - `onPlayerStateUpdate`: Player state update event
>   - `onRemoteCameraStateUpdate`: Remote camera state update event
>   - `onRemoteMicStateUpdate`: Remote microphone state update event
>
> - Example:
>
> ```dart
> final event = ZegoPIPExpressEvent();
> event.onEngineStateUpdate = (state) {
>   print('Engine state: $state');
> };
> ```

---

## [ZegoPipPlatform](../lib/core/channel/zego_pip_platform_interface.dart)

> Platform interface for PIP functionality.
>
> This abstract class defines the interface for platform-specific PIP implementations.
> It provides a common API that can be implemented differently for iOS and Android.
>
> The default implementation is [MethodChannelZegoPip] which uses platform channels
> to communicate with native code.
>
> - Class signature:
>
> ```dart
> abstract class ZegoPipPlatform extends PlatformInterface {
>   // Platform-specific methods
>   Future<void> startPlayingStreamInPIP(String streamID);
>   Future<void> stopPlayingStreamInPIP(String streamID);
>   Future<void> updatePlayingStreamViewInPIP(int viewID, String streamID, int viewMode);
>   Future<void> enableCustomVideoRender(bool isEnabled);
>   Future<void> enableHardwareDecoder(bool isEnabled);
>   Future<bool> stopIOSPIP();
>   Future<bool> isIOSInPIP();
>   Future<void> enableIOSPIP(String streamID, {int aspectWidth = 9, int aspectHeight = 16});
>   Future<void> updateIOSPIPSource(String streamID);
>   Future<void> enableIOSPIPAuto(bool isEnabled, {int aspectWidth = 9, int aspectHeight = 16});
> }
> ```
>
> - Methods:
>   - `startPlayingStreamInPIP()`: Start playing a video stream in picture-in-picture mode
>   - `stopPlayingStreamInPIP()`: Stop playing a video stream in picture-in-picture mode
>   - `updatePlayingStreamViewInPIP()`: Update the playing stream view in picture-in-picture mode
>   - `enableCustomVideoRender()`: Enable or disable custom video rendering
>   - `enableHardwareDecoder()`: Enable or disable hardware decoder (iOS only)
>   - `stopIOSPIP()`: Stop iOS picture-in-picture mode (iOS only)
>   - `isIOSInPIP()`: Check if iOS is in picture-in-picture mode (iOS only)
>   - `enableIOSPIP()`: Enable iOS picture-in-picture mode (iOS only)
>   - `updateIOSPIPSource()`: Update iOS picture-in-picture source stream (iOS only)
>   - `enableIOSPIPAuto()`: Enable iOS auto picture-in-picture mode (iOS only)

---

## Usage Examples

### Basic Usage

```dart
import 'package:zego_pip/zego_pip.dart';

// Initialize
await ZegoPIP().init(
  config: ZegoPIPConfig(aspectWidth: 16, aspectHeight: 9),
  expressConfig: ZegoPIPExpressConfig(
    create: ZegoPIPExpressCreateConfig(
      appID: yourAppID,
      appSign: yourAppSign,
    ),
    room: ZegoPIPExpressRoomConfig(
      roomID: 'test_room_id',
      userID: 'test_user_id',
      userName: 'test_user_name',
    ),
  ),
);

// Enable PIP mode
await ZegoPIP().enable();

// Enable PIP mode when app goes to background
await ZegoPIP().enableWhenBackground();
```

### Using ZegoPIPVideoView Component

```dart
import 'package:zego_pip/zego_pip.dart';

ZegoPIPVideoView(
  streamID: 'stream123',
  loadingBuilder: (context) => Center(
    child: CircularProgressIndicator(),
  ),
  userViewNullBuilder: (context) => Center(
    child: Text('No video available'),
  ),
)
```

### Advanced Usage with External Engine

```dart
import 'package:zego_pip/zego_pip.dart';

// If you have your own ZEGO Express engine
await ZegoPIP().init(
  config: ZegoPIPConfig(aspectWidth: 9, aspectHeight: 16),
  // Don't provide expressConfig if you manage the engine externally
);

// Set up event forwarding
ZegoPIP().private.event?.onEngineStateUpdate = (state) {
  print('Engine state: $state');
};

ZegoPIP().private.event?.onPlayerStateUpdate = (streamID, state, errorCode, extendedData) {
  print('Player state: $state for stream: $streamID');
};
```
