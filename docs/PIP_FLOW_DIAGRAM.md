# iOS PIP Detailed Flow Diagram

[English](PIP_FLOW_DIAGRAM.md) | [中文](PIP_FLOW_DIAGRAM_CN.md)

## Complete Flow Overview

```mermaid
graph TD
    A[Flutter: ZegoPIP().init()] --> B[Flutter: Create ZegoPIPExpressConfig]
    B --> C[Flutter: Call Platform Channel]
    C --> D[iOS: ZegoPipPlugin.registerWithRegistrar]
    D --> E[iOS: Create MethodChannel]
    E --> F[iOS: PipManager.setUpAudioSession]
    F --> G[iOS: Initialize ZegoExpressEngine]
    G --> H[iOS: Enable Custom Video Rendering]
    H --> I[Flutter: Initialization Complete]
  
    I --> J[Flutter: ZegoPIPVideoView Creation]
    J --> K[Flutter: Call enable]
    K --> L[iOS: PipManager.enable]
    L --> M[iOS: Create AVPictureInPictureVideoCallViewController]
    M --> N[iOS: Create AVPictureInPictureController]
    N --> O[iOS: Set Delegate and Content Source]
    O --> P[iOS: Create KitRemoteView and Display Layer]
    P --> Q[iOS: Configure Auto Layout Constraints]
    Q --> R[iOS: PIP Ready]
  
    R --> S[User: Trigger PIP Mode]
    S --> T[iOS: pipController.startPictureInPicture]
    T --> U[iOS: System Enters PIP Mode]
    U --> V[iOS: App Minimizes to Desktop]
    V --> W[iOS: PIP Window Displays]
  
    W --> X[User: Click PIP Window]
    X --> Y[iOS: System Exits PIP Mode]
    Y --> Z[iOS: App Returns to Foreground]
    Z --> AA[iOS: Video Continues Playing]
    AA --> BB[User: Normal App Usage]
```

## Detailed Initialization Flow

```mermaid
sequenceDiagram
    participant F as Flutter
    participant P as ZegoPipPlugin
    participant M as PipManager
    participant E as ZegoExpressEngine
    participant A as AVAudioSession
    participant H as ZegoPipPrivate

    F->>F: ZegoPIP().init(expressConfig)
    F->>F: Create ZegoPIPExpressConfig object
    F->>F: Set appID, appSign, roomID, userID, userName
    F->>P: Call init via MethodChannel
    P->>P: registerWithRegistrar called
    P->>P: Create FlutterMethodChannel
    P->>P: Register method call delegate
    P->>M: PipManager.sharedInstance.setUpAudioSession()
    M->>A: Get shared audio session
    A-->>M: Return AVAudioSession instance
    M->>A: setCategory:AVAudioSessionModeMoviePlayback
    M->>A: setActive:YES
    M->>E: Initialize ZegoExpressEngine
    E-->>M: Engine initialization complete
    M->>E: enableCustomVideoRender:YES
    M->>E: setCustomVideoRenderHandler:self
    
    alt Custom rendering successful
        E-->>M: Custom rendering enabled
        M-->>P: Audio session setup complete
        P-->>F: Initialization complete
    else Custom rendering failed (Error code 1011003)
        E->>H: onDebugError(1011003, "enableCustomVideoRender")
        H->>H: Detect custom rendering error
        H->>H: _tryEnableCustomVideoRender()
        H->>H: Check engine status
        
        alt Engine stopped
            H->>P: Re-call enableCustomVideoRender(true)
            P->>M: PipManager.enableCustomVideoRender(true)
            M->>E: Re-enable custom rendering
            E-->>M: Custom rendering enabled successfully
            M-->>P: Error recovery complete
            P-->>F: Initialization complete
        else Engine not stopped
            H->>H: Add engine status listener
            H->>H: Wait for engine to stop
            E->>H: onEngineStateUpdate(Stop)
            H->>H: Engine stop callback triggered
            H->>H: _onWaitingEngineStopEnableCustomVideoRender()
            H->>P: Re-call enableCustomVideoRender(true)
            P->>M: PipManager.enableCustomVideoRender(true)
            M->>E: Re-enable custom rendering
            E-->>M: Custom rendering enabled successfully
            M-->>P: Error recovery complete
            P-->>F: Initialization complete
        end
    end
```

