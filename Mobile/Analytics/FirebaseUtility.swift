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

struct FirebaseUtility {
    /// Name of analytic event -> Mapped directly to Firebase
    enum Event: String {
        case errorNonFatal
        
        case login // done
        case keepMeSignedIn // done
        
        case autoPay
        case budgetBill
        case eBill
        case forgotPassword
        case forgotUsername
        case register
        case bill
        case payment
        case wallet
        case authOutage // done
        case unauthOutage // done
        case usage
        case more
        case biometricsToggle
        case contactUs
        case home
        case unauth
        case accountPicker
        case alerts
        
        
        
        case loginPageStart // done
        case loginTokenNetworkComplete
        case loginExchangeTokenNetworkComplete // done
        case loginAccountNetworkComplete // done
        case initialAuthenticatedScreenStart // done
        
        case changePasswordStart // done
        case changePasswordSubmit // done
        case changePasswordNetworkComplete // done
        
        case reportOutageStart // done
        case reportOutageSubmit // done
        case reportOutageNetworkComplete // done
        case makePaymentStart
        case makePaymentNext
        case reviewPaymentSubmit
        case paymentNetworkComplete
        case autoPayStart
        case autoPaySubmit
        case autoPayNetworkComplete
        case paperlessEBillStart
        case paperlessEBillSubmit
        case paperlessEBillNetworkComplete
        case budgetBillingStart
        case budgetBillingSubmit
        case budgetBillingNetworkComplete
        case homeProfileStart
        case homeProfileSubmit
        case homeProfileNetworkComplete
        case releaseOfInfoStart
        case releaseOfInfoSubmit
        case releaseOfInfoNetworkComplete
        case personalizeHomeStart
        case personalizeHomeComplete
    }
    
    /// Name of user property -> Mapped directly to Firebase
    enum UserProperty: String {
        case isKeepMeSignedInEnabled
        case isBiometricsEnabled
        
        case isControlGroup
        case customerType
        case serviceType
        
        case isScreenReaderEnabled
        case isSwitchAccessEnabled
        case fontScale
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
        #if DEBUG
        NSLog("📊 Firebase Event: \(event.rawValue)")
        #endif
        
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
        #if DEBUG
        NSLog("👤 Set User Property: \(userProperty.rawValue)")
        #endif
        
        Analytics.setUserProperty(value, forName: userProperty.rawValue)
    }
}


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
        
        case unenrolled_start
        case enroll_complete
        case enrolled_start
        case modify_complete
        case unenroll_complete
        case network_submit_error
        case settings_changed
        case modify_bank
        case learn_more
        case terms
        
        case complete
        
        case start
        case verification_complete
        case answer_question_start
        case answer_question_complete
        
        case offer
        case account_validation
        case account_setup
        case account_security_questions
        case account_complete
        case resend_email
        case ebill_enroll
        case account_verify
        
        case view_pdf
        case view_usage
        case launch_prepaid
        case history_view_more_upcoming_header
        case history_view_more_past_header
        case history_view_more_row
        case history_view_pdf
        
        case switch_payment_method
        case view_terms
        case submit
        
        case add_bank_start
        case add_card_start
        case add_bank_complete
        case add_card_complete
        case delete_payment_method
        case edit_payment_method
        case scan_with_camera
        
        case emergency_number
        case phone_number_main
        case phone_number_emergency_gas
        case phone_number_emergency_electric
        case view_details
        case report_complete
        case map
        case streetlight_map
        case account_number_help
        
        case electric_segment_press
        case gas_segment_press
        case next_graph_press
        case previous_graph_press
        case previous_bar_press
        case next_bar_press
        case projected_graph_press
        case factors_press
        case factor_bill_period_press
        case factor_weather_press
        case factor_other_press
        
        case strong_password_complete
        case change_password_complete
        case default_account_help
        case set_default_account_complete
        case billing_videos
        case release_of_info_complete
        case alert_preferences_complete
        case sign_out
        
        case press
        case account_change
        case expand_premise
        
        case online_form
        case customer_service_residential
        case customer_service_business
        case customer_service_tty_ttd
        case facebook
        case twitter
        case youtube
        case linkedin
        case flickr
        case instagram
        case pinterest
        
        case personalize_banner
        case personalize_button
        case personalize_complete
        case personalize_restore
        case bill_cta
        case bill_slide_to_pay
        case bil_choose_default_payment_method
        case bill_terms
        case bill_view_pdf
        case usage_cta
        case peak_rewards_cta
        case outage_cta
        case projected_bill_cta
        case projected_bill_electric_press
        case projected_bill_gas_press
        case usage_electric_press
        case usage_gas_press
        case usage_previous_graph_press
        case usage_next_graph_press
        case urgent_message_press
        
        case sign_in_register_press
        
        case pay_remind
        case english
        case spanish
        case main_screen
        case initial
        case initial_decline
        case initial_accept
        case opco_update
        case bill_enroll_push
        case bill_enroll_push_cancel
        case bill_enroll_push_continue
        case bill_unenroll_push
        case bill_unenroll_push_cancel
        case bill_unenroll_push_continue
        
        // Login
        case show_password // done
        case forgot_username_press // done
        case forgot_password_press // done
        case biometrics_press
    }
    
    let parameterName: Name
    
    // Should only be used with a name of `action`
    let value: Value?
    
    // Should only be used with a name of `value`
    let providedValue: String?
    
    init(parameterName: Name, value: Value?, providedValue: String? = nil) {
        self.parameterName = parameterName
        self.value = value
        self.providedValue = providedValue
    }
}
