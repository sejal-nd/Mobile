//
//  UserDefaultKeys.swift
//  Mobile
//
//  Created by Marc Shilling on 2/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

struct UserDefaultKeys {
    
    // Terms & Policies
    static let HasAcceptedTerms = "kHasAcceptedTerms" // Used to determine whether or not to display the Terms screen on first app launch
    
    // Touch ID
    static let TouchIDEnabled = "kTouchIDEnabled"
    static let ShouldPromptToEnableTouchID = "kShouldPromptToEnableTouchID" // Should we prompt the user to enable Touch ID after a successful login?
    static let LoggedInUsername = "kLoggedInUsername" // The username of the currently logged in user
    
    // Persist Customer Identifer (from login) to disk
    static let CustomerIdentifier = "kCustomerIdentifier"
    
    static let PaymentDetailsDictionary = "kPaymentDetailsDictionary"
    
    static let InMainApp = "kInMainApp" // Is the user in the "Main" area of the app (past-login). Set to true in MainTabBarController
}
