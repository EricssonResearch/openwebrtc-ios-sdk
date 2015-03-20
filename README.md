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
* `OpenWebRTC-SDK` - Contains helper classes for quickly developing native apps. Currently available only as a Development Pod, meaning that you need need to reference its location by `:path` (example below).

*WARNING!* There are remaing issues in the .podspec's that requires you to _manually_ fix a few things in your Xcode workspace, see below. We hope to sort these out ASAP. If you have an idea of what might be wrong, let us know!

## Fix Header Search Path
After every run of `pod install` you need to _manually_ add the following to Header Search Paths:
* `"${PODS_ROOT}/OpenWebRTC/OpenWebRTC_framework_0.1/OpenWebRTC.framework/Headers"` (recursive)

Note that the version (0.1 in the example above) should match the version of the OpenWebRTC pod you are currently installing.

## Usage
Example Podfile:
```
platform :ios, '8.0'

target 'NativeDemo' do
    pod 'OpenWebRTC', '~> 0.1'
    pod 'OpenWebRTC-SDK', :path => '../../../openwebrtc-ios-sdk/OpenWebRTC-SDK.podspec'
end
```

## Overview

As a quick overview, there are the classes to know to use the SDK.
