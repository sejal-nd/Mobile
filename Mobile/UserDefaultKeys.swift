//
//  UserDefaultKeys.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

struct UserDefaultKeys {
    
    static let hasRunBefore = "kHasRunBefore"
    
    // Terms & Policies
    static let hasAcceptedTerms = "kHasAcceptedTerms" // Used to determine whether or not to display the Terms screen on first app launch
    
    // Touch/Face ID
    static let isBiometricsEnabled = "kBiometricsEnabled"
    static let shouldPromptToEnableBiometrics = "kShouldPromptToEnableBiometrics" // Should we prompt the user to enable Touch/Face ID after a successful login?
    static let loggedInUsername = "kLoggedInUsername" // The username of the currently logged in user
    
    static let customerIdentifier = "kCustomerIdentifier" // Persist Customer Identifer (from login) to disk
    
    static let paymentDetailsDictionary = "kPaymentDetailsDictionary"
    static let reportedOutagesDictionary = "kReportedOutagesDictionary"
    static let commercialUsageAlertSeen = "kCommercialUsageAlertSeen"
    
    static let temperatureScale = "kPTemperatureScale"
    
    static let homeCardCustomizeTappedVersion = "kHomeCardCustomizeTappedVersion"
    static let homeCardPrefsList = "kHomeCardPrefsList"
    
    static let inMainApp = "kInMainApp" // Is the user in the "Main" area of the app (past-login). Set to true in MainTabBarController
    
    static let appRatingEventCount = "kAppRatingEventCount" // Used by AppRating to track number of events that contribute to a rating prompt
    
    static let pushNotificationReceived = "kPushNotificationReceived"
    static let pushNotificationReceivedTimestamp = "kPushNotificationReceivedTimestamp"
    
    static let isInitialPushNotificationPermissionsWorkflowCompleted = "kInitialPushNotificationPermissionsWorkflowCompleted"

    static let usernamesRegisteredForPushNotifications = "kUsernamesRegisteredForPushNotifications"
    
    static let accountVerificationDeepLinkGuid = "kAccountVerificationDeepLinkGuid"
    
    static let isKeepMeSignedInChecked = "kIsKeepMeSignedInChecked"
    
    static let doNotShowIOS9VersionWarningAgain = "kdoNotShowIOS9VersionWarningAgain" // True if iOS 9 user selects "Don't warn me again" on alert
    
    // Gamification
    static let prefersGameHome = "kPrefersGameHome"
    static let gameAccountNumber = "kGamificationAccountNumber"
    static let gameOptedOutLocal = "kGameOptedOutLocal"
    static let gameOnboardingCompleteLocal = "kGameOnboardingCompleteLocal"
    static let gamePointsLocal = "kGamePointsLocal"
    static let gameSelectedBackground = "kGameSelectedBackground"
    static let gameSelectedHat = "kGameSelectedHat"
    static let gameSelectedAccessory = "kGameSelectedAccessory"
    static let gameLastTaskDate = "kGameLastTaskDate"
    static let gameEnergyBuddyUpdatesAlertPreference = "kGameEnergyBuddyUpdatesAlertPref"
}
