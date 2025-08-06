import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// Information class for managing video stream data.
///
/// This class contains all the information needed to manage a video stream,
/// including stream ID, device states, player state, and view information.
///
/// Example usage:
/// ```dart
/// ZegoStreamInfo streamInfo = ZegoStreamInfo.empty();
/// streamInfo.streamID = 'your_stream_id';
/// streamInfo.camera.value = true;
/// ```
class ZegoStreamInfo {
  /// Unique identifier for the video stream.
  ///
  /// This should match the stream ID used when publishing the stream.
  String streamID = '';

  /// Camera state for the stream.
  ///
  /// Default enabled, will receive event notification if disabled.
  /// Use this to track whether the camera is active for this stream.
  ValueNotifier<bool> camera = ValueNotifier<bool>(true);

  /// Microphone state for the stream.
  ///
  /// Default enabled, will receive event notification if disabled.
  /// Use this to track whether the microphone is active for this stream.
  ValueNotifier<bool> microphone = ValueNotifier<bool>(true);

  /// Current player state for the stream.
  ///
  /// This tracks whether the stream is currently playing, stopped, or in an error state.
  ValueNotifier<ZegoPlayerState> stateNotifier = ValueNotifier(
    ZegoPlayerState.NoPlay,
  );

  /// View ID for the stream's video view.
  ///
  /// This is used internally to manage the video rendering view.
  ValueNotifier<int?> viewIDNotifier = ValueNotifier<int?>(-1);

  /// Widget for the stream's video view.
  ///
  /// This contains the actual video rendering widget.
  ValueNotifier<Widget?> viewNotifier = ValueNotifier<Widget?>(null);

  /// Size of the video view.
  ///
  /// This tracks the current dimensions of the video view.
  ValueNotifier<Size> viewSizeNotifier = ValueNotifier<Size>(
    const Size(360, 640),
  );

  /// Clear all stream information and reset to default values.
  ///
  /// This method resets all notifiers to their initial state.
  void clear() {
    camera.value = false;
    microphone.value = false;
    stateNotifier.value = ZegoPlayerState.NoPlay;
    viewIDNotifier.value = -1;
    viewNotifier.value = null;
    viewSizeNotifier.value = const Size(360, 640);
  }

  /// Create an empty ZegoStreamInfo instance.
  ZegoStreamInfo.empty();
}
