inhibit_all_warnings! # ignore all warnings from all pods

def shared_pods # Shared in both iOS and WatchOS
  pod 'RxSwift', '5.1.0' # TODO MANUAL
  pod 'RxSwiftExt', '5.2.0' # TODO MANUAL
end

source 'https://github.com/DecibelInsight/decibel-sdk-ios-spec'
source 'https://github.com/CocoaPods/Specs.git'

def iOS_pods
  pod 'RxSwiftExt/RxCocoa', '5.2.0' # TODO MANUAL
  pod 'DecibelSDK' # TODO Need to manually integrate
end

def iOS_UnitTestPods

end

def iOS_UITestPods

end

target 'EUMobile' do
  platform :ios, '14.1'
  use_frameworks!
  iOS_pods
  shared_pods
end

target 'UnitTests' do
  platform :ios, '14.1'
  use_frameworks!
    iOS_UnitTestPods
    iOS_pods
    shared_pods
end

target 'UITests' do
  platform :ios, '14.1'
  use_frameworks!
    iOS_UITestPods
    iOS_pods
    shared_pods
end

target 'EUMobile-Watch' do
  platform :watchos, '7.0'
  use_frameworks!
end

target 'EUMobile-Watch Extension' do
  platform :watchos, '7.0'
  use_frameworks!

  shared_pods
end

post_install do |installer|
  # Removes the project warnings after a `pod install`
  installer.pods_project.build_configurations.each do |config|
    # Force the main pods frameworks to Swift 5.0
    config.build_settings['SWIFT_VERSION'] = '5.0'
    # Fix localization warning in Xcode 10.2
    config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
  end

  # Set IPHONEOS_DEPLOYMENT_TARGET to 11.0 for all pod projects
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      end
    end
  end
end
