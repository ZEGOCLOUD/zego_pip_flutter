/**
 * @file PipManager.m
 * @brief iOS PIP 功能的核心管理类实现文件
 * @author ZEGO Team
 * @date 2024
 * 
 * 该文件实现了 PipManager 类，负责管理 iOS 平台的 Picture-in-Picture 功能。
 * 包括 PIP 的启用、停止、状态管理以及视频流的播放控制。
 * 使用 AVPictureInPictureController 和 AVPictureInPictureVideoCallViewController 实现 PIP 功能。
 */

#import "PipManager.h"

#import <AVKit/AVKit.h>

#import "Masonry.h"
#import "KitRemoteView.h"

@import ZegoExpressEngine;

// Flutter 层名称常量
#define kFlutterLayerName   @"KitDisplayLayer"

// 单例模式相关变量
static dispatch_once_t onceToken;
static id _instance;

/**
 * @class PipManager (Private Interface)
 * @brief PipManager 的私有接口扩展
 * 
 * 实现了 AVPictureInPictureControllerDelegate 和 ZegoCustomVideoRenderHandler 协议
 * 用于处理 PIP 控制器的回调和自定义视频渲染
 */
API_AVAILABLE(ios(15.0))
@interface PipManager () <AVPictureInPictureControllerDelegate, ZegoCustomVideoRenderHandler>

// PIP 控制相关属性
@property (nonatomic, assign) BOOL isAutoStarted;        // 是否自动启动 PIP
@property (nonatomic, assign) CGFloat aspectWidth;       // PIP 窗口宽度比例
@property (nonatomic, assign) CGFloat aspectHeight;      // PIP 窗口高度比例
@property (nonatomic, assign) ZegoViewMode currentViewMode; // 当前视图模式

// PIP 控制器相关属性
@property (nonatomic, strong) AVPictureInPictureController *pipController;           // PIP 控制器
@property (nonatomic, strong) AVPictureInPictureVideoCallViewController *pipCallVC;  // PIP 视频通话视图控制器

// 视频视图管理
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *flutterVideoViewDictionary; // Flutter 视频视图字典

// PIP 视频显示相关属性
@property (nonatomic, strong) KitRemoteView *pipVideoView;    // PIP 视频视图
@property (nonatomic, strong) AVSampleBufferDisplayLayer *pipLayer; // PIP 显示层
@property (nonatomic, strong) NSString *pipStreamID;          // 当前 PIP 流 ID

@end

@implementation PipManager

/**
 * @brief 获取 PipManager 的单例实例
 * @return PipManager 的单例实例
 * 
 * 使用 dispatch_once 确保线程安全的单例模式
 */
