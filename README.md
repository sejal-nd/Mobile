# Exelon Mobile iOS Application

## Installation

**Requirements**
- Xcode: 15.0.1
- [Github](https://www.github.com) account signed in to Xcode.

**Instructions**
In order for the project to fetch its dependencies you must first log in to your github account on Xcode.  In addition to this you must also clone the repo from Azure DevOps via SSH. Please follow the steps below which are current as of Xcode 15.0.1:

**Cloning Repo via Azure Devops SSH Key**
To use SSH authentication with Azure DevOps you should follow [this guide](https://learn.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops)

Note: Without Azure DevOps SSH setup the project will not be able to fetch its internal dependencies via SPM.

**Log in to Github Account in Xcode**
Note: If you do not have a github account, create one using your exelon email.  This github account does not need any special permissions.  IT is solely used for open source repositorys.

1. Navigate to Xcode -> Settings... -> Accounts
2. Press the `+` button in the bottom left
3. Select `Github`
4. Enter your [Github](https://www.github.com) email address
5. Generate a PAT on [Github](https://www.github.com) with the permissions that Xcode specifies on that page
6. Paste that PAT into the Xcode prompt
7. Select the account you just added to Xcode in the list to the left
8. Change the `Clone using:` option to `ssh`
9. Generate a `id_ed25519` SSH key.  If you need help please see [this guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
10. Once generated add this SSH key to [Github](https://www.github.com)
11. Select this SSH key in the `SSH Key:` Xcode dropdown menu.
12. Quit Xcode, reopen and the project should now automatically fetch dependencies.

## Configurations

The project is configured such that Each Operating Company (OpCo) as well as each environment tier has its own
Xcode configuration, and therefore a separate scheme.

Each configuration defines specific values within the project target build settings which dictate everything about differnt tiers and OpCos.  These values are managed via xcconfig files stored in the tools folder.

## Schemes

To support various development environments each OpCo has multiple schemes
- Automation (AUT)
- Beta
- ReleaseCandidate (RC)
- Release

## Project URL Path

Navigate to the Debug Menu on the landing screen then select the desired project in the `Project URL Suffix` menu.  Then restart the app using the `Save & Restart App` button.

## Git Branching Strategy

The Git Branching strategy can be found at the following URL:
https://exelontfs.visualstudio.com/EU-mobile/_wiki/wikis/EU-mobile.wiki/1386/Git-Branching-Strategy

## Third Party Libraries

Third party libraries are primarily managed using SPM - [Swift Package Manager] (https://github.com/apple/swift-package-manager), in the event that a library needs modification it is integrated directly into the project (Mobile/Vender...).  When neccisary third party libraries are integrated via XCFrameworks, which allows for closed source code to be added to the project supporting multiple platforms.

**Libraries Integrated Directly:**
- SimpleKeychain

**Libraries Integrated Via XCFrameworks:**
- Decibel
- Firebase
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

Note: You must be logged in to a [Github](https://www.github.com) account for the Swift Packages to load.
