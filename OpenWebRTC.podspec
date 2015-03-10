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
  s.preserve_paths = "OpenWebRTC.framework"
  s.public_header_files = "OpenWebRTC.framework/**/*.h"
  s.vendored_frameworks = "OpenWebRTC.framework"
  s.header_mappings_dir = "OpenWebRTC.framework"
  #s.libraries = "c++", "iconv", "resolve", "z"
  s.requires_arc = false
end