+ (instancetype)sharedInstance {
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

/**
 * @brief 初始化方法
 * @return 初始化后的 PipManager 实例
 * 
 * 初始化默认配置：
 * - 自动启动 PIP
 * - 默认宽高比 9:16
 * - 默认视图模式为适应模式
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置默认配置
        self.isAutoStarted = YES;
        self.aspectWidth = 9;
        self.aspectHeight = 16;
        self.currentViewMode = ZegoViewModeAspectFit;
        
        // 初始化 Flutter 视频视图字典
        self.flutterVideoViewDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

/**
 * @brief 设置音频会话
 * 
 * 配置音频会话以支持 PIP 功能：
 * - 设置音频类别为电影播放模式
 * - 激活音频会话
 * - 处理异常情况
 */
- (void)setUpAudioSession {
    @try {
        NSLog(@"[PIPManager] setUpAudioSession");
        
        // 获取共享音频会话实例
        AVAudioSession* audioSession = [AVAudioSession sharedInstance];
        // 设置音频类别为电影播放模式，适合 PIP 场景
        [audioSession setCategory:AVAudioSessionModeMoviePlayback error:nil];
        // 激活音频会话
        [audioSession setActive:YES error:nil];
    } @catch (NSException *exception) {
        NSLog(@"[PIPManager] setUpAudioSession error:%@", exception);
    }
}

/**
 * @brief 启动 PIP 功能
 * @param streamID 要播放的流 ID
 * @return BOOL 是否成功启动 PIP
 * 
 * 启动 Picture-in-Picture 功能：
 * 1. 更新 PIP 源流
 * 2. 检查 iOS 版本支持
 * 3. 检查 PIP 功能支持
 * 4. 启动 PIP 控制器
 */
- (BOOL) startPIP : (NSString* ) streamID {
    NSLog(@"[PIPManager] startPIP, stream id:%@", streamID);
    
    // 更新 PIP 源流
    [self updatePIPSource:streamID];
    
    // 检查 iOS 15.0+ 支持
    if (@available(iOS 15.0, *)) {
        // 检查设备是否支持 PIP 功能
        if ([AVPictureInPictureController isPictureInPictureSupported]) {
            // 更新 PIP 流 ID
            [self updatePIPStreamID: streamID];
            
            // 检查 PIP 控制器是否存在
            if(nil != self.pipController) {
                // 检查 PIP 是否已经激活
                if(! self.pipController.isPictureInPictureActive) {
                    NSLog(@"[PIPManager] startPIP run");
                    // 启动 PIP
                    [self.pipController startPictureInPicture];
                }
            } else {
                NSLog(@"[PIPManager] startPIP, pip controller is nil");
            }
        }
    }
    
    return FALSE;
}

/**
 * @brief 停止 PIP 功能
 * @return BOOL 是否成功停止 PIP
 * 
 * 停止 Picture-in-Picture 功能：
 * 1. 检查 iOS 版本支持
 * 2. 检查 PIP 功能支持
 * 3. 停止 PIP 控制器
 */
- (BOOL) stopPIP {
    NSLog(@"[PIPManager] stopPIP");
    
    // 检查 iOS 15.0+ 支持
    if (@available(iOS 15.0, *)) {
        // 检查设备是否支持 PIP 功能
        if ([AVPictureInPictureController isPictureInPictureSupported]) {
            // 检查 PIP 控制器是否存在
            if(nil != self.pipController) {
                // 检查 PIP 是否已经激活
                if(self.pipController.isPictureInPictureActive) {
                    NSLog(@"[PIPManager] stopPIP run");
                    // 停止 PIP
                    [self.pipController stopPictureInPicture];
                }
            }
        }
    }
    
    [self enableMultiTaskForSDK:FALSE];
    
    return FALSE;
}

/**
 * @brief 检查是否在 PIP 模式
 * @return BOOL 是否在 PIP 模式
 * 
 * 检查当前是否处于 Picture-in-Picture 模式
 */
- (BOOL) isInPIP {
    return [self.pipController isPictureInPictureActive];
}

/**
 * @brief 更新 PIP 流 ID
 * @param streamID 新的流 ID
 * 
 * 更新当前 PIP 播放的流 ID，用于跟踪当前播放的流
 */
- (void) updatePIPStreamID: (NSString*) streamID {
    NSLog(@"[PIPManager] updatePIPStreamID %@", streamID);
    
    self.pipStreamID = streamID;
}

- (void) updatePIPAspectSize: (CGFloat) aspectWidth :(CGFloat) aspectHeight {
    NSLog(@"[PIPManager] updatePIPAspectSize (%f, %f)", aspectWidth, aspectHeight);
    
    self.aspectWidth = aspectWidth;
    self.aspectHeight = aspectHeight;
}

- (void) updatePIPSource: (NSString*) streamID {
    NSLog(@"[PIPManager] updatePIPSource, stream id:%@", streamID);
    
    if(self.pipStreamID == streamID) {
        NSLog(@"[PIPManager] updatePIPSource, stream id is same");
        
        return;
    }
    [self updatePIPStreamID:streamID];
    
    if(nil == self.pipController) {
        NSLog(@"[PIPManager] updatePIPSource, pip controller is nil");
        
        return;
    }
    
    if (@available(iOS 17.4, *)) {
        UIView* flutterVideoView = [self.flutterVideoViewDictionary objectForKey:streamID];
        if(nil != flutterVideoView) {
            AVSampleBufferDisplayLayer* flutterDisplayLayer =[self getLayerOfView:flutterVideoView];
            if(! flutterDisplayLayer.isReadyForDisplay) {
                NSLog(@"[PIPManager] updatePIPSource, view is not ready for display, reject update");
                
                return;
            }
            
            AVPictureInPictureControllerContentSource *contentSource = [[AVPictureInPictureControllerContentSource alloc] initWithActiveVideoCallSourceView:flutterVideoView contentViewController:self.pipCallVC];
            self.pipController.contentSource = contentSource;
            
            NSLog(@"[PIPManager] updatePIPSource, update %@'s view to pip controller, view:%@, layer:%@", streamID, flutterVideoView, flutterDisplayLayer);
        } else {
            
            NSLog(@"[PIPManager] updatePIPSource, video view is nil");
        }
    }
}

/**
 * @brief 启用/禁用自动 PIP
 * @param isEnabled 是否启用自动 PIP
 * 
 * 控制是否自动进入 PIP 模式
 */
- (void) enableAutoPIP: (BOOL) isEnabled {
    NSLog(@"[PIPManager] enableAutoPIP: %@", isEnabled ? @"YES" : @"NO");
    
    self.isAutoStarted = isEnabled;
}

/**
 * @brief 启用 PIP 功能
 * @param streamID 要播放的流 ID
 * @return BOOL 是否成功启用 PIP
 * 
 * 为指定的流启用 Picture-in-Picture 功能：
 * 1. 更新 PIP 流 ID
 * 2. 检查 iOS 版本和 PIP 支持
 * 3. 清理旧的 PIP 对象
 * 4. 创建新的 PIP 控制器和视图
 * 5. 设置 PIP 视频视图和显示层
 * 6. 配置自动启动设置
 */
- (BOOL) enablePIP: (NSString*) streamID  {
    NSLog(@"[PIPManager] enablePIP, stream id:%@", streamID);
    
    // 更新 PIP 流 ID
    [self updatePIPStreamID: streamID];
    
    // 检查 iOS 15.0+ 支持
    if (@available(iOS 15.0, *)) {
        // 检查设备是否支持 PIP 功能
        if ([AVPictureInPictureController isPictureInPictureSupported]) {
            // 清理旧的 PIP 对象
            if(nil != self.pipController) {
                NSLog(@"[PIPManager] enablePIP, destory objects");
                
                self.pipLayer = NULL;
                self.pipVideoView = NULL;
                
                self.pipCallVC = NULL;
                self.pipController = NULL;
            }
            
            NSLog(@"[PIPManager] enablePIP, create objects");
            
            // 创建 PIP 视频通话视图控制器
            self.pipCallVC = [AVPictureInPictureVideoCallViewController new];
            // 设置 PIP 窗口的宽高比
            self.pipCallVC.preferredContentSize = CGSizeMake(self.aspectWidth, self.aspectHeight);
            
            // 获取 Flutter 视频视图
            UIView* flutterVideoView = [self.flutterVideoViewDictionary objectForKey:streamID];
            // 创建 PIP 内容源
            AVPictureInPictureControllerContentSource *contentSource = [[AVPictureInPictureControllerContentSource alloc] initWithActiveVideoCallSourceView:flutterVideoView contentViewController:self.pipCallVC];
            
            // 创建 PIP 控制器并设置代理
            self.pipController = [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
            self.pipController.delegate = self;
            
            // 创建 PIP 视频视图
            self.pipVideoView = [[KitRemoteView alloc] initWithFrame:CGRectZero];
            if(nil != self.pipCallVC) {
                NSLog(@"[PIPManager] enablePIP, add pip video view in pip call vc");
                // 将 PIP 视频视图添加到 PIP 通话视图控制器中
                [self.pipCallVC.view addSubview:self.pipVideoView];
            }
            
            // 设置 PIP 视频视图的自动布局约束
            self.pipVideoView.translatesAutoresizingMaskIntoConstraints = NO;
            [self.pipVideoView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.pipCallVC.view);
            }];
            
            // 创建 PIP 显示层并添加到视频视图中
            self.pipLayer = [self createAVSampleBufferDisplayLayer];
            [self.pipVideoView addDisplayLayer:self.pipLayer];
            
            NSLog(@"[PIPManager] enablePIP, update auto started to %@", self.isAutoStarted ? @"YES" : @"NO");
            self.pipController.canStartPictureInPictureAutomaticallyFromInline = self.isAutoStarted;
        }
        
    }
    
    return YES;
}

