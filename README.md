# Exelon Mobile iOS Application

## Installation
**Requirements**
- Xcode: 13.3.1

## Configurations

The project is configured such that Each Operating Company (OpCo) as well as each environment tier has its own
Xcode configuration, and therefore a separate scheme.

Each configuration defines specific values within the project target build settings which dictate everything about differnt tiers and OpCos.  These values are managed via xcconfig files stored in the tools folder.

## Schemes

To support various development environments each OpCo has multiple schemes
- Automation
- Beta
- ReleaseCandidate
- Release

## Project URL Path

Navigate to the Debug Menu on the landing screen then select the desired project in the `Project URL Suffix` menu.  Then restart the app.

## Git Branching Strategy

The GIT Branching strategy can be found in the URL :

https://exelontfs.visualstudio.com/EU-mobile/_wiki/wikis/EU-mobile.wiki/1386/Git-Branching-Strategy

## Third Party Libraries

Third party libraries are primarily managed using SPM - [Swift Package Manager] (https://github.com/apple/swift-package-manager), in the event that a library needs modification it is integrated directly into the project (Mobile/Vender...).  When neccisary third party libraries are integrated via XCFrameworks, which allow for closed source code added to the project supporting multiple platforms.

**Libraries Integrated Directly:**
- SimpleKeychain

**Libraries Integrated Via XCFrameworks:**
- Decibel
- RXCocoa
- RxRelay
- RXSwift
- RXSwiftExt

**Libraries Managed By Swift Package Manager:**
- Toast
- Lottie
- Reachability
- HorizonCalendar
- Charts
- XLPagerTabStrip
- AppCenter
- MedalliaDigialSDK
- Firebase
