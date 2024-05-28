workspace 'PubNub'
use_frameworks!

platform :ios, '15.0'

target 'PubNubContractTests' do
  # pod 'Cucumberish', :git => 'https://github.com/parfeon/Cucumberish.git', :branch => 'master', :inhibit_warnings => true
  pod 'Cucumberish'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'Cucumberish'
        target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        end
      end
    end
  end
end

target 'PubNubContractTestsBeta' do
  # pod 'Cucumberish', :git => 'https://github.com/parfeon/Cucumberish.git', :branch => 'master', :inhibit_warnings => true
  pod 'Cucumberish'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'Cucumberish'
        target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        end
      end
    end
  end
end