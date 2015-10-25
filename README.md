# WARNING! Work in progress, breaking changes ahead :)
![pod version](https://img.shields.io/cocoapods/v/OpenWebRTC.svg) [![Badge w/ Platform](http://img.shields.io/cocoapods/p/OpenWebRTC.svg?style=flat)](https://cocoadocs.org/docsets/OpenWebRTC)

# [WIP] OpenWebRTC iOS SDK
SDK for adding OpenWebRTC to your iOS apps using CocoaPods


## Installation

The SDK uses [CocoaPods](http://cocoapods.org) as library dependency manager. In order to set this up:

    sudo gem install cocoapods
    pod setup

The OpenWebRTC SDK is made up of 2 different pods:

* `OpenWebRTC` - Contains the pre-build framework `OpenWebRTC.framework`.
* `OpenWebRTC-SDK` - Contains helper classes for quickly developing native and hybrid apps. 

## CocoaPods > 0.38.2 problems
There is currently a [problem](https://github.com/EricssonResearch/openwebrtc-ios-sdk/issues/30) with versions of CocoaPods that are newer than `0.38.2`. If you are on a newer version, e.g. `0.39.0`, one solution is to downgrade your installation:
```
sudo gem install cocoapods -v 0.38.2
```

## Usage
Example Podfile:
```
platform :ios, '8.0'

target 'NativeDemo' do
    pod 'OpenWebRTC', '~> 0.1'
    pod 'OpenWebRTC-SDK', :path => '../../../openwebrtc-ios-sdk/OpenWebRTC-SDK.podspec'
end
```

## Change log
#### 0.2.1
* Minor changes to view handling for hybrid apps

#### 0.2.0
* Added classes for Hybrid (mixed native and WebView) app development
