Pod::Spec.new do |s|
  s.name         = "OpenWebRTC"
  s.version      = "0.1"
  s.summary      = "OpenWebRTC.framework wrapped in CocoaPod"
  s.homepage     = "http://www.openwebrtc.io"
  s.license      = { :type => "BSD-2", :file => "LICENSE" }
  s.author       = { "Ericsson AB" => "labs@ericsson.com" }
  s.platform     = :ios, "7.1"

  ## TESTING
  #s.source       = { :path => "OpenWebRTC.framework" }
  #s.public_header_files = "OpenWebRTC.framework/**/*.h"
  #s.vendored_frameworks = "OpenWebRTC.framework"
  #s.header_mappings_dir = "OpenWebRTC.framework"

  ## FOR RELEASE
  s.source = { :http => "http://static.verkstad.net/OpenWebRTC_framework_#{s.version}.zip" }
  s.preserve_paths = "OpenWebRTC_framework_#{s.version}/*.framework"
  s.public_header_files = "OpenWebRTC_framework_#{s.version}/OpenWebRTC.framework/**/*.h"
  s.vendored_frameworks = "OpenWebRTC_framework_#{s.version}/OpenWebRTC.framework"

  s.frameworks = "JavaScriptCore", "VideoToolbox", "AssetsLibrary", "CoreVideo", "CoreAudio", "CoreGraphics", "OpenGLES", "OpenWebRTC"
  s.libraries = "c++", "iconv", "resolve"
  s.requires_arc = false
end