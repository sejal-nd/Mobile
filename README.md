# Exelon Mobile iOS Application

## Targets

The project is configured such that Each Operating Company (OpCo) has its own
XCode target, and therefore a separate product. Source code that is shared between
OpCos is included in all targets. Source code that is OpCo specific is only
included in the specific target for that OpCo.

## Schemes

To support various development environments each Target has multiple schemes
- Development
- Testing
- Staging
- Production
- Automation

## Third Party Libraries

Third party libraries are managed using Cocoa Pods: https://github.com/CocoaPods/CocoaPods

SimpleKeychain is the only dependency directly integrated into the project: This can be found under Mobile->Vendor

**Libraries Used:**
- RXSwift
- RXCocoa
- RXGesture
- RXSwiftExt
- RXTest
- ModelMapper
- JVFloatLabeledTextField
- ToastSwift
- Zxcvbn
- Lottie
- JVFloatLabeledTextField
- ReachabilitySwift
- PDTSimpleCalendar
- Charts
- XLPagerTabStrip
- CardIO
- GoogleAnalytics
- Firebase
- AppCenter
