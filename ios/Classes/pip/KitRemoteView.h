/**
 * @file KitRemoteView.h
 * @brief Custom video display view header file
 * @author ZEGO Team
 * @date 2024
 * 
 * This file defines the KitRemoteView class for displaying remote video streams.
 * Inherits from UIView and integrates AVSampleBufferDisplayLayer for efficient video rendering.
 */

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class KitRemoteView
 * @brief Custom video display view
 * 
 * This class is responsible for:
 * 1. Providing video display container
 * 2. Managing AVSampleBufferDisplayLayer
 * 3. Supporting dynamic addition and removal of display layers
 * 4. Optimizing video rendering performance
 */
@interface KitRemoteView : UIView

/**
 * @brief Video display layer
 * 
 * AVSampleBufferDisplayLayer for rendering video frames
 * Supports efficient hardware-accelerated video rendering
 */
@property(nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;

/**
 * @brief Add display layer
 * @param layer AVSampleBufferDisplayLayer to add
 * 
 * Add specified display layer to current view
 * Used for dynamically switching different video sources
 */
- (void)addDisplayLayer:(AVSampleBufferDisplayLayer *)layer;

@end

NS_ASSUME_NONNULL_END 