/**
 * @brief 启用/禁用硬件解码
 * @param isEnabled 是否启用硬件解码
 * 
 * 控制是否使用硬件解码器进行视频解码，提高性能
 */
- (void)enableHardwareDecoder: (BOOL) isEnabled {
    NSLog(@"[PIPManager] enableHardwareDecoder: %@", isEnabled ? @"YES" : @"NO");
    
    [[ZegoExpressEngine sharedEngine] enableHardwareDecoder:isEnabled];
}

/**
 * @brief 启用/禁用自定义视频渲染
 * @param isEnabled 是否启用自定义视频渲染
 * 
 * 控制是否使用自定义的视频渲染方式：
 * - 启用时：配置自定义渲染参数并设置渲染处理器
 * - 禁用时：清除渲染处理器并禁用自定义渲染
 */
- (void)enableCustomVideoRender: (BOOL) isEnabled {
    NSLog(@"[PIPManager] enableCustomVideoRender: %@", isEnabled ? @"YES" : @"NO");
    
    if(isEnabled) {
        // 启用自定义渲染，在渲染回调中分发到不同的层
        ZegoCustomVideoRenderConfig *renderConfig = [[ZegoCustomVideoRenderConfig alloc] init];
        renderConfig.bufferType = ZegoVideoBufferTypeCVPixelBuffer;  // 使用 CVPixelBuffer 类型
        renderConfig.frameFormatSeries = ZegoVideoFrameFormatSeriesRGB;  // 使用 RGB 格式

        // 启用自定义视频渲染并设置配置
        [[ZegoExpressEngine sharedEngine] enableCustomVideoRender:YES config:renderConfig];
        // 设置自定义视频渲染处理器
        [[ZegoExpressEngine sharedEngine] setCustomVideoRenderHandler:self];
    } else {
        // 清除自定义视频渲染处理器
        [[ZegoExpressEngine sharedEngine] setCustomVideoRenderHandler:nil];
        // 禁用自定义视频渲染
        [[ZegoExpressEngine sharedEngine] enableCustomVideoRender:NO config:NULL];
    }
}

