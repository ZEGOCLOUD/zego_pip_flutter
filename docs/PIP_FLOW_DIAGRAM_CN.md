# iOS PIP 详细流程图

[English](PIP_FLOW_DIAGRAM.md) | [中文](PIP_FLOW_DIAGRAM_CN.md)

## 完整流程概览

```mermaid
graph TD
    A[Flutter: ZegoPIP().init()] --> B[Flutter: 创建 ZegoPIPExpressConfig]
    B --> C[Flutter: 调用平台通道]
    C --> D[iOS: ZegoPipPlugin.registerWithRegistrar]
    D --> E[iOS: 创建 MethodChannel]
    E --> F[iOS: PipManager.setUpAudioSession]
    F --> G[iOS: 初始化 ZegoExpressEngine]
    G --> H[iOS: 启用自定义视频渲染]
    H --> I[Flutter: 初始化完成]
  
    I --> J[Flutter: ZegoPIPVideoView 创建]
    J --> K[Flutter: 调用 enable]
    K --> L[iOS: PipManager.enable]
    L --> M[iOS: 创建 AVPictureInPictureVideoCallViewController]
    M --> N[iOS: 创建 AVPictureInPictureController]
    N --> O[iOS: 设置代理和内容源]
    O --> P[iOS: 创建 KitRemoteView 和显示层]
    P --> Q[iOS: 配置自动布局约束]
    Q --> R[iOS: PIP 准备就绪]
  
    R --> S[用户: 触发 PIP 模式]
    S --> T[iOS: pipController.startPictureInPicture]
    T --> U[iOS: 系统进入 PIP 模式]
    U --> V[iOS: 应用最小化到桌面]
    V --> W[iOS: PIP 窗口显示]
  
    W --> X[用户: 点击 PIP 窗口]
    X --> Y[iOS: 系统退出 PIP 模式]
    Y --> Z[iOS: 应用恢复前台]
    Z --> AA[iOS: 视频继续播放]
    AA --> BB[用户: 正常使用应用]
```

## 详细初始化流程

```mermaid
sequenceDiagram
    participant F as Flutter
    participant P as ZegoPipPlugin
    participant M as PipManager
    participant E as ZegoExpressEngine
    participant A as AVAudioSession
    participant H as ZegoPipPrivate

    F->>F: ZegoPIP().init(expressConfig)
    F->>F: 创建 ZegoPIPExpressConfig 对象
    F->>F: 设置 appID, appSign, roomID, userID, userName
    F->>P: 通过 MethodChannel 调用 init
    P->>P: registerWithRegistrar 被调用
    P->>P: 创建 FlutterMethodChannel
    P->>P: 注册方法调用代理
    P->>M: PipManager.sharedInstance.setUpAudioSession()
    M->>A: 获取共享音频会话
    A-->>M: 返回 AVAudioSession 实例
    M->>A: setCategory:AVAudioSessionModeMoviePlayback
    M->>A: setActive:YES
    M->>E: 初始化 ZegoExpressEngine
    E-->>M: 引擎初始化完成
    M->>E: enableCustomVideoRender:YES
    M->>E: setCustomVideoRenderHandler:self
    
    alt 自定义渲染成功
        E-->>M: 自定义渲染启用完成
        M-->>P: 音频会话设置完成
        P-->>F: 初始化完成
    else 自定义渲染失败 (错误码 1011003)
        E->>H: onDebugError(1011003, "enableCustomVideoRender")
        H->>H: 检测到自定义渲染错误
        H->>H: _tryEnableCustomVideoRender()
        H->>H: 检查引擎状态
        
        alt 引擎已停止
            H->>P: 重新调用 enableCustomVideoRender(true)
            P->>M: PipManager.enableCustomVideoRender(true)
            M->>E: 重新启用自定义渲染
            E-->>M: 自定义渲染启用成功
            M-->>P: 错误恢复完成
            P-->>F: 初始化完成
        else 引擎未停止
            H->>H: 添加引擎状态监听器
            H->>H: 等待引擎停止
            E->>H: onEngineStateUpdate(Stop)
            H->>H: 引擎停止回调触发
            H->>H: _onWaitingEngineStopEnableCustomVideoRender()
            H->>P: 重新调用 enableCustomVideoRender(true)
            P->>M: PipManager.enableCustomVideoRender(true)
            M->>E: 重新启用自定义渲染
            E-->>M: 自定义渲染启用成功
            M-->>P: 错误恢复完成
            P-->>F: 初始化完成
        end
    end
```

