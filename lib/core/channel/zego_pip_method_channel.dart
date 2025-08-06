import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:zego_pip/core/channel/zego_pip_platform_interface.dart';

/// An implementation of [ZegoPipPlatform] that uses method channels.
class MethodChannelZegoPip extends ZegoPipPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zego_pip');

  @override
  Future<void> startPlayingStreamInPIP(String streamID) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[ZegoPipMethodChannel] startPlayingStreamInPIP not support in Android',
      );
      return;
    }

    debugPrint(
      '[ZegoPipMethodChannel] startPlayingStreamInPIP: streamID=$streamID',
    );

    try {
      await methodChannel.invokeMethod('startPlayingStreamInPIP', {
        'stream_id': streamID,
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[ZegoPipMethodChannel] Failed to startPlayingStreamInPIP: $e',
      );
    }
  }

  @override
  Future<void> stopPlayingStreamInPIP(String streamID) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[ZegoPipMethodChannel] stopPlayingStreamInPIP not support in Android',
      );
      return;
    }

    debugPrint(
      '[ZegoPipMethodChannel] stopPlayingStreamInPIP: streamID=$streamID',
    );

    try {
      await methodChannel.invokeMethod('stopPlayingStreamInPIP', {
        'stream_id': streamID,
      });
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to stopPlayingStreamInPIP: $e');
    }
  }

  @override
  Future<void> updatePlayingStreamViewInPIP(
    int viewID,
    String streamID,
    int viewMode,
  ) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[ZegoPipMethodChannel] updatePlayingStreamViewInPIP not support in Android',
      );
      return;
    }

    debugPrint(
      '[ZegoPipMethodChannel] updatePlayingStreamViewInPIP: viewID=$viewID, streamID=$streamID, viewMode=$viewMode',
    );

    try {
      await methodChannel.invokeMethod('updatePlayingStreamViewInPIP', {
        'view_id': viewID,
        'stream_id': streamID,
        'view_mode': viewMode,
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[ZegoPipMethodChannel] Failed to updatePlayingStreamViewInPIP: $e',
      );
    }
  }

  @override
  Future<void> enableCustomVideoRender(bool isEnabled) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[ZegoPipMethodChannel] enableCustomVideoRender not support in Android',
      );
      return;
    }

    debugPrint(
      '[ZegoPipMethodChannel] enableCustomVideoRender: enabled=$isEnabled',
    );

    try {
      await methodChannel.invokeMethod('enableCustomVideoRender', {
        'enabled': isEnabled,
      });
    } on PlatformException catch (e) {
      debugPrint(
        '[ZegoPipMethodChannel] Failed to enableCustomVideoRender: $e',
      );
    }
  }

  @override
  Future<void> enableHardwareDecoder(bool isEnabled) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[ZegoPipMethodChannel] enableHardwareDecoder not support in Android',
      );
      return;
    }

    debugPrint(
      '[ZegoPipMethodChannel] enableHardwareDecoder: enabled=$isEnabled',
    );

    try {
      await methodChannel.invokeMethod('enableHardwareDecoder', {
        'enabled': isEnabled,
      });
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to enableHardwareDecoder: $e');
    }
  }

  @override
  Future<bool> stopIOSPIP() async {
    if (Platform.isAndroid) {
      debugPrint('[ZegoPipMethodChannel] stopIOSPIP not support in Android');
      return false;
    }

    // Check iOS system version, PIP requires iOS 15+
    final systemVersion = await _getIOSSystemVersion();
    if (systemVersion < 15) {
      debugPrint(
        '[ZegoPipMethodChannel] stopIOSPIP not support smaller than iOS 15',
      );
      return false;
    }

    debugPrint('[ZegoPipMethodChannel] stopIOSPIP');

    bool result = false;
    try {
      result = await methodChannel.invokeMethod('stopPIP', {}) ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to stopIOSPIP: $e');
    }

    return result;
  }

  @override
  Future<bool> isIOSInPIP() async {
    if (Platform.isAndroid) {
      debugPrint('[ZegoPipMethodChannel] isIOSInPIP not support in Android');
      return false;
    }

    // Check iOS system version, PIP requires iOS 15+
    final systemVersion = await _getIOSSystemVersion();
    if (systemVersion < 15) {
      debugPrint(
        '[ZegoPipMethodChannel] isIOSInPIP not support smaller than iOS 15',
      );
      return false;
    }

    debugPrint('[ZegoPipMethodChannel] isIOSInPIP');

    bool isInPIP = false;
    try {
      isInPIP = await methodChannel.invokeMethod('isInPIP', {}) ?? false;
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to isIOSInPIP: $e');
    }

    return isInPIP;
  }

  @override
  Future<void> enableIOSPIP(
    String streamID, {
    int aspectWidth = 9,
    int aspectHeight = 16,
  }) async {
    if (Platform.isAndroid) {
      debugPrint('[ZegoPipMethodChannel] enableIOSPIP not support in Android');
      return;
    }

    // Check iOS system version, PIP requires iOS 15+
    final systemVersion = await _getIOSSystemVersion();
    if (systemVersion < 15) {
      debugPrint(
        '[ZegoPipMethodChannel] enableIOSPIP not support smaller than iOS 15',
      );
      return;
    }

    debugPrint(
      '[ZegoPipMethodChannel] enableIOSPIP: streamID=$streamID, aspectWidth=$aspectWidth, aspectHeight=$aspectHeight',
    );

    try {
      await methodChannel.invokeMethod('enablePIP', {
        'stream_id': streamID,
        'aspect_width': aspectWidth,
        'aspect_height': aspectHeight,
      });
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to enableIOSPIP: $e');
    }
  }

  @override
  Future<void> updateIOSPIPSource(String streamID) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[ZegoPipMethodChannel] updateIOSPIPSource not support in Android',
      );
      return;
    }

    // Check iOS system version, PIP requires iOS 15+
    final systemVersion = await _getIOSSystemVersion();
    if (systemVersion < 15) {
      debugPrint(
        '[ZegoPipMethodChannel] updateIOSPIPSource not support smaller than iOS 15',
      );
      return;
    }

    debugPrint('[ZegoPipMethodChannel] updateIOSPIPSource: streamID=$streamID');

    try {
      await methodChannel.invokeMethod('updatePIPSource', {
        'stream_id': streamID,
      });
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to updateIOSPIPSource: $e');
    }
  }

  @override
  Future<void> enableIOSPIPAuto(
    bool isEnabled, {
    int aspectWidth = 9,
    int aspectHeight = 16,
  }) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[ZegoPipMethodChannel] enableIOSPIPAuto not support in Android',
      );
      return;
    }

    // Check iOS system version, PIP requires iOS 15+
    final systemVersion = await _getIOSSystemVersion();
    if (systemVersion < 15) {
      debugPrint(
        '[ZegoPipMethodChannel] enableIOSPIPAuto not support smaller than iOS 15',
      );
      return;
    }

    debugPrint(
      '[ZegoPipMethodChannel] enableIOSPIPAuto: enabled=$isEnabled, aspectWidth=$aspectWidth, aspectHeight=$aspectHeight',
    );

    try {
      await methodChannel.invokeMethod('enableAutoPIP', {
        'enabled': isEnabled,
        'aspect_width': aspectWidth,
        'aspect_height': aspectHeight,
      });
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to enableIOSPIPAuto: $e');
    }
  }

  /// Get iOS system version number
  Future<int> _getIOSSystemVersion() async {
    if (!Platform.isIOS) return 0;

    try {
      final version =
          await methodChannel.invokeMethod<String>('getSystemVersion') ?? '0';
      final majorVersion = int.tryParse(version.split('.').first) ?? 0;
      return majorVersion;
    } on PlatformException catch (e) {
      debugPrint('[ZegoPipMethodChannel] Failed to get system version: $e');
      return 0;
    }
  }
}