/**
 * @brief 开始播放流
 * @param streamID 要播放的流 ID
 * 
 * 使用 ZegoExpressEngine 开始播放指定的视频流
 */
- (void)startPlayingStream:(NSString *)streamID {
    NSLog(@"[PIPManager] startPlayingStream, stream id:%@", streamID);
    
    [[ZegoExpressEngine sharedEngine] startPlayingStream:streamID];
}

/**
 * @brief 更新播放流视图
 * @param streamID 流 ID
 * @param videoView 视频视图
 * @param viewMode 视图模式
 * 
 * 更新指定流的视频视图和显示模式：
 * 1. 为视频视图添加 Flutter 层
 * 2. 设置视图模式
 * 3. 如果 PIP 已激活，更新 PIP 流 ID
 * 4. 否则启用 PIP 功能
 */
- (void)updatePlayingStreamView:(NSString *)streamID videoView:(UIView *)videoView viewMode:(NSNumber *)viewMode{
    NSLog(@"[PIPManager] updatePlayingStreamView, stream id:%@, video view:%@, view mode:%@", streamID, videoView, viewMode);
    
    // 为视频视图添加自定义渲染层，如果没有找到则添加一个
    [self addFlutterLayerWithView:streamID :videoView];
    // 设置视图模式
    [self setViewMode:(ZegoViewMode)[viewMode integerValue]];
    
    // 检查 PIP 控制器是否存在且已激活
    if(self.pipController != nil && self.pipController.isPictureInPictureActive) {
        // 如果 PIP 已激活，更新 PIP 流 ID
        [self updatePIPStreamID: streamID];
    } else {
        // 否则启用 PIP 功能
        [self enablePIP:streamID];
    }
}

- (void)stopPlayingStream:(NSString *)streamID {
    NSLog(@"[PIPManager] stopPlayingStream, stream id:%@", streamID);
    
    UIView* flutterVideoView = [self.flutterVideoViewDictionary objectForKey:streamID];
    [flutterVideoView removeObserver:self forKeyPath:@"bounds"];
    [self.flutterVideoViewDictionary removeObjectForKey:streamID];
    
    [[ZegoExpressEngine sharedEngine] stopPlayingStream:streamID];
}

- (AVSampleBufferDisplayLayer *)createAVSampleBufferDisplayLayer
{
    NSLog(@"[PIPManager] createAVSampleBufferDisplayLayer");
    
    AVSampleBufferDisplayLayer *layer = [[AVSampleBufferDisplayLayer alloc] init];
    layer.videoGravity = [self videoGravityForViewMode:self.currentViewMode];
    layer.opaque = YES;
    
    return layer;
}

