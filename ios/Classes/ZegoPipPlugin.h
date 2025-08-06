/**
 * @file ZegoPipPlugin.h
 * @brief Main header file for Zego PIP Flutter plugin
 * @author ZEGO Team
 * @date 2024
 * 
 * This file defines the ZegoPipPlugin class, which serves as a bridge between Flutter and iOS native PIP functionality.
 * Implements the FlutterPlugin protocol and is responsible for handling method calls from Flutter.
 */

#import <Flutter/Flutter.h>

/**
 * @class ZegoPipPlugin
 * @brief Main implementation class for Flutter PIP plugin
 * 
 * This class is responsible for:
 * 1. Registering Flutter method channels
 * 2. Handling method calls from Flutter
 * 3. Managing PIP functionality lifecycle
 * 4. Interacting with PipManager
 */
@interface ZegoPipPlugin : NSObject <FlutterPlugin>

@end 