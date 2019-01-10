platform :ios, '10.0'

# Shared in both iOS and WatchOS
def shared_pods
  pod 'RxSwift',    '4.3.1'
  pod "ModelMapper",    '9.0.0'
end

def iOS_pods
  pod "lottie-ios",     '2.0.3'
  pod "JVFloatLabeledTextField",     '1.2.1'
  pod "Toast-Swift", '4.0.0'
  pod "zxcvbn-ios", '1.0.4'
  pod 'ReachabilitySwift', '4.2.1'
  pod 'RxSwiftExt', '3.3.0'
  pod 'PDTSimpleCalendar', '0.9.1'
  pod 'Charts', '3.2.0'
  pod "RxGesture", '2.0.1'
  pod 'XLPagerTabStrip'
  pod 'AppCenterXCUITestExtensions', '1.0'
end

target 'BGE' do
  use_frameworks!

  iOS_pods
  shared_pods

  target 'BGEUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'BGEUnitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'ComEd' do
  use_frameworks!

  iOS_pods
  shared_pods

  target 'ComEdUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'ComEdUnitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'PECO' do
  use_frameworks!

  iOS_pods
  shared_pods

  target 'PECOUITests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'PECOUnitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'PECO_WatchOS' do
  use_frameworks!

  # Pods for PECO_WatchOS
end

target 'PECO_WatchOS Extension' do
  use_frameworks!

  shared_pods

end