- (void)enableMultiTaskForSDK:(BOOL)enable
{
    NSLog(@"[PIPManager] enableMultiTaskForSDK: %@", enable ? @"YES" : @"NO");
    
    NSString *params = nil;
    if (enable){
        params = @"{\"method\":\"liveroom.video.enable_ios_multitask\",\"params\":{\"enable\":true}}";
        [[ZegoExpressEngine sharedEngine] callExperimentalAPI:params];
    } else {
        params = @"{\"method\":\"liveroom.video.enable_ios_multitask\",\"params\":{\"enable\":false}}";
        [[ZegoExpressEngine sharedEngine] callExperimentalAPI:params];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"bounds"]) {
        UIView *targetFlutterView = nil;
        for (UIView *view in self.flutterVideoViewDictionary.allValues) {
            if (view == object) {
                targetFlutterView = view;
                break;
            }
        }
        
        if(nil != targetFlutterView) {
            CGRect newBounds = [[change objectForKey:NSKeyValueChangeNewKey] CGRectValue];
            
            AVSampleBufferDisplayLayer* flutterDisplayLayer = [self getLayerOfView:targetFlutterView];
            if(nil != flutterDisplayLayer) {
                NSLog(@"[PIPManager] observeValueForKeyPath, sync display layer frame of flutter video view, %@", NSStringFromCGRect(newBounds));
                
                flutterDisplayLayer.frame = newBounds;
            } else {
                NSLog(@"[PIPManager] observeValueForKeyPath, not found display layer of flutter video view");
            }
        }
        
    }
}

#pragma mark - AVPictureInPictureControllerDelegate
- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"[PIPManager] pictureInPictureController willStart");
    [self enableMultiTaskForSDK:TRUE];
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"[PIPManager] pictureInPictureController didStart");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error {
    NSLog(@"[PIPManager] pictureInPictureController failedToStart, error: %@", error);
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"[PIPManager] pictureInPictureController willStop");
    
    [self enableMultiTaskForSDK:FALSE];
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"[PIPManager] pictureInPictureController didStop");
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL restored))completionHandler {
    NSLog(@"[PIPManager] pictureInPictureController restoreUserInterface");
}

#pragma mark - ZegoCustomVideoRenderHandler

/**
 * @brief 远程视频帧回调方法
 * @param buffer 视频帧的 CVPixelBuffer 数据
 * @param param 视频帧参数，包含格式、尺寸等信息
 * @param streamID 流 ID，用于标识视频流
 *
 * 这是 ZegoExpressEngine 自定义视频渲染的核心回调方法，负责：
 * 1. 接收来自 ZegoExpressEngine 的视频帧数据
 * 2. 将 CVPixelBuffer 转换为 CMSampleBuffer
 * 3. 根据当前状态决定渲染目标：
 *    - PIP 模式：渲染到 PIP 显示层 (pipLayer)
 *    - 正常模式：渲染到 Flutter UIView 的注入显示层
 * 4. 处理渲染错误和异常情况
 * 5. 管理内存释放
 *
 * 关键流程：
 * - 视频帧数据 → CMSampleBuffer → 目标显示层 → 用户界面
 * - 支持双模式无缝切换，确保视频渲染的连续性
 */
