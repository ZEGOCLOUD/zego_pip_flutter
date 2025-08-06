// Dart imports:
import 'dart:core';
import 'dart:io';

// Flutter imports:
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';

import 'package:zego_pip/core/zego_pip.dart';
import 'package:zego_pip/core/private/defines.dart';

/// A Flutter widget that displays video streams with automatic PIP support.
///
/// This widget automatically handles video rendering and PIP mode switching.
/// It can be used as a drop-in replacement for regular video views in your app.
///
/// The widget hierarchy (from bottom to top) is:
/// 1. background view
/// 2. video view
/// 3. foreground view
///
/// Example usage:
/// ```dart
/// ZegoPIPVideoView(
///   streamID: 'your_stream_id',
///   loadingBuilder: (context) => CircularProgressIndicator(),
///   userViewNullBuilder: (context) => Text('No video available'),
/// )
/// ```
class ZegoPIPVideoView extends StatefulWidget {
  const ZegoPIPVideoView({
    super.key,
    required this.streamID,
    this.loadingBuilder,
    this.userViewNullBuilder,
  });

  /// The unique identifier for the video stream to display.
  ///
  /// This streamID should match the one used when publishing the stream.
  final String streamID;

  /// Optional builder for the loading state.
  ///
  /// If provided, this widget will be shown while the video is loading.
  /// If null, a default loading indicator will be used.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Optional builder for when the user view is null.
  ///
  /// If provided, this widget will be shown when there's no video content to display.
  /// If null, a default error message will be shown.
  final Widget Function(BuildContext context)? userViewNullBuilder;

  @override
  State<ZegoPIPVideoView> createState() => _ZegoPIPVideoViewState();
}

class _ZegoPIPVideoViewState extends State<ZegoPIPVideoView> {
  ZegoStreamInfo? streamInfo;

  @override
  void initState() {
    super.initState();

    ZegoPIP().private.streamData.startPlayStream(widget.streamID);
  }

  @override
  void dispose() {
    ZegoPIP().private.streamData.stopPlayStream(streamInfo?.streamID ?? '');

    super.dispose();
  }

  /// Default loading builder
  Widget _defaultLoadingBuilder(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Default user view null builder
  Widget _defaultUserViewNullBuilder(BuildContext context) {
    return Text(
      'userView is null!',
      style: TextStyle(
        color: Colors.red[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return PiPSwitcher(
        floating: ZegoPIP().private.floating,
        childWhenDisabled: video(),
        childWhenEnabled: video(),
      );
    }

    return video();
  }

  Widget video() {
    return Center(
      child: ZegoPIP().private.isInit
          ? ValueListenableBuilder(
              valueListenable:
                  ZegoPIP().private.streamData.playingStreamListNotifier,
              builder: (context, layingStreamList, _) {
                final index = layingStreamList.indexWhere(
                  (e) => e.streamID == widget.streamID,
                );
                if (-1 == index) {
                  return widget.loadingBuilder?.call(context) ??
                      _defaultLoadingBuilder(context);
                }

                streamInfo = layingStreamList[index];

                return ValueListenableBuilder(
                  valueListenable: streamInfo!.camera,
                  builder: (context, isCameraOn, _) {
                    return isCameraOn
                        ? ValueListenableBuilder<Widget?>(
                            valueListenable: streamInfo!.viewNotifier,
                            builder: (context, userView, _) {
                              return userView ??
                                  (widget.userViewNullBuilder?.call(context) ??
                                      _defaultUserViewNullBuilder(context));
                            },
                          )
                        : Icon(Icons.videocam_off);
                  },
                );
              },
            )
          : Text(
              'ZegoPIP not init!',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}
