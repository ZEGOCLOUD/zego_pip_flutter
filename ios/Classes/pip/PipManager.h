/**
 * @file PipManager.h
 * @brief Core management class header file for iOS PIP functionality
 * @author ZEGO Team
 * @date 2024
 * 
 * This file defines the PipManager class, responsible for managing iOS platform Picture-in-Picture functionality.
 * Includes PIP enable/disable, status management, and video stream playback control.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class PipManager
 * @brief Core management class for iOS PIP functionality
 * 
 * This class is responsible for:
 * 1. Managing AVPictureInPictureController lifecycle
 * 2. Handling video stream playback and rendering
 * 3. Managing PIP mode switching
 * 4. Handling audio sessions and hardware decoding settings
 * 5. Providing singleton pattern to ensure global unique instance
 */
@interface PipManager : NSObject

/**
 * @brief Get singleton instance of PipManager
 * @return Singleton instance of PipManager
 * 
 * Use singleton pattern to ensure only one PipManager instance globally
 */
+ (instancetype)sharedInstance;

/**
 * @brief Set up audio session
 * 
 * Configure audio session to support PIP functionality, including:
 * - Setting audio category
 * - Configuring audio mode
 * - Enabling audio session
 */
- (void)setUpAudioSession;

#pragma mark - PIP 控制方法

/**
 * @brief Stop PIP functionality
 * @return BOOL Whether PIP was successfully stopped
 * 
 * Stop current PIP mode and return to normal playback mode
 */
- (BOOL) stopPIP;

/**
 * @brief Check if in PIP mode
 * @return BOOL Whether in PIP mode
 * 
 * Check if currently in Picture-in-Picture mode
 */
- (BOOL) isInPIP;

/**
 * @brief Enable PIP functionality
 * @param streamID Stream ID to play
 * @return BOOL Whether PIP was successfully enabled
 * 
 * Enable Picture-in-Picture functionality for specified stream
 */
- (BOOL) enablePIP: (NSString*) streamID;

/**
 * @brief Update PIP source stream
 * @param streamID New stream ID
 * 
 * Switch to new video stream in PIP mode
 */
- (void) updatePIPSource: (NSString*) streamID;

/**
 * @brief Enable/disable auto PIP
 * @param isEnabled Whether to enable auto PIP
 * 
 * Control whether to automatically enter PIP mode
 */
- (void) enableAutoPIP: (BOOL) isEnabled;

/**
 * @brief Update PIP aspect ratio
 * @param aspectWidth Width ratio
 * @param aspectHeight Height ratio
 * 
 * Set PIP window aspect ratio
 */
- (void) updatePIPAspectSize: (CGFloat) aspectWidth :(CGFloat) aspectHeight;

#pragma mark - 硬件设置方法

/**
 * @brief Enable/disable hardware decoding
 * @param isEnabled Whether to enable hardware decoding
 * 
 * Control whether to use hardware decoder for video decoding
 */
- (void) enableHardwareDecoder: (BOOL)isEnabled;

/**
 * @brief Enable/disable custom video rendering
 * @param isEnabled Whether to enable custom video rendering
 * 
 * Control whether to use custom video rendering method
 */
- (void) enableCustomVideoRender: (BOOL)isEnabled;

#pragma mark - 流播放控制方法

/**
 * @brief Start playing stream
 * @param streamID Stream ID to play
 * 
 * Start playing specified video stream
 */
- (void) startPlayingStream:(NSString *)streamID;

/**
 * @brief Update playing stream view
 * @param streamID Stream ID
 * @param videoView Video view
 * @param viewMode View mode
 * 
 * Update video view and display mode for specified stream
 */
- (void) updatePlayingStreamView:(NSString *)streamID videoView:(UIView *)videoView  viewMode:(NSNumber *)viewMode;

/**
 * @brief Stop playing stream
 * @param streamID Stream ID to stop
 * 
 * Stop playing specified video stream
 */
- (void) stopPlayingStream:(NSString *)streamID;

@end

NS_ASSUME_NONNULL_END 