- (void)onRemoteVideoFrameCVPixelBuffer:(CVPixelBufferRef)buffer param:(ZegoVideoFrameParam *)param streamID:(NSString *)streamID
{
    // 将 CVPixelBuffer 转换为 CMSampleBuffer，用于 AVSampleBufferDisplayLayer 渲染
    CMSampleBufferRef sampleBuffer = [self createSampleBuffer:buffer];
    if (sampleBuffer) {
        // 获取对应的 Flutter UIView 和其注入的显示层
        UIView* flutterVideoView = [self.flutterVideoViewDictionary objectForKey:streamID];
        // 正常模式：渲染到 Flutter UIView 的注入显示层
        AVSampleBufferDisplayLayer *destLayer = [self getLayerOfViewInMainThread:flutterVideoView];
        
        // 判断当前是否在 PIP 模式且是 PIP 流
        if(self.pipController.pictureInPictureActive && [self.pipStreamID isEqualToString:streamID])  {
            destLayer = self.pipLayer; // PIP 模式：渲染到 PIP 显示层
        }
        
        // 渲染视频帧到目标显示层
        if(nil != destLayer) {
            [destLayer enqueueSampleBuffer:sampleBuffer]; // 🎯 渲染视频帧到目标显示层
            
            // 检查渲染状态，处理渲染失败的情况
            if (destLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
                // 错误码 -11847 表示渲染层需要重建
                if (-11847 == destLayer.error.code) {
                    if (destLayer == self.pipLayer) {
                        // PIP 层渲染失败，重建 PIP 层
                        [self performSelectorOnMainThread:@selector(rebuildPIPLayer) withObject:NULL waitUntilDone:YES];
                    } else {
                        // Flutter 层渲染失败，重建对应的 Flutter 层
                        [self performSelectorOnMainThread:@selector(rebuildFlutterLayer:) withObject:streamID waitUntilDone:YES];
                    }
                }
            }
        }
        
        // 释放 CMSampleBuffer，避免内存泄漏
        CFRelease(sampleBuffer);
    }
}

/**
 * @brief 创建 CMSampleBuffer 从 CVPixelBuffer
 * @param pixelBuffer 输入的 CVPixelBuffer
 * @return CMSampleBufferRef 创建的 CMSampleBuffer，失败时返回 NULL
 *
 * 该方法负责将 CVPixelBuffer 转换为 CMSampleBuffer，用于 AVSampleBufferDisplayLayer 渲染：
 * 1. 验证输入参数的有效性
 * 2. 创建视频格式描述
 * 3. 生成 CMSampleBuffer
 * 4. 设置立即显示标志
 * 5. 管理内存释放
 */
- (CMSampleBufferRef)createSampleBuffer:(CVPixelBufferRef)pixelBuffer
{
    // 验证输入参数
    if (!pixelBuffer) {
        NSLog(@"[PIPManager] createSampleBuffer, pixelBuffer is null");
        return NULL;
    }
    
    // 设置时间信息为无效，不指定具体的时间戳
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    
    // 创建视频格式描述，用于描述 CVPixelBuffer 的格式信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    
    // 从 CVPixelBuffer 创建 CMSampleBuffer
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    if (result != noErr) {
        NSLog(@"[PIPManager] createSampleBuffer, Failed to create sample buffer, error: %d", (int)result);
        return NULL;
    }
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    
    // 释放视频格式描述，避免内存泄漏
    CFRelease(videoInfo);
    
    // 设置立即显示标志，确保视频帧能够立即渲染
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    return sampleBuffer;
}

/**
 * @brief 获取 UIView 中注入的 AVSampleBufferDisplayLayer
 * @param videoView 要查找的 UIView
 * @return AVSampleBufferDisplayLayer* 找到的显示层，未找到时返回 nil
 *
 * 该方法用于从 Flutter UIView 中获取之前注入的 AVSampleBufferDisplayLayer：
 * 1. 验证输入参数的有效性
 * 2. 遍历 UIView 的所有子层
 * 3. 根据层名称查找目标显示层
 * 4. 同步显示层的框架尺寸
 * 5. 返回找到的显示层
 */
- (AVSampleBufferDisplayLayer*) getLayerOfView:(UIView *)videoView {
    // 验证输入参数
    if(nil == videoView) {
        return nil;
    }
    
    // 遍历 UIView 的所有子层，查找注入的显示层
    AVSampleBufferDisplayLayer* targetLayer = nil;
    for (CALayer *layer in videoView.layer.sublayers) {
        if ([layer.name isEqualToString:kFlutterLayerName]) {
            targetLayer = (AVSampleBufferDisplayLayer *)layer;
            // 同步显示层的框架尺寸，确保与 UIView 保持一致
            if(!CGRectIsEmpty(videoView.bounds)) {
                targetLayer.frame = videoView.bounds;
            }
            break;
        }
    }
    
    return targetLayer;
}

