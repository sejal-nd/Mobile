Exelon Mobile iOS Application


Targets
------------

The project is configured such that Each Operating Company (OpCo) has its own
XCode target, and therefore a seperate product. Source code that is shared between
OpCos is included in all targets. Source code that is OpCo specific is only
included in the specific target for that OpCo.

Schemes
----------------

To support various development environments each Target has multiple schemes
- Development
- Testing
- Staging
- Production
- Automation

Third Party Libraries
----------------------

Third party libraries are managed using Carthage: https://github.com/Carthage/Carthage

Libraries Used:
- RXSwift
- RXCocoa
- JVFloatLabeledTextField
- ToastSwift
- Zxcvbn
- Lottie
- HockeySDK
