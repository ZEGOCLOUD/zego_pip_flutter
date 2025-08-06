import 'dart:io';

import 'package:floating/floating.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:zego_pip/core/channel/zego_pip_platform_interface.dart';
import 'package:zego_pip/core/private/stream_data.dart';
import 'package:zego_pip/core/defines.dart';

class ZegoPipPrivate {
  bool isInit = false;
  bool isLoginRoom = false;
  String roomID = '';
  bool isRoomLogin = false;

  ValueNotifier<ZegoEngineState> engineStateNotifier = ValueNotifier(
    ZegoEngineState.Stop,
  );
  var streamData = StreamData();
  final floating = Floating();

  var pipConfig = ZegoPIPConfig();

  /// If not null, will initiate create engine and capture events
  /// Otherwise, please create engine externally and call ZegoPip.instance.event after listening to express events
  ZegoPIPExpressConfig? expressConfig;

  /// Express event callbacks
  ZegoPIPExpressEvent? event;
}

/// ZEGO Express Engine related functionality extensions
extension ZegoPipPrivateExpressExtension on ZegoPipPrivate {
  void onEngineStateUpdate(ZegoEngineState state) {
    debugPrint('[ZegoPipPrivate] onEngineStateUpdate: $state');
    engineStateNotifier.value = state;
  }

  void onPlayerStateUpdate(
    String streamID,
    ZegoPlayerState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    debugPrint(
      '[ZegoPipPrivate] onPlayerStateUpdate: streamID=$streamID, state=$state, errorCode=$errorCode',
    );
    streamData.updateStreamState(streamID, state);
  }

  void onRoomStreamUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoStream> streamList,
    Map<String, dynamic> extendedData,
  ) {
    debugPrint(
      '[ZegoPipPrivate] onRoomStreamUpdate: roomID=$roomID, updateType=$updateType, streamCount=${streamList.length}',
    );

    switch (updateType) {
      case ZegoUpdateType.Add:
        debugPrint(
          '[ZegoPipPrivate] Streams added: ${streamList.map((s) => s.streamID).join(', ')}',
        );
        for (var stream in streamList) {
          if (!streamData.isPlayingStream(stream.streamID)) {
            debugPrint(
              '[ZegoPipPrivate] Restarting play stream: ${stream.streamID}',
            );
            streamData.startPlayStream(stream.streamID);
          }
        }
        break;
      case ZegoUpdateType.Delete:
        debugPrint(
          '[ZegoPipPrivate] Streams deleted: ${streamList.map((s) => s.streamID).join(', ')}',
        );
        for (var stream in streamList) {
          if (streamData.isPlayingStream(stream.streamID)) {
            debugPrint(
              '[ZegoPipPrivate] Stopping play stream: ${stream.streamID}',
            );
            streamData.stopPlayStream(stream.streamID);
          }
        }
        break;
    }
  }

  void onRoomStateChanged(
    String roomID,
    ZegoRoomStateChangedReason reason,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    debugPrint(
      '[ZegoPipPrivate] onRoomStateChanged: roomID=$roomID, reason=$reason, errorCode=$errorCode',
    );

    this.roomID = roomID;

    isRoomLogin = reason == ZegoRoomStateChangedReason.Logined;
    debugPrint('[ZegoPipPrivate] Room login status: $isRoomLogin');

    if (reason == ZegoRoomStateChangedReason.LoginFailed ||
        reason == ZegoRoomStateChangedReason.Logout ||
        reason == ZegoRoomStateChangedReason.KickOut) {
      debugPrint('[ZegoPipPrivate] clear room id');
      this.roomID = '';
    }
  }

  void onRemoteCameraStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    debugPrint(
      '[ZegoPipPrivate] onRemoteCameraStateUpdate: streamID=$streamID, state=$state',
    );

    streamData.updateCameraState(
      streamID,
      state == ZegoRemoteDeviceState.Open ||
          state == ZegoRemoteDeviceState.NoAuthorization,
    );
  }

  void onRemoteMicStateUpdate(String streamID, ZegoRemoteDeviceState state) {
    debugPrint(
      '[ZegoPipPrivate] onRemoteMicStateUpdate: streamID=$streamID, state=$state',
    );

    streamData.updateMicrophoneState(
      streamID,
      state == ZegoRemoteDeviceState.Open ||
          state == ZegoRemoteDeviceState.NoAuthorization,
    );
  }

  void onDebugError(int errorCode, String funcName, String info) {
    debugPrint(
      '[ZegoPipPrivate] onDebugError: errorCode=$errorCode, funcName=$funcName, info=$info',
    );

    if (1011003 == errorCode && funcName == "enableCustomVideoRender") {
      debugPrint(
        '[ZegoPipPrivate] Custom video render error detected, attempting to fix...',
      );
      // Description: Failed to set custom capture/preprocessing/rendering
      // Possible cause: Custom capture/preprocessing/rendering not set before engine startup
      // Suggested solution: Please ensure custom capture/preprocessing/rendering is set before engine startup
      _tryEnableCustomVideoRender();
    }
  }

  Future<void> _tryEnableCustomVideoRender() async {
    debugPrint(
      '[ZegoPipPrivate] _tryEnableCustomVideoRender: current engine state=${engineStateNotifier.value}',
    );

    if (ZegoEngineState.Stop == engineStateNotifier.value) {
      if (Platform.isIOS) {
        debugPrint('[ZegoPipPrivate] Enabling custom video render on iOS...');
        // https://doc-zh.zego.im/article/3673
        await ZegoPipPlatform.instance.enableCustomVideoRender(true);
        debugPrint('[ZegoPipPrivate] Custom video render enabled successfully');
      } else {
        debugPrint(
          '[ZegoPipPrivate] Custom video render not needed on this platform',
        );
      }
    } else {
      debugPrint(
        '[ZegoPipPrivate] Engine not stopped, waiting for engine stop...',
      );

      /// not stop
      engineStateNotifier.addListener(
        _onWaitingEngineStopEnableCustomVideoRender,
      );
    }
  }

  void _onWaitingEngineStopEnableCustomVideoRender() {
    debugPrint(
      '[ZegoPipPrivate] _onWaitingEngineStopEnableCustomVideoRender: engine stopped, retrying...',
    );
    engineStateNotifier.removeListener(
      _onWaitingEngineStopEnableCustomVideoRender,
    );

    _tryEnableCustomVideoRender();
  }
}

