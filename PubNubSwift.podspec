Pod::Spec.new do |s|
  s.name     = 'PubNubSwift'
  s.version  = '7.1.0'
  s.homepage = 'https://github.com/pubnub/swift'
  s.documentation_url = 'https://www.pubnub.com/docs/swift-native/pubnub-swift-sdk'
  s.authors = { 'PubNub, Inc.' => 'support@pubnub.com' }
  s.social_media_url = 'https://twitter.com/pubnub'
  s.license = { :type => 'PubNub Software Development Kit License', :file => 'LICENSE' }
  s.source = { :git => 'https://github.com/pubnub/swift.git', :tag => s.version }
  s.summary = 'PubNub Swift-based SDK for iOS, macOS, tvOS, & watchOS'
  s.description = <<-DESC

The PubNub Real-Time Network. Build real-time apps quickly and scale them globally.

                  DESC

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '4.0'

  s.swift_version = '5.0'

  s.module_name = 'PubNub'
  s.source_files = 'Sources/**/*.swift'

  if defined?($PubNubAsStaticFramework)
    Pod::UI.puts "#{s.name}: Using overridden static_framework value of '#{$PubNubAsStaticFramework}'"
    s.static_framework = $PubNubAsStaticFramework
  else
    s.static_framework = false
  end
end