## PIP Enable Flow

```mermaid
sequenceDiagram
    participant F as Flutter
    participant P as ZegoPipPlugin
    participant M as PipManager
    participant PC as AVPictureInPictureController
    participant VC as AVPictureInPictureVideoCallViewController
    participant KV as KitRemoteView
    participant S as System

    F->>F: ZegoPIP().enable()
    F->>P: Call enablePIP via MethodChannel
    P->>M: PipManager.enablePIP(streamID)
    M->>M: Check iOS version (>= 15.0)
    M->>M: Check device PIP support
    M->>M: Update PIP stream ID
    
    alt PIP controller exists and active
        M->>M: Stop current PIP
        M->>PC: stopPictureInPicture
        PC-->>M: PIP stopped
    end
    
    M->>VC: Create AVPictureInPictureVideoCallViewController
    M->>VC: Set aspect ratio (aspectWidth:aspectHeight)
    M->>M: Get Flutter video view
    M->>M: Create PIP content source
    M->>PC: Create AVPictureInPictureController
    M->>PC: Set delegate: self
    M->>KV: Create KitRemoteView
    M->>KV: Add to PIP call view controller
    M->>KV: Set auto layout constraints
    M->>KV: Create PIP display layer
    M->>KV: Add display layer to video view
    
    M->>PC: startPictureInPicture
    PC->>S: Request PIP mode
    S-->>PC: PIP mode activated
    PC->>M: pictureInPictureControllerDidStartPictureInPicture
    M-->>P: PIP enabled successfully
    P-->>F: Enable complete
```

## PIP Disable Flow

```mermaid
sequenceDiagram
    participant F as Flutter
    participant P as ZegoPipPlugin
    participant M as PipManager
    participant PC as AVPictureInPictureController
    participant S as System

    F->>F: ZegoPIP().stopPIP()
    F->>P: Call stopPIP via MethodChannel
    P->>M: PipManager.stopPIP()
    M->>M: Check iOS version (>= 15.0)
    M->>M: Check if in PIP mode
    
    alt In PIP mode
        M->>PC: stopPictureInPicture
        PC->>S: Request exit PIP mode
        S-->>PC: PIP mode deactivated
        PC->>M: pictureInPictureControllerDidStopPictureInPicture
        M->>M: Clean up PIP resources
        M-->>P: PIP stopped successfully
        P-->>F: Stop complete
    else Not in PIP mode
        M-->>P: Already not in PIP mode
        P-->>F: Stop complete
    end
```

## Video Rendering Flow

```mermaid
sequenceDiagram
    participant ZE as ZegoExpressEngine
    participant PM as PipManager
    participant FV as Flutter UIView
    participant ASL as AVSampleBufferDisplayLayer
    participant S as System Renderer

    ZE->>ZE: Receive video frame data
    ZE->>PM: onRemoteVideoFrameCVPixelBuffer callback
    PM->>PM: Check current PIP status
    
    alt PIP mode active
        PM->>ASL: Render to PIP display layer (pipLayer)
        ASL->>S: Display in PIP window
    else Normal mode
        PM->>FV: Get Flutter UIView
        PM->>ASL: Render to Flutter UIView's injected display layer
        ASL->>FV: Display via injected display layer
        FV->>S: Display in Flutter app interface
    end
```

## Error Handling Flow

```mermaid
graph TD
    A[Error Occurs] --> B{Error Type}
    
    B -->|Custom Rendering Error| C[Error Code 1011003]
    B -->|PIP Not Supported| D[iOS < 15.0]
    B -->|Device Not Supported| E[Device Limitations]
    B -->|Engine Error| F[ZegoExpressEngine Error]
    
    C --> G[_tryEnableCustomVideoRender]
    G --> H{Engine Status}
    H -->|Stopped| I[Re-enable Custom Rendering]
    H -->|Running| J[Wait for Engine Stop]
    J --> K[Add Status Listener]
    K --> L[Engine Stop Callback]
    L --> I
    
    D --> M[Show Version Warning]
    E --> N[Show Device Warning]
    F --> O[Engine Error Recovery]
    
    I --> P[Recovery Success]
    M --> Q[User Action Required]
    N --> Q
    O --> R[Engine Restart]
    
    P --> S[Continue Normal Flow]
    Q --> T[User Updates/Changes Device]
    R --> S
```

