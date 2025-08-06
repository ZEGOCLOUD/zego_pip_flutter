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