- (AVSampleBufferDisplayLayer*) getLayerOfViewInMainThread:(UIView *)videoView {
    if(nil == videoView) {
        return nil;
    }
    
    __block AVSampleBufferDisplayLayer* targetLayer = nil;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (CALayer *layer in videoView.layer.sublayers) {
            if ([layer.name isEqualToString:kFlutterLayerName]) {
                targetLayer = (AVSampleBufferDisplayLayer *)layer;
                if(!CGRectIsEmpty(videoView.bounds)) {
                    targetLayer.frame = videoView.bounds;
                }
                break;
            }
        }
    });
    
    return targetLayer;
}

- (void)addFlutterLayerWithView:(NSString *)streamID  :(UIView *)videoView  {
    NSLog(@"[PIPManager] addFlutterLayerWithView, video view:%@", videoView);
    
    UIView* flutterVideoView = [self.flutterVideoViewDictionary objectForKey:streamID];
    if (flutterVideoView != videoView) {
        NSLog(@"[PIPManager] addFlutterLayerWithView, update video view(%@) of stream(%@)", videoView, streamID);
        
        if(nil != flutterVideoView) {
            [flutterVideoView removeObserver:self forKeyPath:@"bounds"];
        }
        [self.flutterVideoViewDictionary setObject:videoView forKey:streamID];
    }
    
    AVSampleBufferDisplayLayer* displayLayer = [self getLayerOfView:videoView];
    if (nil == displayLayer) {
        displayLayer = [self createAVSampleBufferDisplayLayer];
        displayLayer.name = kFlutterLayerName;
        [videoView.layer addSublayer:displayLayer];
        
        displayLayer.frame = videoView.bounds;
        displayLayer.videoGravity = [self videoGravityForViewMode:self.currentViewMode];
        
        NSLog(@"[PIPManager] addFlutterLayerWithView, layer not found, add layer:%@ in videoView:%@", displayLayer, videoView);
    }
    
    [videoView addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)rebuildFlutterLayer:(NSString* )streamID {
    NSLog(@"[PIPManager] rebuildFlutterLayer, stream id:%@", streamID);
    
    @synchronized(self) {
        UIView* flutterVideoView = [self.flutterVideoViewDictionary objectForKey:streamID];
        if(nil != flutterVideoView) {
            AVSampleBufferDisplayLayer* displayLayer = [self getLayerOfView:flutterVideoView];
            if (nil != displayLayer) {
                NSLog(@"[PIPManager] rebuildFlutterLayer, remove %@ from super layer", displayLayer);
                [displayLayer removeFromSuperlayer];
            } else {
                NSLog(@"[PIPManager] rebuildFlutterLayer, layer is nil");
            }
        } else {
            NSLog(@"[PIPManager] rebuildFlutterLayer, video view is nil");
        }
        
        [self addFlutterLayerWithView:streamID :flutterVideoView];
    }
}

- (void)rebuildPIPLayer {
    NSLog(@"[PIPManager] rebuildPIPLayer");
    
    @synchronized(self) {
        if (self.pipLayer) {
            NSLog(@"[PIPManager] rebuildPIPLayer, remove %@ from super layer", self.pipLayer);
            
            [self.pipLayer removeFromSuperlayer];
            self.pipLayer = nil;
        }
        
        self.pipLayer = [self createAVSampleBufferDisplayLayer];
        [self.pipVideoView addDisplayLayer:self.pipLayer];
    }
}

- (void)setViewMode:(ZegoViewMode)viewMode {
    NSLog(@"[PIPManager] setViewMode: %d", (int)viewMode);
    
    self.currentViewMode = viewMode;
    
    // 更新现有layer的videoGravity
    if (self.pipLayer) {
        self.pipLayer.videoGravity = [self videoGravityForViewMode:viewMode];
    }
    
    // 更新所有flutter layer的videoGravity
    for (UIView *videoView in self.flutterVideoViewDictionary.allValues) {
        AVSampleBufferDisplayLayer *layer = [self getLayerOfView:videoView];
        if (layer) {
            layer.videoGravity = [self videoGravityForViewMode:viewMode];
        }
    }
}

- (NSString *)videoGravityForViewMode:(ZegoViewMode)viewMode {
    switch (viewMode) {
        case ZegoViewModeAspectFit:
            return AVLayerVideoGravityResizeAspect;
        case ZegoViewModeAspectFill:
            return AVLayerVideoGravityResizeAspectFill;
        case ZegoViewModeScaleToFill:
            return AVLayerVideoGravityResize;
        default:
            return AVLayerVideoGravityResizeAspect;
    }
}

@end 