## PIP 启用流程

```mermaid
sequenceDiagram
    participant F as Flutter
    participant P as ZegoPipPlugin
    participant M as PipManager
    participant PC as AVPictureInPictureController
    participant VC as AVPictureInPictureVideoCallViewController
    participant KV as KitRemoteView
    participant S as 系统

    F->>F: ZegoPIP().enable()
    F->>P: 通过 MethodChannel 调用 enablePIP
    P->>M: PipManager.enablePIP(streamID)
    M->>M: 检查 iOS 版本 (>= 15.0)
    M->>M: 检查设备 PIP 支持
    M->>M: 更新 PIP 流 ID
    
    alt PIP 控制器存在且激活
        M->>M: 停止当前 PIP
        M->>PC: stopPictureInPicture
        PC-->>M: PIP 已停止
    end
    
    M->>VC: 创建 AVPictureInPictureVideoCallViewController
    M->>VC: 设置宽高比 (aspectWidth:aspectHeight)
    M->>M: 获取 Flutter 视频视图
    M->>M: 创建 PIP 内容源
    M->>PC: 创建 AVPictureInPictureController
    M->>PC: 设置代理: self
    M->>KV: 创建 KitRemoteView
    M->>KV: 添加到 PIP 通话视图控制器
    M->>KV: 设置自动布局约束
    M->>KV: 创建 PIP 显示层
    M->>KV: 添加显示层到视频视图
    
    M->>PC: startPictureInPicture
    PC->>S: 请求 PIP 模式
    S-->>PC: PIP 模式已激活
    PC->>M: pictureInPictureControllerDidStartPictureInPicture
    M-->>P: PIP 启用成功
    P-->>F: 启用完成
```

## PIP 禁用流程

```mermaid
sequenceDiagram
    participant F as Flutter
    participant P as ZegoPipPlugin
    participant M as PipManager
    participant PC as AVPictureInPictureController
    participant S as 系统

    F->>F: ZegoPIP().stopPIP()
    F->>P: 通过 MethodChannel 调用 stopPIP
    P->>M: PipManager.stopPIP()
    M->>M: 检查 iOS 版本 (>= 15.0)
    M->>M: 检查是否在 PIP 模式
    
    alt 在 PIP 模式中
        M->>PC: stopPictureInPicture
        PC->>S: 请求退出 PIP 模式
        S-->>PC: PIP 模式已停用
        PC->>M: pictureInPictureControllerDidStopPictureInPicture
        M->>M: 清理 PIP 资源
        M-->>P: PIP 停止成功
        P-->>F: 停止完成
    else 不在 PIP 模式中
        M-->>P: 已经不在 PIP 模式中
        P-->>F: 停止完成
    end
```

## 视频渲染流程

```mermaid
sequenceDiagram
    participant ZE as ZegoExpressEngine
    participant PM as PipManager
    participant FV as Flutter UIView
    participant ASL as AVSampleBufferDisplayLayer
    participant S as 系统渲染器

    ZE->>ZE: 接收视频帧数据
    ZE->>PM: onRemoteVideoFrameCVPixelBuffer 回调
    PM->>PM: 检查当前 PIP 状态
    
    alt PIP 模式激活
        PM->>ASL: 渲染到 PIP 显示层 (pipLayer)
        ASL->>S: 显示在 PIP 窗口
    else 正常模式
        PM->>FV: 获取 Flutter UIView
        PM->>ASL: 渲染到 Flutter UIView 的注入显示层
        ASL->>FV: 通过注入的显示层显示
        FV->>S: 显示在 Flutter 应用界面
    end
```

## 错误处理流程

```mermaid
graph TD
    A[错误发生] --> B{错误类型}
    
    B -->|自定义渲染错误| C[错误码 1011003]
    B -->|PIP 不支持| D[iOS < 15.0]
    B -->|设备不支持| E[设备限制]
    B -->|引擎错误| F[ZegoExpressEngine 错误]
    
    C --> G[_tryEnableCustomVideoRender]
    G --> H{引擎状态}
    H -->|已停止| I[重新启用自定义渲染]
    H -->|运行中| J[等待引擎停止]
    J --> K[添加状态监听器]
    K --> L[引擎停止回调]
    L --> I
    
    D --> M[显示版本警告]
    E --> N[显示设备警告]
    F --> O[引擎错误恢复]
    
    I --> P[恢复成功]
    M --> Q[需要用户操作]
    N --> Q
    O --> R[引擎重启]
    
    P --> S[继续正常流程]
    Q --> T[用户更新/更换设备]
    R --> S
```

