//
//  FirebaseUtility.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/11/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import FirebaseAnalytics
import Firebase
import Foundation

/// Event name + event value -> Mapped to dict before being send to Firebase
///
/// - Note: Only one parameter should have a value between `value` and `providedValue`.  If both have a value, `providedValue` takes precendence.
struct EventParameter {
    enum Name: String {
        case action
        case value
    }
    
    enum Value: String {
        case errorCode
        case screenName
        
        // Login
        case show_password
        case forgot_username_press
        case forgot_password_press
        
        // keepMeSignedIn Toggle
        case isOn
    }
    
    let parameterName: Name
    let value: Value?
    let providedValue: String?
    
    init(parameterName: Name, value: Value?, providedValue: String? = nil) {
        self.parameterName = parameterName
        self.value = value
        self.providedValue = providedValue
    }
}

struct FirebaseUtility {
    /// Name of analytic event -> Mapped directly to Firebase
    enum Event: String {
        case errorNonFatal
        
        case login // done
        case keepMeSignedIn // done
        case loginPageStart
        case loginTokenNetworkComplete
        case loginExchangeTokenNetworkComplete
        case loginAccountNetworkComplete
        case loginAccountDetailsNetworkComplete
        case initialAuthenticatedScreenStart
        
        case changePasswordStart
        case changePasswordSubmit
        case changePasswordNetworkComplete
    }
    
    /// Name of user property -> Mapped directly to Firebase
    enum UserProperty: String {
        case isKeepMeSignedInEnabled
        case isBiometricsEnabled
    }
    
    /// This method should only be called once from App Delegate: Configures Firebase
    public static func configure() {
        guard let filePath = Bundle.main.path(forResource: Environment.shared.firebaseConfigFile, ofType: "plist"),
            let fileopts = FirebaseOptions(contentsOfFile: filePath) else {
                return dLog("Failed to load Firebase Analytics")
        }
        
        FirebaseApp.configure(options: fileopts)
    }
    
    /// Log an event to be sent to Firebase
    ///
    /// - Parameters:
    ///   - event: Name of the event being sent to Firebase
    ///   - parameters: Dict of parameters to be sent along with the event name
    public static func logEvent(_ event: Event, parameters: [EventParameter]? = nil) {
        // Convert Event Parameter into dict if it exists
        let parametersDict = parameters?.reduce([String: Any]()) { (dict, eventParameter) -> [String: Any] in
            var dict = dict
            
            if let providedValue = eventParameter.providedValue {
                dict[eventParameter.parameterName.rawValue] = providedValue
            } else if let value = eventParameter.value {
                dict[eventParameter.parameterName.rawValue] = value.rawValue
            } else {
                return [:]
            }
            
            return dict
        }

        Analytics.logEvent(event.rawValue, parameters: parametersDict)
    }
    
    /// Sets a User Propetry on the current user, all future events are auto tagged with User Properties
    ///
    /// - Parameters:
    ///   - userProperty: Name of the user property
    ///   - value: `String` value of property
    public static func setUserPropety(_ userProperty: UserProperty, value: String? = nil) {
        Analytics.setUserProperty(value, forName: userProperty.rawValue)
    }
}
