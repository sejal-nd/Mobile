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

This is geared towards running on Azure DevOps. Fastlane is used for the .ipa file delivery to Apple.

## iOS

### Authentication

Fastlane authenticates using a json file `App_Store_Connect_API_Key.json` which contains an App Store Connect API key.  This file is stored in Azure DevOps secure files and is downloaded in a task where its directory is then passed to Fastlane.

### ios uploadBuild


Upload a pre-built IPA to the App Store. This is setup to run in the context of an Azure DevOps release definition.

For Example:
```
fastlane uploadBuild bundle_id:com.ifactorconsulting.ace ipa_path:EUMobile.ipa api_key_path:App_Store_Connect_API_Key.json --verbose
```