## 状态管理流程

```mermaid
stateDiagram-v2
    [*] --> 未初始化
    未初始化 --> 初始化中: ZegoPIP().init()
    初始化中 --> 已初始化: 初始化成功
    初始化中 --> 错误: 初始化失败
    
    已初始化 --> PIP已启用: enable()
    已初始化 --> 后台PIP: enableWhenBackground()
    
    PIP已启用 --> PIP激活: 用户触发 PIP
    PIP激活 --> PIP已启用: 用户退出 PIP
    PIP激活 --> 应用最小化: 系统最小化
    
    后台PIP --> PIP激活: 应用进入后台
    后台PIP --> 已初始化: cancelBackground()
    
    应用最小化 --> PIP激活: 用户点击 PIP
    应用最小化 --> 已初始化: 用户关闭 PIP
    
    错误 --> 未初始化: 重试
    已初始化 --> 未初始化: uninit()
```

## 关键组件交互

```mermaid
graph TB
    subgraph "Flutter 层"
        A[ZegoPIP] --> B[ZegoPIPVideoView]
        B --> C[MethodChannel]
    end
    
    subgraph "iOS 插件层"
        C --> D[ZegoPipPlugin]
        D --> E[PipManager]
    end
    
    subgraph "iOS 系统层"
        E --> F[AVPictureInPictureController]
        E --> G[AVPictureInPictureVideoCallViewController]
        E --> H[KitRemoteView]
        H --> I[AVSampleBufferDisplayLayer]
    end
    
    subgraph "ZEGO 引擎层"
        E --> J[ZegoExpressEngine]
        J --> K[自定义视频渲染处理器]
        K --> I
    end
    
    subgraph "系统服务"
        F --> L[iOS PIP 服务]
        G --> L
        I --> M[硬件加速渲染]
    end
```

## 性能优化要点

### 1. **内存管理**
- **显示层复用**: 复用 `AVSampleBufferDisplayLayer` 实例
- **缓冲区池**: 实现视频缓冲区池
- **资源清理**: PIP 禁用时正确清理资源

### 2. **渲染优化**
- **硬件加速**: 使用 `AVSampleBufferDisplayLayer` 进行硬件加速
- **帧丢弃**: 实现智能帧丢弃以保持流畅播放
- **分辨率缩放**: 根据 PIP 窗口大小动态调整分辨率

### 3. **音频会话管理**
- **后台音频**: 为后台播放正确配置音频会话
- **音频中断**: 优雅处理音频中断
- **音量控制**: 保持音频音量一致性

### 4. **错误恢复**
- **自动重试**: 实现自动重试机制
- **优雅降级**: 如果 PIP 失败则回退到正常模式
- **状态同步**: 保持 Flutter 和 iOS 状态同步

## 调试和监控

### 1. **日志点**
```objc
// PipManager.m 中的关键日志点
NSLog(@"[PipManager] PIP 已为流启用: %@", streamID);
NSLog(@"[PipManager] 自定义渲染已启用: %@", isEnabled ? @"YES" : @"NO");
NSLog(@"[PipManager] PIP 状态已更改: %ld", (long)state);
```

### 2. **状态监控**
- **PIP 状态**: 监控 `AVPictureInPictureController` 状态变化
- **引擎状态**: 跟踪 `ZegoExpressEngine` 状态
- **渲染状态**: 监控视频渲染性能

### 3. **性能指标**
- **帧率**: 监控视频帧渲染率
- **内存使用**: 跟踪内存消耗
- **CPU 使用**: 监控 PIP 模式下的 CPU 利用率

## 最佳实践

### 1. **初始化顺序**
1. 初始化 Flutter binding
2. 使用正确配置初始化 ZegoPIP
3. 初始化后创建视频视图
4. 启用 PIP 功能

### 2. **错误处理**
1. 始终检查 iOS 版本兼容性
2. 实现正确的错误恢复机制
3. 提供用户友好的错误消息
4. 记录错误以便调试

### 3. **资源管理**
1. PIP 禁用时清理资源
2. 正确处理应用生命周期变化
3. 适当管理音频会话
4. 监控内存使用

### 4. **用户体验**
1. 提供模式之间的平滑过渡
2. 在 PIP 模式下保持视频质量
3. 优雅处理用户交互
4. 为状态变化提供清晰的反馈 