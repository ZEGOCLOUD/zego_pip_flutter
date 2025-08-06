import 'package:zego_express_engine/zego_express_engine.dart';

/// Configuration class for PIP settings.
///
/// This class contains the basic configuration parameters for Picture-in-Picture functionality,
/// such as aspect ratio settings.
///
/// Example usage:
/// ```dart
/// ZegoPIPConfig(
///   aspectWidth: 9,
///   aspectHeight: 16,
/// )
/// ```
class ZegoPIPConfig {
  const ZegoPIPConfig({this.aspectWidth = 9, this.aspectHeight = 16});

  /// Width aspect ratio for the PIP window.
  ///
  /// This value is used to calculate the aspect ratio of the PIP window.
  /// Default value is 9.
  final int aspectWidth;

  /// Height aspect ratio for the PIP window.
  ///
  /// This value is used to calculate the aspect ratio of the PIP window.
  /// Default value is 16.
  final int aspectHeight;
}

/// Configuration class for ZEGO Express engine integration.
///
/// This class contains all the configuration parameters needed to initialize
/// the ZEGO Express engine and set up room connections.
///
/// Example usage:
/// ```dart
/// ZegoPIPExpressConfig(
///   create: ZegoPIPExpressCreateConfig(
///     appID: 1234567890,
///     appSign: 'your_app_sign',
///   ),
///   room: ZegoPIPExpressRoomConfig(
///     roomID: 'test_room_id',
///     userID: 'test_user_id',
///     userName: 'test_user_name',
///   ),
/// )
/// ```
class ZegoPIPExpressConfig {
  ZegoPIPExpressConfig({this.create, this.room, this.event});

  /// Configuration for creating ZEGO Express engine.
  ///
  /// If provided, zego_pip will internally create the express engine.
  /// If null, the client should create the express engine externally.
  ZegoPIPExpressCreateConfig? create;

  /// Configuration for automatic room login.
  ///
  /// If provided, zego_pip will automatically login to the specified room.
  /// If null, manual room login is required.
  ZegoPIPExpressRoomConfig? room;

  /// Express event callbacks
  ///
  /// If the express engine is created externally, the client needs to actively listen to express events
  /// and forward these events to zego_pip, as the internal logic depends on these events.
  ///
  /// Otherwise, zego_pip will internally listen to the corresponding events.
  ZegoPIPExpressEvent? event;
}

class ZegoPIPExpressCreateConfig {
  ZegoPIPExpressCreateConfig({
    required this.appID,
    required this.appSign,
    this.scenario = ZegoScenario.Default,
  });

  /// ZEGO application ID.
  ///
  /// This is the unique identifier for your ZEGO application.
  /// You can find this in your ZEGO console.
  int appID;

  /// ZEGO application signature.
  ///
  /// This is the security signature for your ZEGO application.
  /// You can find this in your ZEGO console.
  String appSign;

  /// ZEGO scenario configuration.
  ///
  /// This determines the optimization strategy for the ZEGO Express engine.
  /// Default value is [ZegoScenario.Default].
  ZegoScenario scenario;
}

class ZegoPIPExpressRoomConfig {
  ZegoPIPExpressRoomConfig({
    required this.roomID,
    required this.userID,
    required this.userName,
  });

  /// Room ID for automatic login.
  ///
  /// If not empty, the system will automatically login to this room.
  /// If null or empty, manual room login is required.
  String roomID;

  /// User ID for room login.
  ///
  /// This is the unique identifier for the user in the room.
  String userID;

  /// User name for room login.
  ///
  /// This is the display name for the user in the room.
  String userName;

  /// Whether the configuration is complete for automatic room login.
  ///
  /// Returns `true` if roomID, userID, and userName are all provided and not empty.
  bool get canLoginRoom =>
      (roomID.isNotEmpty) && (userID.isNotEmpty) && (userName.isNotEmpty);
}

/// Event callback interface for ZEGO Express engine events.
///
/// If the express engine is created externally, the client needs to actively listen to express events
/// and forward them to zego_pip. This interface defines all the callback methods that can be implemented.
///
/// Example usage:
/// ```dart
/// ZegoPIPExpressEvent(
///   onEngineStateUpdate: (state) {
///     print('Engine state: $state');
///   },
///   onPlayerStateUpdate: (streamID, state, errorCode, extendedData) {
///     print('Player state: $state for stream: $streamID');
///   },
/// )
/// ```
class ZegoPIPExpressEvent {
  ZegoPIPExpressEvent({
    this.onEngineStateUpdate,
    this.onDebugError,
    this.onRoomStreamUpdate,
    this.onRoomStateChanged,
    this.onPlayerStateUpdate,
    this.onRemoteCameraStateUpdate,
    this.onRemoteMicStateUpdate,
  });

  Function(ZegoEngineState state)? onEngineStateUpdate;
  Function(int errorCode, String funcName, String info)? onDebugError;
  Function(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoStream> streamList,
    Map<String, dynamic> extendedData,
  )?
  onRoomStreamUpdate;
  Function(
    String roomID,
    ZegoRoomStateChangedReason reason,
    int errorCode,
    Map<String, dynamic> extendedData,
  )?
  onRoomStateChanged;

  Function(
    String streamID,
    ZegoPlayerState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  )?
  onPlayerStateUpdate;

  Function(String streamID, ZegoRemoteDeviceState state)?
  onRemoteCameraStateUpdate;

  Function(String streamID, ZegoRemoteDeviceState state)?
  onRemoteMicStateUpdate;
}
