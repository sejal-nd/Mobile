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
        case watch
        
        case errorNonFatal
        
        case login
        
        case autoPay
        case budgetBill
        case eBill
        case forgotPassword
        case forgotUsername
        case register
        case bill
        case payment
        case wallet
        case authOutage
        case unauthOutage
        case usage
        case more
        case biometricsToggle
        case contactUs
        case home
        case unauth
        case accountPicker
        case alerts
        
        case loginPageStart
        case loginTokenNetworkComplete
        case loginExchangeTokenNetworkComplete
        case loginAccountNetworkComplete
        case initialAuthenticatedScreenStart
        
        case changePasswordStart
        case changePasswordSubmit
        case changePasswordNetworkComplete
        
        case reportOutageStart
        case reportOutageSubmit
        case reportOutageNetworkComplete
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
        
        // Gamification
        case gamification
        case gamificationOptOut
        case gamificationExperienceAccessed
    }
    
    /// Name of user property -> Mapped directly to Firebase
    enum UserProperty: String {
        case isBiometricsEnabled
        
        case isControlGroup
        case customerType
        case serviceType
        
        case isScreenReaderEnabled
        case isSwitchAccessEnabled
        case fontScale
        
        // Gamification
        case gamificationGroup
        case gamificationCluster
        case gamificationIsOptedOut
        case gamificationIsOnboarded
    }
    
    /// This method should only be called once from App Delegate: Configures Firebase
    public static func configure() {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info-\(Configuration.shared.environmentName.rawValue)-Flavor\(Configuration.shared.opco.rawValue)", ofType: "plist"),
            let fileopts = FirebaseOptions(contentsOfFile: filePath) else {
                return Log.info("Failed to load Firebase Analytics")
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
        NSLog("📊🔥 Firebase Event: \(event.rawValue)")
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
    
    public static func logEvent(_ event: Event, customParameters: [String : Any]) {
        #if DEBUG
        NSLog("📊🔥 Firebase Event: \(event.rawValue)")
        #endif

        Analytics.logEvent(event.rawValue, parameters: customParameters)
    }
    
    /// Sets a User Property on the current user, all future events are auto tagged with User Properties
    ///
    /// - Parameters:
    ///   - userProperty: Name of the user property
    ///   - value: `String` value of property
    public static func setUserProperty(_ userProperty: UserProperty, value: String? = nil) {
        #if DEBUG
        NSLog("👤 Set User Property: \(userProperty.rawValue)")
        #endif
        
        Analytics.setUserProperty(value, forName: userProperty.rawValue)
    }

    public static func trackScreenWithName(_ name: String?, className: String?) {
        Analytics.setScreenName(name, screenClass: className)
    }
    
}


// MARK: - Watch Analytics

extension FirebaseUtility {
    public static func logWatchScreenView(_ screenName: String) {
        NSLog("📊🔥⌚️ Firebase Event: \(screenName)")
        
        Analytics.logEvent(Event.watch.rawValue, parameters: [EventParameter.Name.action.rawValue: screenName])
    }
}


/// Event name + event value -> Mapped to dict before being send to Firebase
///
/// - Note: Only one parameter should have a value between `value` and `providedValue`.  If both have a value, `providedValue` takes precendence.
struct EventParameter {
    enum Name: String {
        case action
        case value
        case alternateContact = "alternate_contact"
    }
    
    enum Value: String {
        case errorCode
        case screenName
        
        case email
        case text
        case both
        case none
        
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
        case verification_complete
        case answer_question_complete
        
        case cancel
        case autopay
        
        case account_complete
        case resend_email
        case ebill_enroll
        case account_verify
        case return_to_signin
        
        case view_pdf
        case history_view_more_upcoming_header
        case history_view_more_past_header
        case history_view_more_past_row
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
        case phone_number_gas_1
        case phone_number_gas_2
        case phone_number_electric_1
        case phone_number_electric_2
        case view_details
        case report_complete
        case map
        case streetlight_map
        case account_number_help
        
        case electric_segment_press
        case gas_segment_press
        case last_bill_graph_press
        case last_year_graph_press
        
        case previous_bar_press
        case current_bar_press
        case projected_bar_press
        
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
        
        case view_screen
        case personalize_banner
        case personalize_button
        case personalize_complete
        case personalize_restore
        case bill_cta
        case bill_slide_to_pay
        case bill_choose_default_payment_method
        case bill_terms
        case bill_view_pdf
        case usage_cta
        case promo_cta
        case outage_cta
        case projected_bill_cta
        case projected_bill_electric_press
        case projected_bill_gas_press
        case usage_electric_press
        case usage_gas_press
        case usage_previous_graph_press
        case usage_next_graph_press
        case urgent_message_press
        case weather_tip
        
        case sign_in_register_press
        case report_outage_press
        case view_outage_press
        
        case days_before_due_press
        case english
        case spanish
        case opco_update
        case bill_enroll_push_cancel
        case bill_enroll_push_continue
        case bill_unenroll_push_continue
        
        // Login
        case show_password
        case forgot_username_press
        case forgot_password_press
        case biometrics_press
        
        // Gamification
        case onboard_start
        case onboard_step1_complete
        case onboard_step2_complete
        case opt_in
        case push_opt_out
        case reminder_set
        case tip_favorited
        case coin_tapped
        case gifts_changed
        case toggled_gas_elec
        case viewed_task_empty_state
        case tapped_fab
        case switch_to_game_view
        case switch_to_home_view
        case final_gift_unlocked
        case seven_day_streak
        
        case extension_cta
        case dpa_cta
        case reinstate_cta
        case assistance_cta
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
