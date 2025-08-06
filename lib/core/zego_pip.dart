import 'dart:io';

import 'package:floating/floating.dart';
import 'package:flutter/cupertino.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_pip/core/private/zego_pip_private.dart';

import 'package:zego_pip/core/defines.dart';
import 'package:zego_pip/core/channel/zego_pip_platform_interface.dart';

/// Main class for managing Picture-in-Picture (PIP) functionality.
///
/// This class provides a singleton instance that handles all PIP-related operations
/// including initialization, enabling/disabling PIP mode, and managing background PIP.
///
/// Example usage:
/// ```dart
/// // Initialize PIP
/// await ZegoPIP().init(
///   expressConfig: ZegoPIPExpressConfig(
///     create: ZegoPIPExpressCreateConfig(
///       appID: 1234567890,
///       appSign: 'your_app_sign',
///     ),
///     room: ZegoPIPExpressRoomConfig(
///       roomID: 'test_room_id',
///       userID: 'test_user_id',
///       userName: 'test_user_name',
///     ),
///   ),
/// );
///
/// // Enable PIP mode
/// final status = await ZegoPIP().enable();
/// ```
///
/// {@category APIs}
///
class ZegoPIP {
  factory ZegoPIP() {
    return shared;
  }

  static final ZegoPIP shared = ZegoPIP._internal();

  /// Current version of the PIP plugin.
  ///
  /// Returns the version string of the zego_pip plugin.
  String get version => "0.1";

  /// Initialize the PIP functionality.
  ///
  /// This method must be called before using any other PIP features.
  /// It sets up the ZEGO Express engine and configures the PIP system.
  ///
  /// [config] - PIP configuration including aspect ratio and other settings.
  /// [expressConfig] - ZEGO Express engine configuration. If null, it means the client has already created the express engine;
  ///                   If not null, zego_pip will internally create the express engine and register related express events.
  ///                   The expressConfig contains create, room, and event configurations.
  ///                   Please ensure that `enablePlatformView` is set to true
  ///
  /// Returns `true` if initialization is successful, `false` otherwise.
  ///
  /// Throws:
  /// - [PlatformException] if platform-specific initialization fails
  Future<bool> init({
    ZegoPIPConfig config = const ZegoPIPConfig(),

    /// If null, it means the client has already created the express engine;
    /// If not null, zego_pip will internally create the express engine and register related express events.
    ZegoPIPExpressConfig? expressConfig,
  }) async {
    if (private.isInit) {
      return true;
    }

    private.isInit = true;
    private.pipConfig = config;
    private.expressConfig = expressConfig;
    private.event = expressConfig?.event ?? ZegoPIPExpressEvent();

    if (null != expressConfig?.create) {
      ZegoExpressEngine.onEngineStateUpdate = private.onEngineStateUpdate;
      ZegoExpressEngine.onDebugError = private.onDebugError;
      ZegoExpressEngine.onRoomStreamUpdate = private.onRoomStreamUpdate;
      ZegoExpressEngine.onRoomStateChanged = private.onRoomStateChanged;
      ZegoExpressEngine.onPlayerStateUpdate = private.onPlayerStateUpdate;
      ZegoExpressEngine.onRemoteCameraStateUpdate =
          private.onRemoteCameraStateUpdate;
      ZegoExpressEngine.onRemoteMicStateUpdate = private.onRemoteMicStateUpdate;

      await ZegoExpressEngine.createEngineWithProfile(
        ZegoEngineProfile(
          expressConfig!.create!.appID,
          expressConfig.create!.scenario,
          appSign: expressConfig.create!.appSign,
          enablePlatformView: true,
        ),
      );
    } else {
      /// External creation is responsible, assume it's already started
      private.engineStateNotifier.value = ZegoEngineState.Start;

      private.event?.onEngineStateUpdate = private.onEngineStateUpdate;
      private.event?.onDebugError = private.onDebugError;
      private.event?.onRoomStreamUpdate = private.onRoomStreamUpdate;
      private.event?.onRoomStateChanged = private.onRoomStateChanged;
      private.event?.onPlayerStateUpdate = private.onPlayerStateUpdate;
      private.event?.onRemoteCameraStateUpdate =
          private.onRemoteCameraStateUpdate;
      private.event?.onRemoteMicStateUpdate = private.onRemoteMicStateUpdate;
    }

    if (Platform.isIOS) {
      /// For detailed information, refer to https://doc-zh.zego.im/article/3673
      await ZegoPipPlatform.instance.enableCustomVideoRender(true);
    }

    /// Enable PIP when app goes to background by default
    final status = await private.enableWhenBackground();
    debugPrint('pip status:$status');

    if (expressConfig?.room?.canLoginRoom ?? false) {
      final result = await ZegoExpressEngine.instance.loginRoom(
        expressConfig!.room!.roomID,
        ZegoUser(expressConfig.room!.userID, expressConfig.room!.userName),
        config: ZegoRoomConfig(0, true, ''),
      );
      if (0 != result.errorCode) {
        return false;
      }

      private.isLoginRoom = true;
    }

    return true;
  }

  /// Deinitialize the PIP functionality.
  ///
  /// This method cleans up all resources and stops the PIP system.
  /// It should be called when the app is shutting down or when PIP is no longer needed.
  ///
  /// This method will:
  /// - Logout from the room if logged in
  /// - Destroy the ZEGO Express engine if expressConfig is not null on [init]
  /// - Clean up all PIP-related resources
  Future<void> uninit() async {
    if (!private.isInit) {
      return;
    }

    private.isInit = false;
    private.pipConfig = ZegoPIPConfig();

    if (private.isLoginRoom) {
      private.roomID = '';
      private.isLoginRoom = false;
      private.isRoomLogin = false;
      await ZegoExpressEngine.instance.logoutRoom();
    }

    if (null != private.expressConfig) {
      await ZegoExpressEngine.destroyEngine();
    }
    private.expressConfig = null;
  }

  /// Actively enable PIP mode.
  ///
  /// This method enables Picture-in-Picture mode for the current video stream.
  /// The user can then minimize the app and continue watching the video in a floating window.
  ///
  /// Returns the current [PiPStatus] indicating whether PIP was successfully enabled.
  ///
  /// Note: This method only works on supported platforms (iOS 15.0+ and Android 8.0+).
  Future<PiPStatus> enable() async {
    return await private.enable();
  }

  /// Enable PIP mode when the app goes to background.
  ///
  /// This method configures the system to automatically enter PIP mode
  /// when the user switches to another app or minimizes the current app.
  ///
  /// Returns the current [PiPStatus] indicating whether background PIP was successfully enabled.
  ///
  /// Note: This feature may not be available on all platforms or devices.
  Future<PiPStatus> enableWhenBackground() async {
    return await private.enableWhenBackground();
  }

  /// Actively cancel background PIP mode.
  ///
  /// This method disables the automatic PIP mode that was enabled by [enableWhenBackground].
  /// After calling this method, the app will no longer automatically enter PIP mode when going to background.
  ///
  /// Note: This does not affect manually enabled PIP mode via [enable].
  Future<void> cancelBackground() async {
    await private.cancelBackground();
  }

  ZegoPIP._internal();

  var private = ZegoPipPrivate();
}
