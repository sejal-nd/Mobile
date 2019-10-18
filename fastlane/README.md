fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios screenshots
```
fastlane ios screenshots
```
Generate new localized screenshots -> Increment version number -> setup certs + profiles -> Create IPA -> Upload dSYMs -> Upload to App Store
### ios uploadBuild
```
fastlane ios uploadBuild
```

### ios refresh_dsyms
```
fastlane ios refresh_dsyms
```
Refresh DSYMS

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