## State Management Flow

```mermaid
stateDiagram-v2
    [*] --> Uninitialized
    Uninitialized --> Initializing: ZegoPIP().init()
    Initializing --> Initialized: Init Success
    Initializing --> Error: Init Failed
    
    Initialized --> PIPEnabled: enable()
    Initialized --> BackgroundPIP: enableWhenBackground()
    
    PIPEnabled --> PIPActive: User Triggers PIP
    PIPActive --> PIPEnabled: User Exits PIP
    PIPActive --> AppMinimized: System Minimizes
    
    BackgroundPIP --> PIPActive: App Goes Background
    BackgroundPIP --> Initialized: cancelBackground()
    
    AppMinimized --> PIPActive: User Clicks PIP
    AppMinimized --> Initialized: User Closes PIP
    
    Error --> Uninitialized: Retry
    Initialized --> Uninitialized: uninit()
```

## Key Components Interaction

```mermaid
graph TB
    subgraph "Flutter Layer"
        A[ZegoPIP] --> B[ZegoPIPVideoView]
        B --> C[MethodChannel]
    end
    
    subgraph "iOS Plugin Layer"
        C --> D[ZegoPipPlugin]
        D --> E[PipManager]
    end
    
    subgraph "iOS System Layer"
        E --> F[AVPictureInPictureController]
        E --> G[AVPictureInPictureVideoCallViewController]
        E --> H[KitRemoteView]
        H --> I[AVSampleBufferDisplayLayer]
    end
    
    subgraph "ZEGO Engine Layer"
        E --> J[ZegoExpressEngine]
        J --> K[Custom Video Render Handler]
        K --> I
    end
    
    subgraph "System Services"
        F --> L[iOS PIP Service]
        G --> L
        I --> M[Hardware Accelerated Rendering]
    end
```

## Performance Optimization Points

### 1. **Memory Management**
- **Display Layer Reuse**: Reuse `AVSampleBufferDisplayLayer` instances
- **Buffer Pool**: Implement video buffer pooling
- **Resource Cleanup**: Proper cleanup when PIP is disabled

### 2. **Rendering Optimization**
- **Hardware Acceleration**: Use `AVSampleBufferDisplayLayer` for hardware acceleration
- **Frame Dropping**: Implement intelligent frame dropping for smooth playback
- **Resolution Scaling**: Dynamic resolution adjustment based on PIP window size

### 3. **Audio Session Management**
- **Background Audio**: Proper audio session configuration for background playback
- **Audio Interruption**: Handle audio interruption gracefully
- **Volume Control**: Maintain audio volume consistency

### 4. **Error Recovery**
- **Automatic Retry**: Implement automatic retry mechanisms
- **Graceful Degradation**: Fallback to normal mode if PIP fails
- **State Synchronization**: Keep Flutter and iOS states synchronized

## Debugging and Monitoring

### 1. **Log Points**
```objc
// Key logging points in PipManager.m
NSLog(@"[PipManager] PIP enabled for stream: %@", streamID);
NSLog(@"[PipManager] Custom rendering enabled: %@", isEnabled ? @"YES" : @"NO");
NSLog(@"[PipManager] PIP state changed: %ld", (long)state);
```

### 2. **State Monitoring**
- **PIP State**: Monitor `AVPictureInPictureController` state changes
- **Engine State**: Track `ZegoExpressEngine` status
- **Rendering State**: Monitor video rendering performance

### 3. **Performance Metrics**
- **Frame Rate**: Monitor video frame rendering rate
- **Memory Usage**: Track memory consumption
- **CPU Usage**: Monitor CPU utilization during PIP mode

## Best Practices

### 1. **Initialization Order**
1. Initialize Flutter binding
2. Initialize ZegoPIP with proper configuration
3. Create video views after initialization
4. Enable PIP functionality

### 2. **Error Handling**
1. Always check iOS version compatibility
2. Implement proper error recovery mechanisms
3. Provide user-friendly error messages
4. Log errors for debugging

### 3. **Resource Management**
1. Clean up resources when PIP is disabled
2. Handle app lifecycle changes properly
3. Manage audio session appropriately
4. Monitor memory usage

### 4. **User Experience**
1. Provide smooth transitions between modes
2. Maintain video quality in PIP mode
3. Handle user interactions gracefully
4. Provide clear feedback for state changes
