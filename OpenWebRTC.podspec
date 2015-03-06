Pod::Spec.new do |s|
  s.name         = "OpenWebRTC"
  s.version      = "0.1"
  s.summary      = "SDK for adding WebRTC to your app through OpenWebRTC"
  s.homepage     = "http://www.openwebrtc.io"
  s.license      = { :type => "BSD-2", :file => "LICENSE" }
  s.author       = { "Ericsson AB" => "labs@ericsson.com" }
  s.platform     = :ios, "7.1"
  s.source       = {
    :git => "https://github.com/EricssonResearch/openwebrtc-ios-sdk.git",
    :tag => "0.1"
  }
  s.source_files = "SDK/*.{h,m}"
  
  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"
  s.requires_arc = true
end