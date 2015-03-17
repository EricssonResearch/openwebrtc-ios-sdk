# OpenWebRTC iOS SDK
SDK for adding OpenWebRTC to your iOS apps using CocoaPods 


## Installation

The SDK uses [CocoaPods](http://cocoapods.org) as library dependency manager. In order to set this up:

    sudo gem install cocoapods
    pod setup

The best way to add the OpenWebRTC SDK to your application project is to add the OpenWebRTC dependency to your Podfile:

    pod 'OpenWebRTC'

## Fix Header Search Path
After every run of `pod install` you need to _manually_ add the following to Header Search Paths:
* `"${PODS_ROOT}/OpenWebRTC/OpenWebRTC_framework_0.1/OpenWebRTC.framework/Headers"` (recursive)

Note that the version (0.1 in the example above) should match the version of the OpenWebRTC pod you are currently installing.

## Overview

As a quick overview, there are the classes to know to use the SDK.

## Usage
