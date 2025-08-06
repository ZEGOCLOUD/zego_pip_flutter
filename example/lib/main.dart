import 'package:flutter/material.dart';
import 'dart:async';

import 'package:zego_pip/zego_pip.dart';

/// player demo
/// create the express engine by zego_pip

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ZegoPIP().init(
    /// zego_pip internally creates the express engine, listens for events, and logs in to the room
    expressConfig: ZegoPIPExpressConfig(
      create: ZegoPIPExpressCreateConfig(
        // Please fill in your own app id
        appID: ,
        // Please fill in your own app sign
        appSign: ,
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
