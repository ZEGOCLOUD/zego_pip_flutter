import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_pip/zego_pip.dart';

/// publisher demo

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();
  await Permission.microphone.request();

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
    MaterialApp(
      home: Scaffold(
        /// Please fill in your own stream id
        body: Center(
          child: ValueListenableBuilder(
            valueListenable: ZegoExpressManager().isPublishingNotifier,
            builder: (context, isPublishing, _) {
              return isPublishing
                  ? ElevatedButton(
                      onPressed: () {
                        ZegoExpressManager().stopPublishing();
                      },
                      child: Text("Stop Publish"),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        ZegoExpressManager().publish();
                      },
                      child: Text("Publish Stream"),
                    );
            },
          ),
        ),
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

  ValueNotifier<bool> isPublishingNotifier = ValueNotifier(false);

  Future<void> init() async {
    ZegoExpressEngine.onPublisherStateUpdate = onPublisherStateUpdate;

    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(
        // Please fill in your own app id
        ,
        ZegoScenario.Default,
        // Please fill in your own app sign
        appSign: ,
      ),
    );
  }

  Future<bool> loginRoom() async {
    final result = await ZegoExpressEngine.instance.loginRoom(
      /// Please fill in your own room id
      'test_room_id',
      ZegoUser(
        /// Please fill in your own room login user info
        'test_push_user_id',
        'test_push_user_name',
      ),
      config: ZegoRoomConfig(0, true, ''),
    );

    return 0 == result.errorCode;
  }

  Future<void> publish() async {
    await ZegoExpressEngine.instance.enableCamera(true);
    await ZegoExpressEngine.instance.muteMicrophone(false);

    await ZegoExpressEngine.instance.startPublishingStream(
      'test_stream_id',
    );
  }

  Future<void> stopPublishing() async {
    await ZegoExpressEngine.instance.stopPublishingStream();
  }

  void onPublisherStateUpdate(
    String streamID,
    ZegoPublisherState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    isPublishingNotifier.value = state != ZegoPublisherState.NoPublish;
  }
}
