# Exelon Mobile iOS Application

## Installation
**Requirements**
- Xcode: 10.1
- Cocoa Pods: 1.5.3
After a fresh `git clone` from the "Exelon_Mobile_iOS" repository, open a terminal at the root project folder and run `pod install`.  Following this open the project workspace named: "Mobile.xcworkspace", the project is now open and working.

## Configurations

The project is configured such that Each Operating Company (OpCo) as well as each environment tier has its own
Xcode configuration, and therefore a separate scheme.

Each configuration defines specific values within the project target build settings which dictate everything about differnt tiers and OpCos.

## Schemes

To support various development environments each OpCo has multiple schemes
- Automation
- Testing
- Staging
- ProdBeta
- Production

## Project URL Path

Navigate to the Debug Menu on the landing screen then select the desired project in the `Project URL Suffix` menu.  Then restart the app.

| Git Branch   |    URL Prefix                        |
| -------------- | ------------------------------- |
|   phi/             |    /phimobile                        |
|   billing/        |    /billing                               |
|   payments/  |    /paymentenhancements  |
|   mma/          |    /manage-my-account      |
|   hotfix/         |    /hotfix                               |

## Third Party Libraries

Third party libraries are primarily managed using Cocoa Pods (https://github.com/CocoaPods/CocoaPods), in the event that a library needs modification it is integrated directly into the project (Mobile/Vender...)

**Libraries Integrated Directly:**
- SimpleKeychain

**Libraries Managed By Cocoa Pods:**
- RXSwift
- RXCocoa
- RXSwiftExt
- RXTest
- ToastSwift
- Zxcvbn
- Lottie
- JVFloatLabeledTextField
- ReachabilitySwift
- PDTSimpleCalendar
- Charts
- XLPagerTabStrip
- GoogleAnalytics
- Firebase
- AppCenter
- Survery Monkey
