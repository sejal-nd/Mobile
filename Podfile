inhibit_all_warnings! # ignore all warnings from all pods

def shared_pods # Shared in both iOS and WatchOS
  pod 'RxSwift', '4.5.0'
  pod 'ModelMapper', '10.0.0'
end

def iOS_pods
  pod 'lottie-ios', '2.5.3'
  pod 'JVFloatLabeledTextField', '1.2.1'
  pod 'Toast-Swift', '5.0.0'
  pod 'zxcvbn-ios', '1.0.4'
  pod 'ReachabilitySwift', '4.3.1'
  pod 'RxSwiftExt', '3.4.0'
  pod 'RxSwiftExt/RxCocoa', '3.4.0'
  pod 'PDTSimpleCalendar', '0.9.1'
  pod 'Charts', '3.3'
  pod 'XLPagerTabStrip', '9.0.0'
  pod 'GoogleAnalytics', '3.17.0'
  pod 'Firebase/Core', '5.19.0'
  pod 'AppCenter', '1.14'
end

def iOS_UnitTestPods
  pod 'RxTest', '4.5.0'
end

def iOS_UITestPods
  pod 'AppCenterXCUITestExtensions', '1.0'
end

abstract_target 'BGEApp' do
    platform :ios, '10.0'
    use_frameworks!

    iOS_pods
    shared_pods

    target 'BGE' do
    end

    target 'BGEUnitTests' do
        iOS_UnitTestPods
    end

    target 'BGEUITests' do
        iOS_UITestPods
    end
end

abstract_target 'ComEdApp' do
    platform :ios, '10.0'
    use_frameworks!

    iOS_pods
    shared_pods

    target 'ComEd' do
    end

    target 'ComEdUnitTests' do
        iOS_UnitTestPods
    end

    target 'ComEdUITests' do
        iOS_UITestPods
    end
end

abstract_target 'PECOApp' do
    platform :ios, '10.0'
    use_frameworks!

    iOS_pods
    shared_pods

    target 'PECO' do
    end

    target 'PECOUnitTests' do
        iOS_UnitTestPods
    end

    target 'PECOUITests' do
        iOS_UITestPods
    end
end

target 'PECO_WatchOS' do
  platform :watchos, '4.0'
  use_frameworks!
end

target 'PECO_WatchOS Extension' do
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
        if config.name == 'Release'
            config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
        end
    end
end
