![pod version](https://img.shields.io/cocoapods/v/OpenWebRTC.svg) [![Badge w/ Platform](http://img.shields.io/cocoapods/p/OpenWebRTC.svg?style=flat)](https://cocoadocs.org/docsets/OpenWebRTC)

# OpenWebRTC iOS SDK
SDK for adding OpenWebRTC to your iOS apps using CocoaPods

## Installation

The SDK uses [CocoaPods](http://cocoapods.org) as library dependency manager. In order to set this up:

    sudo gem install cocoapods
    pod setup

The OpenWebRTC SDK is made up of 2 different pods:

* `OpenWebRTC` - Contains the pre-build framework `OpenWebRTC.framework`.
* `OpenWebRTC-SDK` - Contains helper classes for quickly developing native and hybrid apps. 

## Usage
Example Podfile:
```
platform :ios, '8.0'

target 'NativeDemo' do
    pod 'OpenWebRTC', '~> 0.1'
    pod 'OpenWebRTC-SDK',  :git => 'https://github.com/EricssonResearch/openwebrtc-ios-sdk.git'
end
```
or
```
platform :ios, '8.0'

target 'NativeDemo' do
    pod 'OpenWebRTC'
    pod 'OpenWebRTC-SDK', :path => '../../../openwebrtc-ios-sdk/OpenWebRTC-SDK.podspec'
end
```

## Examples
Apps that use the OpenWebRTC iOS SDK:
* [NativeDemo](https://github.com/EricssonResearch/openwebrtc-examples/tree/master/ios/NativeDemo)
* [Bowser](https://github.com/EricssonResearch/bowser)

## API
The entry point class for Native app developement is `OpenWebRTCNativeHandler`:

```
@protocol OpenWebRTCNativeHandlerDelegate <NSObject>

- (void)answerGenerated:(NSDictionary *)answer;
- (void)offerGenerated:(NSDictionary *)offer;
- (void)candidateGenerate:(NSString *)candidate;

/**
 * Format of sources:
 * [{'name':xxx, 'source':xxx, 'mediaType':'audio' or 'video'}, {}, ...]
 */
- (void)gotLocalSources:(NSArray *)sources;
- (void)gotRemoteSource:(NSDictionary *)source;

@end

@interface OpenWebRTCNativeHandler : NSObject

@property (nonatomic, weak) id <OpenWebRTCNativeHandlerDelegate> delegate;
@property (nonatomic, strong) OpenWebRTCSettings *settings;

- (instancetype)initWithDelegate:(id <OpenWebRTCNativeHandlerDelegate>)delegate;

- (void)setSelfView:(OpenWebRTCVideoView *)selfView;
- (void)setRemoteView:(OpenWebRTCVideoView *)remoteView;
- (void)addSTUNServerWithAddress:(NSString *)address port:(NSInteger)port;
- (void)addTURNServerWithAddress:(NSString *)address port:(NSInteger)port username:(NSString *)username password:(NSString *)password isTCP:(BOOL)isTCP;

- (void)startGetCaptureSourcesForAudio:(BOOL)audio video:(BOOL)video;
- (void)initiateCall;
- (void)terminateCall;

- (void)handleOfferReceived:(NSString *)offer;
- (void)handleAnswerReceived:(NSString *)answer;
- (void)handleRemoteCandidateReceived:(NSDictionary *)candidate;

- (void)setVideoCaptureSourceByName:(NSString *)name;
- (void)videoView:(OpenWebRTCVideoView *)videoView setVideoRotation:(NSInteger)degrees;
- (void)videoView:(OpenWebRTCVideoView *)videoView setMirrored:(BOOL)isMirrored;
- (NSInteger)rotationForVideoView:(OpenWebRTCVideoView *)videoView;

@end
```

## Change log
#### 0.3
New APIs for:
* Setting video capture device (camera)
* Setting and getting video rotation per video view
* Setting mirroring per video view

#### 0.2.1
* Minor changes to view handling for hybrid apps

#### 0.2.0
* Added classes for Hybrid (mixed native and WebView) app development