/// PIP related functionality extensions
extension ZegoPipPrivatePIPExtension on ZegoPipPrivate {
  /// Enable PIP mode
  Future<PiPStatus> enable() async {
    if (Platform.isAndroid) {
      return _enableAndroidPIP();
    } else if (Platform.isIOS) {
      return _enableIOSPIP();
    }
    return PiPStatus.unavailable;
  }

  /// Enable PIP mode when app goes to background
  Future<PiPStatus> enableWhenBackground() async {
    if (Platform.isAndroid) {
      return _enableAndroidPIPWhenBackground();
    } else if (Platform.isIOS) {
      return _enableIOSPIPWhenBackground();
    }
    return PiPStatus.unavailable;
  }

  /// Cancel background PIP mode
  Future<void> cancelBackground() async {
    if (Platform.isAndroid) {
      await _cancelAndroidBackground();
    } else if (Platform.isIOS) {
      await _cancelIOSBackground();
    }
  }

  /// Enable PIP on Android platform
  Future<PiPStatus> _enableAndroidPIP() async {
    final isPipAvailable = await floating.isPipAvailable;
    if (!isPipAvailable) {
      debugPrint('[ZegoPipPrivate] enable, but pip is not available');
      return PiPStatus.unavailable;
    }

    var status = PiPStatus.unavailable;
    try {
      status = await floating.enable(
        ImmediatePiP(
          aspectRatio: Rational(pipConfig.aspectWidth, pipConfig.aspectHeight),
        ),
      );
    } catch (e) {
      debugPrint('[ZegoPipPrivate] enable exception: ${e.toString()}');
    }
    return status;
  }

  /// Enable background PIP on Android platform
  Future<PiPStatus> _enableAndroidPIPWhenBackground() async {
    final isPipAvailable = await floating.isPipAvailable;
    if (!isPipAvailable) {
      debugPrint(
        '[ZegoPipPrivate] enableWhenBackground, but pip is not available',
      );
      return PiPStatus.unavailable;
    }

    try {
      return await floating.enable(
        OnLeavePiP(
          aspectRatio: Rational(pipConfig.aspectWidth, pipConfig.aspectHeight),
        ),
      );
    } catch (e) {
      debugPrint(
        '[ZegoPipPrivate] enableWhenBackground exception: ${e.toString()}',
      );
      return PiPStatus.disabled;
    }
  }

  /// Cancel background PIP on Android platform
  Future<void> _cancelAndroidBackground() async {
    try {
      await floating.cancelOnLeavePiP();
    } catch (e) {
      debugPrint(
        '[ZegoPipPrivate] cancelOnLeavePiP exception: ${e.toString()}',
      );
    }
  }

  /// Enable PIP on iOS platform
  Future<PiPStatus> _enableIOSPIP() async {
    try {
      await ZegoPipPlatform.instance.enableIOSPIP(
        'default_stream', // Need to pass actual streamID here
        aspectWidth: pipConfig.aspectWidth,
        aspectHeight: pipConfig.aspectHeight,
      );
      return PiPStatus.enabled;
    } catch (e) {
      debugPrint('[ZegoPipPrivate] enableIOSPIP exception: ${e.toString()}');
      return PiPStatus.unavailable;
    }
  }

  /// Enable background PIP on iOS platform
  Future<PiPStatus> _enableIOSPIPWhenBackground() async {
    try {
      await ZegoPipPlatform.instance.enableIOSPIPAuto(
        true,
        aspectWidth: pipConfig.aspectWidth,
        aspectHeight: pipConfig.aspectHeight,
      );
      return PiPStatus.enabled;
    } catch (e) {
      debugPrint(
        '[ZegoPipPrivate] enableIOSPIPWhenBackground exception: ${e.toString()}',
      );
      return PiPStatus.unavailable;
    }
  }

  /// Cancel background PIP on iOS platform
  Future<void> _cancelIOSBackground() async {
    try {
      await ZegoPipPlatform.instance.stopIOSPIP();
    } catch (e) {
      debugPrint(
        '[ZegoPipPrivate] cancelIOSBackground exception: ${e.toString()}',
      );
    }
  }
}
