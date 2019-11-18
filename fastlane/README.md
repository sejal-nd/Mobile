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

This is geared towards running on Azure DevOps, slotting into the existing build architecture where our build script in `tools/ios-build.sh` handles the majority of the process first. Fastlane is used for generation of screenshots, delivery to Apple, and syncing dSYMs from Apple over to App Center.

## iOS

### Opco environments

For any fastlane command, you will need to specify the `--env opco` flag to specify which opco. These are lower case, so use `bge`, `comed`, or `peco`

### Apple Developer Account

Currently this is hardcoded to use the user ID `E20600@exelonds.com`, for which the password is stored on Azure DevOps only. This is Peter Harris' other developer account. If you need to test something, swap your own account in in the Fastfile. Preferably use an account without 2FA turned on.

### ios screenshots

Compiles the app and runs the [OPCO]-AUT-Fastlane scheme, which consists of the `ScreenshotsUITests` script. There are several `snapshot` calls in this script to capture the various screenshots. Tweak this file to take different screenshots or change the order. (Note they are labled 01Home, 02Bill, etc to make sure they are in order alphabetically.)

The device set for screenshots is configured in the `Snapfile`, currently set to:

* iPhone 8 Plus
* iPhone 11 Pro Max
* iPad Pro (12.9-inch) (3rd generation)

Run the command with:

```
fastlane screenshots --env opco
```

### ios uploadBuild


Upload a pre-built IPA to the App Store. This is setup to run in the context of an Azure DevOps release definition, so it makes some assumptions about where files are. For example, here: https://dev.azure.com/exelontfs/EU-mobile/_release?_a=releases&view=mine&definitionId=8

Key assumptions:

* Another process has already built and sign the IPA file -- namely our `tools/ios-build.sh` script that is kicked off as part of the pull request flow.
* Those assets are available in a `build` folder, next to the `repo` clone
* The exact path is per opco, see the .env.opco files

```
fastlane uploadBuild --env opco
```

### ios refresh_dsyms

Designed to sync dSYMs from Apple over to App Center for crash analysis

```
fastlane refresh_dsyms --env opco
```
