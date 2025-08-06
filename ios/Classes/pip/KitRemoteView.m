/**
 * @file KitRemoteView.m
 * @brief Custom video display view implementation file
 * @author ZEGO Team
 * @date 2024
 * 
 * This file implements the KitRemoteView class, providing video display functionality.
 * Manages AVSampleBufferDisplayLayer lifecycle and layout.
 */

#import "KitRemoteView.h"

@implementation KitRemoteView

/**
 * @brief Initialization method
 * @param frame Initial frame of the view
 * @return Initialized KitRemoteView instance
 * 
 * Initialize view and set display layer to NULL
 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialize display layer as NULL
        _displayLayer = NULL;
    }
    return self;
}

/**
 * @brief Add display layer
 * @param layer AVSampleBufferDisplayLayer to add
 * 
 * Add specified display layer to current view's layer hierarchy
 * and update displayLayer property
 */
- (void)addDisplayLayer:(AVSampleBufferDisplayLayer *)layer {
    // Add display layer as sublayer
    [self.layer addSublayer:layer];
    // Update displayLayer property reference
    self.displayLayer = layer;
}

/**
 * @brief Layout subviews
 * 
 * Called when view size changes, ensuring display layer matches view bounds
 */
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Update display layer frame to match view bounds
    self.displayLayer.frame = self.bounds;
}

@end 