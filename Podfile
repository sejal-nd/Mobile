inhibit_all_warnings! # ignore all warnings from all pods

def shared_pods # Shared in both iOS and WatchOS
  pod 'RxSwift', '5.1.0'
  pod 'RxSwiftExt', '5.2.0'
end

def iOS_pods
  pod 'lottie-ios', '3.1.5'
  pod 'Toast-Swift', '5.0.0'
  pod 'zxcvbn-ios', '1.0.4'
  pod 'ReachabilitySwift', '4.3.1'
  pod 'RxSwiftExt/RxCocoa', '5.2.0'
  pod 'PDTSimpleCalendar', '0.9.1'
  pod 'Charts', '3.3'
  pod 'XLPagerTabStrip', '9.0.0'
  pod 'GoogleAnalytics', '3.17.0'
  pod 'Firebase/Core', '5.19.0'
  pod 'Firebase/RemoteConfig'
  pod 'AppCenter', '1.14'
end

def iOS_UnitTestPods
  pod 'RxTest', '5.1.0'
end

def iOS_UITestPods
  
end

target 'EUMobile' do
  platform :ios, '12.0'
  use_frameworks!
  iOS_pods
  shared_pods
end

target 'EUMobileUnitTests' do
  platform :ios, '12.0'
  use_frameworks!
    iOS_UnitTestPods
    iOS_pods
    shared_pods
end

target 'EUMobileUITests' do
  platform :ios, '12.0'
  use_frameworks!
    iOS_UITestPods
    iOS_pods
    shared_pods
end

target 'EUMobile-Watch' do
  platform :watchos, '4.0'
  use_frameworks!
end

target 'EUMobile-Watch Extension' do
  platform :watchos, '4.0'
  use_frameworks!

  shared_pods
end

# Removes the project warnings after a `pod install`
post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        # Force the main pods frameworks to Swift 5.0
        config.build_settings['SWIFT_VERSION'] = '5.0'
        # Fix localization warning in Xcode 10.2
        config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
    end
end
