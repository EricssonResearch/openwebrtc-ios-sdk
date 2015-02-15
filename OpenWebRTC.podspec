Pod::Spec.new do |s|
  s.name         = "OpenWebRTC"
  s.version      = "0.1"
  s.summary      = "SDK for adding OpenWebRTC to your iOS apps"
  s.homepage     = "http://www.openwebrtc.io"
  s.license      = { :type => "BSD-2", :file => "LICENSE" }
  s.author             = { "Ericsson Research" => "labs@ericsson.com" }
  s.social_media_url   = "http://twitter.com/OpenWebRTC"
  s.platform           = :ios, "8.0"
  s.source             = {
    :git => "https://github.com/EricssonResearch/openwebrtc-ios-sdk.git",
    :tag => "0.1"
  }
  s.source_files  = "SDK/*.{h,m}"
  
  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"
  s.requires_arc = true
end