import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:zego_pip/core/channel/zego_pip_platform_interface.dart';
import 'package:zego_pip/core/private/defines.dart';

class StreamData {
  final ValueNotifier<List<ZegoStreamInfo>> playingStreamListNotifier =
      ValueNotifier<List<ZegoStreamInfo>>([]);

  bool isPlayingStream(String streamID) {
    final index = playingStreamListNotifier.value.indexWhere(
      (e) => e.streamID == streamID,
    );
    if (-1 == index) {
      return false;
    }

    return playingStreamListNotifier.value[index].stateNotifier.value !=
        ZegoPlayerState.NoPlay;
  }

  Future<ZegoStreamInfo> startPlayStream(String streamID) async {
    final index = playingStreamListNotifier.value.indexWhere(
      (e) => e.streamID == streamID,
    );
    if (-1 != index &&
        playingStreamListNotifier.value[index].stateNotifier.value !=
            ZegoPlayerState.NoPlay) {
      await stopPlayStream(streamID);
    }

    var streamInfo = ZegoStreamInfo.empty();
    streamInfo.streamID = streamID;
    final newList = List<ZegoStreamInfo>.from(playingStreamListNotifier.value);
    newList.add(streamInfo);
    playingStreamListNotifier.value = newList;

    await _startPlayStream(streamInfo);
    await _updateCanvas(streamInfo);

    return streamInfo;
  }

  Future<void> stopPlayStream(String streamID) async {
    final index = playingStreamListNotifier.value.indexWhere(
      (e) => e.streamID == streamID,
    );
    if (-1 == index) {
      return;
    }

    final streamInfo = playingStreamListNotifier.value[index];
    await _stopPlayStream(streamInfo);
    final newList = List<ZegoStreamInfo>.from(playingStreamListNotifier.value);
    newList.removeWhere((e) => e.streamID == streamID);
    playingStreamListNotifier.value = newList;

    streamInfo.clear();
  }

  void updateStreamState(String streamID, ZegoPlayerState playerState) {
    final index = playingStreamListNotifier.value.indexWhere(
      (e) => e.streamID == streamID,
    );
    if (-1 == index) {
      return;
    }

    final streamInfo = playingStreamListNotifier.value[index];
    streamInfo.stateNotifier.value = playerState;
  }

  void updateCameraState(String streamID, bool state) {
    final index = playingStreamListNotifier.value.indexWhere(
      (e) => e.streamID == streamID,
    );
    if (-1 == index) {
      return;
    }

    final streamInfo = playingStreamListNotifier.value[index];
    streamInfo.camera.value = state;
  }

  void updateMicrophoneState(String streamID, bool state) {
    final index = playingStreamListNotifier.value.indexWhere(
      (e) => e.streamID == streamID,
    );
    if (-1 == index) {
      return;
    }

    final streamInfo = playingStreamListNotifier.value[index];
    streamInfo.microphone.value = state;
  }

  Future<void> _startPlayStream(ZegoStreamInfo streamInfo) async {
    if (Platform.isIOS) {
      ZegoPipPlatform.instance.startPlayingStreamInPIP(streamInfo.streamID);
    } else {
      await ZegoExpressEngine.instance.startPlayingStream(
        streamInfo.streamID,
        canvas: null,
      );
    }
  }

  Future<void> _stopPlayStream(ZegoStreamInfo streamInfo) async {
    if (streamInfo.streamID.isEmpty) {
      return;
    }

    if (Platform.isIOS) {
      ZegoPipPlatform.instance.stopPlayingStreamInPIP(streamInfo.streamID);
    } else {
      await ZegoExpressEngine.instance.stopPlayingStream(streamInfo.streamID);
    }
  }

  Future<void> _updateCanvas(ZegoStreamInfo streamInfo) async {
    await ZegoExpressEngine.instance
        .createCanvasView((int viewID) async {
          streamInfo.viewIDNotifier.value = viewID;

          final canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFit);
          if (Platform.isIOS) {
            ZegoPipPlatform.instance.updatePlayingStreamViewInPIP(
              viewID,
              streamInfo.streamID,
              ZegoViewMode.AspectFit.index,
            );
          } else {
            await ZegoExpressEngine.instance.updatePlayingCanvas(
              streamInfo.streamID,
              canvas,
            );
          }
        })
        .then((widget) {
          streamInfo.viewNotifier.value = widget;
        });
  }
}
