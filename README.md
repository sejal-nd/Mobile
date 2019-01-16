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

Third party libraries are primarily managed using Cocoa Pods (https://github.com/CocoaPods/CocoaPods), in the event that a library needs modification it is integrated directly into the project (Mobile/Vender...)

**Libraries Integrated Directly:**
- SimpleKeychain

**Libraries Managed By Cocoa Pods:**
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
