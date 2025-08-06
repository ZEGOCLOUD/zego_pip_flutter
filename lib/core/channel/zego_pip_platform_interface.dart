import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:zego_pip/core/channel/zego_pip_method_channel.dart';

/// Platform interface for PIP functionality.
///
/// This abstract class defines the interface for platform-specific PIP implementations.
/// It provides a common API that can be implemented differently for iOS and Android.
///
/// The default implementation is [MethodChannelZegoPip] which uses platform channels
/// to communicate with native code.
abstract class ZegoPipPlatform extends PlatformInterface {
  /// Constructs a ZegoPipPlatform.
  ZegoPipPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZegoPipPlatform _instance = MethodChannelZegoPip();

  /// The default instance of [ZegoPipPlatform] to use.
  ///
  /// Defaults to [MethodChannelZegoPip].
  static ZegoPipPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZegoPipPlatform] when
  /// they register themselves.
  static set instance(ZegoPipPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Start playing a video stream in picture-in-picture mode.
  ///
  /// This method initiates the playback of a specific video stream in PIP mode.
  /// The stream will be displayed in a floating window that can be moved around the screen.
  ///
  /// [streamID] - The unique identifier of the stream to play in PIP mode.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> startPlayingStreamInPIP(String streamID) {
    throw UnimplementedError(
      'startPlayingStreamInPIP() has not been implemented.',
    );
  }

  /// Stop playing a video stream in picture-in-picture mode.
  ///
  /// This method stops the playback of a specific video stream in PIP mode.
  /// The floating window will be closed and the stream will stop playing.
  ///
  /// [streamID] - The unique identifier of the stream to stop playing in PIP mode.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> stopPlayingStreamInPIP(String streamID) {
    throw UnimplementedError(
      'stopPlayingStreamInPIP() has not been implemented.',
    );
  }

  /// Update the playing stream view in picture-in-picture mode.
  ///
  /// This method updates the video view for a stream that is currently playing in PIP mode.
  /// It can be used to change the view mode or update the view ID for the stream.
  ///
  /// [viewID] - The ID of the view to update.
  /// [streamID] - The unique identifier of the stream.
  /// [viewMode] - The view mode to apply to the stream.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> updatePlayingStreamViewInPIP(
    int viewID,
    String streamID,
    int viewMode,
  ) {
    throw UnimplementedError(
      'updatePlayingStreamViewInPIP() has not been implemented.',
    );
  }

  /// Enable or disable custom video rendering.
  ///
  /// This method controls whether the plugin uses custom video rendering
  /// instead of the default ZEGO Express engine rendering.
  ///
  /// [isEnabled] - Whether to enable custom video rendering.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> enableCustomVideoRender(bool isEnabled) {
    throw UnimplementedError(
      'enableCustomVideoRender() has not been implemented.',
    );
  }

  /// Enable or disable hardware decoder (iOS only).
  ///
  /// This method controls whether the plugin uses hardware acceleration
  /// for video decoding on iOS devices.
  ///
  /// [isEnabled] - Whether to enable hardware decoding.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> enableHardwareDecoder(bool isEnabled) {
    throw UnimplementedError(
      'enableHardwareDecoder() has not been implemented.',
    );
  }

  /// Stop iOS picture-in-picture mode (iOS only).
  ///
  /// This method stops the current PIP mode on iOS devices.
  /// The floating video window will be closed and the app will return to normal mode.
  ///
  /// Returns `true` if PIP was successfully stopped, `false` otherwise.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<bool> stopIOSPIP() {
    throw UnimplementedError('stopIOSPIP() has not been implemented.');
  }

  /// Check if iOS is in picture-in-picture mode (iOS only).
  ///
  /// This method checks whether the app is currently in PIP mode on iOS devices.
  ///
  /// Returns `true` if the app is in PIP mode, `false` otherwise.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<bool> isIOSInPIP() {
    throw UnimplementedError('isIOSInPIP() has not been implemented.');
  }

  /// Enable iOS picture-in-picture mode (iOS only).
  ///
  /// This method enables PIP mode on iOS devices for a specific video stream.
  /// The video will be displayed in a floating window that can be moved around the screen.
  ///
  /// [streamID] - The unique identifier of the stream to display in PIP mode.
  /// [aspectWidth] - The width aspect ratio for the PIP window (default: 9).
  /// [aspectHeight] - The height aspect ratio for the PIP window (default: 16).
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> enableIOSPIP(
    String streamID, {
    int aspectWidth = 9,
    int aspectHeight = 16,
  }) {
    throw UnimplementedError('enableIOSPIP() has not been implemented.');
  }

  /// Update iOS picture-in-picture source stream (iOS only).
  ///
  /// This method updates the source stream for the current PIP mode on iOS devices.
  /// It allows switching between different video streams while maintaining PIP mode.
  ///
  /// [streamID] - The unique identifier of the new stream to display in PIP mode.
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> updateIOSPIPSource(String streamID) {
    throw UnimplementedError('updateIOSPIPSource() has not been implemented.');
  }

  /// Enable iOS auto picture-in-picture mode (iOS only).
  ///
  /// This method enables automatic PIP mode on iOS devices.
  /// When enabled, the app will automatically enter PIP mode when the user switches to another app.
  ///
  /// [isEnabled] - Whether to enable automatic PIP mode.
  /// [aspectWidth] - The width aspect ratio for the PIP window (default: 9).
  /// [aspectHeight] - The height aspect ratio for the PIP window (default: 16).
  ///
  /// Throws:
  /// - [UnimplementedError] if the platform implementation is not available
  Future<void> enableIOSPIPAuto(
    bool isEnabled, {
    int aspectWidth = 9,
    int aspectHeight = 16,
  }) {
    throw UnimplementedError('enableIOSPIPAuto() has not been implemented.');
  }
}
