workspace 'PubNub'
use_frameworks!

target 'PubNubContractTests' do
  platform :ios, '11.0'

  pod 'Cucumberish', :inhibit_warnings => true
end

target 'PubNubContractTestsBeta' do
  platform :ios, '11.0'
  
  pod 'Cucumberish', :inhibit_warnings => true
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
      next unless target.name =~ /Cucumberish/
      target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      end
  end
end