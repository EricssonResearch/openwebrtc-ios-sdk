Pod::Spec.new do |s|
  s.name         = "OpenWebRTC"
  s.version      = "1.0"
  s.summary      = "OpenWebRTC.framework wrapped in CocoaPod"
  s.homepage     = "http://www.openwebrtc.io"
  s.license      = { :type => "BSD-2", :file => "LICENSE" }
  s.author       = { "Ericsson AB" => "labs@ericsson.com" }
  s.source       = { :path => "OpenWebRTC.framework" }
  s.platform     = :ios, "7.1"
  s.frameworks   = "VideoToolbox", "AssetsLibrary"
  s.library      = "z"
  ######s.xcconfig     =  { "FRAMEWORK_SEARCH_PATHS" => '"$(PODS_ROOT)/OpenWebRTC"' }
  ######s.preserve_paths = "NewRelic_iOS_Agent_#{s.version}/*.framework"
  ######s.public_header_files = "NewRelic_iOS_Agent_#{s.version}/NewRelicAgent.framework/**/*.h"
  ######s.vendored_frameworks = "NewRelic_iOS_Agent_#{s.version}/NewRelicAgent.framework"
  s.preserve_paths = "*.framework/Headers/**"
  s.public_header_files = "OpenWebRTC.framework/**/*.h"
  s.vendored_frameworks = "OpenWebRTC.framework"
  s.xcconfig = { 'LIBRARY_SEARCH_PATHS' => '$(PODS_ROOT)/OpenWebRTC/' }
  s.requires_arc = false
end