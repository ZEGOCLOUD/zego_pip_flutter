/**
 * @file ZegoPipPlugin.m
 * @brief Implementation file for Zego PIP Flutter plugin
 * @author ZEGO Team
 * @date 2024
 * 
 * This file implements the ZegoPipPlugin class, which serves as a bridge between Flutter and iOS native PIP functionality.
 * Responsible for handling method calls from Flutter and forwarding them to PipManager.
 */

#import "ZegoPipPlugin.h"
#import <UIKit/UIKit.h>
#import <zego_express_engine/ZegoPlatformViewFactory.h>
#import <zego_express_engine/ZegoPlatformView.h>
#import "pip/PipManager.h"

@implementation ZegoPipPlugin

/**
 * @brief Register Flutter plugin
 * @param registrar Flutter plugin registrar
 * 
 * This method is called when the Flutter engine starts, used for:
 * 1. Creating method channels
 * 2. Registering plugin instances
 * 3. Initializing audio sessions
 */
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  // Create method channel named "zego_pip"
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"zego_pip"
            binaryMessenger:[registrar messenger]];
  
  // Create plugin instance and register as method call delegate
  ZegoPipPlugin* instance = [[ZegoPipPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  
  // Set up audio session for PIP functionality
  [[PipManager sharedInstance] setUpAudioSession];
}

/**
 * @brief Handle method calls from Flutter
 * @param call Method call object containing method name and parameters
 * @param result Result callback for returning results to Flutter
 * 
 * This method handles all method calls from Flutter, including:
 * - System version retrieval
 * - PIP functionality control
 * - Video stream playback control
 * - Hardware decoding and custom rendering settings
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  // Get system version information
  if ([@"getSystemVersion" isEqualToString:call.method]) {
    result([[UIDevice currentDevice] systemVersion]);
  } 
  // Start playing stream in PIP
  else if ([@"startPlayingStreamInPIP" isEqualToString:call.method]) {
    NSDictionary *arguments = call.arguments;
    NSString *streamID = arguments[@"stream_id"];
    
    NSLog(@"[ZegoPipPlugin] startPlayingStreamInPIP, streamID: %@", streamID);
    [self startPlayingStreamInPIP:streamID];
    
    result(nil);
  } 
  // Stop playing stream in PIP
  else if ([@"stopPlayingStreamInPIP" isEqualToString:call.method]) {
    NSDictionary *arguments = call.arguments;
    NSString *streamID = arguments[@"stream_id"];
    
    NSLog(@"[ZegoPipPlugin] stopPlayingStreamInPIP, streamID: %@", streamID);
    [self stopPlayingStreamInPIP:streamID];
    
    result(nil);
  } 
  // Update playing stream view in PIP
  else if ([@"updatePlayingStreamViewInPIP" isEqualToString:call.method]) {
    NSDictionary *arguments = call.arguments;
    
    NSNumber *viewID = arguments[@"view_id"];
    NSString *streamID = arguments[@"stream_id"];
    NSNumber *viewMode = arguments[@"view_mode"];
    
    NSLog(@"[ZegoPipPlugin] updatePlayingStreamViewInPIP, viewID: %@, streamID: %@, viewMode: %@", viewID, streamID, viewMode);
    [self updatePlayingStreamViewInPIP:viewID streamID:streamID viewMode:viewMode];
    
    result(nil);
  } 
  // Enable/disable custom video rendering
  else if ([@"enableCustomVideoRender" isEqualToString:call.method]) {
    NSDictionary *arguments = call.arguments;
    
    NSNumber *enabledValue = arguments[@"enabled"];
    BOOL isEnabled = [enabledValue boolValue];
    
    NSLog(@"[ZegoPipPlugin] enableCustomVideoRender, isEnabled: %@", isEnabled ? @"YES" : @"NO");
    [[PipManager sharedInstance] enableCustomVideoRender:isEnabled];
    
    result(nil);
  } 
  // Enable/disable hardware decoding
  else if ([@"enableHardwareDecoder" isEqualToString:call.method]) {
    NSDictionary *arguments = call.arguments;
    
    NSNumber *enabledValue = arguments[@"enabled"];
    BOOL isEnabled = [enabledValue boolValue];
    
    NSLog(@"[ZegoPipPlugin] enableHardwareDecoder, isEnabled: %@", isEnabled ? @"YES" : @"NO");
    [[PipManager sharedInstance] enableHardwareDecoder:isEnabled];
    
    result(nil);
  } 
  // Stop PIP functionality
  else if ([@"stopPIP" isEqualToString:call.method]) {
    if (![self checkIOSVersionSupport:@"stopPIP" result:result]) {
      return;
    }
    
    NSLog(@"[ZegoPipPlugin] stopPIP");
    
    BOOL callResult = [[PipManager sharedInstance] stopPIP];
    
    result(@(callResult));
  } 
  // Check if in PIP mode
  else if ([@"isInPIP" isEqualToString:call.method]) {
    if (![self checkIOSVersionSupport:@"isInPIP" result:result]) {
      return;
    }
    
    NSLog(@"[ZegoPipPlugin] isInPIP");
    
    BOOL isInPIP = [[PipManager sharedInstance] isInPIP];
    
    result(@(isInPIP));
  } 
  // Enable PIP functionality
  else if ([@"enablePIP" isEqualToString:call.method]) {
    if (![self checkIOSVersionSupport:@"enablePIP" result:result]) {
      return;
    }
    
    NSDictionary *arguments = call.arguments;
    NSString *streamID = arguments[@"stream_id"];
    
    // Get aspect ratio parameters
    NSNumber* aspectWidth = arguments[@"aspect_width"];
    NSNumber* aspectHeight = arguments[@"aspect_height"];
    CGFloat cgFloatAspectWidth = [aspectWidth floatValue];
    CGFloat cgFloatAspectHeight = [aspectHeight floatValue];
    
    NSLog(@"[ZegoPipPlugin] enablePIP, streamID: %@", streamID);
    
    // Update PIP aspect ratio and enable PIP
    [[PipManager sharedInstance] updatePIPAspectSize:cgFloatAspectWidth :cgFloatAspectHeight];
    [[PipManager sharedInstance] enablePIP:streamID];
    
    result(nil);
  } 
  // Update PIP source stream
  else if ([@"updatePIPSource" isEqualToString:call.method]) {
    if (![self checkIOSVersionSupport:@"updatePIPSource" result:result]) {
      return;
    }
    
    NSDictionary *arguments = call.arguments;
    NSString *streamID = arguments[@"stream_id"];
    
    NSLog(@"[ZegoPipPlugin] updatePIPSource, streamID: %@", streamID);
    
    [[PipManager sharedInstance] updatePIPSource:streamID];
    
    result(nil);
  } 
  // Enable/disable auto PIP
  else if ([@"enableAutoPIP" isEqualToString:call.method]) {
    if (![self checkIOSVersionSupport:@"enableAutoPIP" result:result]) {
      return;
    }
    
    NSDictionary *arguments = call.arguments;
    
    NSNumber *enabledValue = arguments[@"enabled"];
    BOOL isEnabled = [enabledValue boolValue];
    
    // Get aspect ratio parameters
    NSNumber* aspectWidth = arguments[@"aspect_width"];
    NSNumber* aspectHeight = arguments[@"aspect_height"];
    CGFloat cgFloatAspectWidth = [aspectWidth floatValue];
    CGFloat cgFloatAspectHeight = [aspectHeight floatValue];
    
    NSLog(@"[ZegoPipPlugin] enableAutoPIP, isEnabled: %@", isEnabled ? @"YES" : @"NO");
    
    // Update PIP aspect ratio and enable/disable auto PIP
    [[PipManager sharedInstance] updatePIPAspectSize:cgFloatAspectWidth :cgFloatAspectHeight];
    [[PipManager sharedInstance] enableAutoPIP:isEnabled];
    
    result(nil);
  } else {
    // Unimplemented method
    result(FlutterMethodNotImplemented);
  }
}

/**
 * @brief Check if iOS version supports PIP functionality
 * @param methodName Method name for log output
 * @param result Flutter result callback
 * @return BOOL Whether supported
 * 
 * PIP functionality requires iOS 15.0 or higher
 */
- (BOOL)checkIOSVersionSupport:(NSString *)methodName result:(FlutterResult)result {
  NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
  NSArray *versionComponents = [systemVersion componentsSeparatedByString:@"."];
  NSInteger majorVersion = [versionComponents[0] integerValue];
  
  if (majorVersion < 15) {
    NSLog(@"[ZegoPipPlugin] %@ not support smaller than iOS 15", methodName);
    result(nil);
    return NO;
  }
  return YES;
}

/**
 * @brief Start playing stream in PIP
 * @param streamID Stream ID
 * 
 * Call PipManager to start playing stream on main thread
 */
- (void)startPlayingStreamInPIP:(NSString *)streamID {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[PipManager sharedInstance] startPlayingStream:streamID];
  });
}

/**
 * @brief Update playing stream view in PIP
 * @param viewID View ID
 * @param streamID Stream ID
 * @param viewMode View mode
 * 
 * Get platform view and update playing stream view in PIP
 */
- (void)updatePlayingStreamViewInPIP:(NSNumber *)viewID streamID:(NSString *)streamID viewMode:(NSNumber *)viewMode {
  // Get platform view by view ID
  ZegoPlatformView *platformView = [[ZegoPlatformViewFactory sharedInstance] getPlatformView:viewID];
  if (platformView == nil) {
    NSLog(@"[ZegoPipPlugin] platformView is nil");
    return;
  }
  
  // Update playing stream view on main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    [[PipManager sharedInstance] updatePlayingStreamView:streamID videoView:platformView.view viewMode:viewMode];
  });
}

/**
 * @brief Stop playing stream in PIP
 * @param streamID Stream ID
 * 
 * Call PipManager to stop playing stream on main thread
 */
- (void)stopPlayingStreamInPIP:(NSString *)streamID {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[PipManager sharedInstance] stopPlayingStream:streamID];
  });
}

@end 