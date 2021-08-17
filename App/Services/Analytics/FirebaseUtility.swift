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

/// A type that represents a trackable event
private protocol Event {
    var name: String { get }
    var parameters: [String: Any]? { get }
}

/// A type that represents a trackable event parameter
private protocol EventParameter {
    var key: String { get }
    var value: Any { get }
    var type: ParameterType { get }
}

extension EventParameter {
    var key: String {
        return type.name
    }
    
    var value: Any {
        return "\(self)"
    }
    
    var type: ParameterType {
        return .action
    }
}

enum ParameterType: String {
    var name: String {
        return self.rawValue
    }
    
    case action
    case value
    case error
    case alternateContact = "alternate_contact"
}

enum FirebaseEvent: Event {
    case autoPay(parameters: [AutoPayParameter]?)
    case budgetBill(parameters: [BudgetBillParameter]?)
    case eBill(parameters: [EBillParameter]?)
    case forgotPassword(parameters: [ForgotPasswordParameter]?)
    case forgotUsername(parameters: [ForgotUsernameParameter]?)
    case register(parameters: [RegisterParameter]?)
    case bill(parameters: [BillParameter]?)
    case payment(parameters: [PaymentParameter]?)
    case wallet(parameters: [WalletParameter]?)
    
    case authOutage(parameters: [OutageParameter]?)
    case unauthOutage(parameters: [OutageParameter]?)
    
    case home(parameters: [HomeParameter]?)
    case accountPicker(parameters: [AccountPickerParameter]?)
    case biometricsToggle(parameters: [BiometricsParameter]?)
    
    case login(parameters: [LoginParameter]?)
    
    case usage(parameters: [UsageParameter]?)
    case more(parameters: [MoreParameter]?)
    case contactUs(parameters: [ContactUsParameter]?)
    
    case unauth(parameters: [UnAuthParameter]?)
    case alerts(parameters: [AlertsParameter]?)
    
    // Gamification
    case gamification(parameters: [GamificationParameter]?)
    case gamificationOptOut(parameters: [GamificationValueParameter]?)
    case gamificationExperienceAccessed(parameters: [GamificationValueParameter]?)
    
    case watch
    
    case errorNonFatal
    
    case loginPageStart
    case loginTokenNetworkComplete
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
    
    case screenView(_ screen: Screen)
    
    var name: String {
        switch self {
        case .autoPay:
            return "autoPay"
        case .budgetBill:
            return "budgetBill"
        case .eBill:
            return "eBill"
        case .bill:
            return "bill"
        case .payment:
            return "payment"
        case .authOutage:
            return "authOutage"
        case .unauthOutage:
            return "unauthOutage"
        case .register:
            return "register"
        case .home:
            return "home"
        case .forgotPassword:
            return "forgotPassword"
        case .forgotUsername:
            return "forgotUsername"
        case .wallet:
            return "wallet"
        case .accountPicker:
            return "accountPicker"
        case .biometricsToggle:
            return "biometricsToggle"
        case .login:
            return "login"
        case .usage:
            return "usage"
        case .more:
            return "more"
        case .contactUs:
            return "contactUs"
        case .unauth:
            return "unauth"
        case .alerts:
            return "alerts"
        case .gamification:
            return "gamification"
        case .gamificationOptOut:
            return "gamificationOptOut"
        case .gamificationExperienceAccessed:
            return "gamificationExperienceAccessed"
        case .screenView:
            return AnalyticsEventScreenView
        default:
            return "\(self)"
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .autoPay(let parameters as [EventParameter]?),
             .budgetBill(let parameters as [EventParameter]?),
             .eBill(let parameters as [EventParameter]?),
             .bill(let parameters as [EventParameter]?),
             .payment(let parameters as [EventParameter]?),
             .authOutage(let parameters as [EventParameter]?),
             .unauthOutage(let parameters as [EventParameter]?),
             .home(let parameters as [EventParameter]?),
             .register(let parameters as [EventParameter]?),
             .forgotPassword(let parameters as [EventParameter]?),
             .forgotUsername(let parameters as [EventParameter]?),
             .wallet(let parameters as [EventParameter]?),
             .accountPicker(let parameters as [EventParameter]?),
             .login(let parameters as [EventParameter]?),
             .usage(let parameters as [EventParameter]?),
             .more(let parameters as [EventParameter]?),
             .contactUs(let parameters as [EventParameter]?),
             .unauth(let parameters as [EventParameter]?),
             .alerts(let parameters as [EventParameter]?),
             .gamification(let parameters as [EventParameter]?),
             .gamificationOptOut(let parameters as [EventParameter]?),
             .gamificationExperienceAccessed(let parameters as [EventParameter]?),
             .biometricsToggle(let parameters as [EventParameter]?):
            
            // Convert Event Parameter into dict if it exists
            let parametersDict = parameters?.reduce([String: Any]()) { (dict, eventParameter) -> [String: Any] in
                var dict = dict
                
                dict[eventParameter.key] = eventParameter.value
                
                return dict
            }
            
            return parametersDict
            
        case .screenView(let screen):
            return [
                AnalyticsParameterScreenName: screen.screenName,
                    AnalyticsParameterScreenClass: screen.className
            ]

        default:
            return nil
        }
    }
}

enum BiometricsParameter: String, EventParameter {
    case `true`
    case `false`
    
    var type: ParameterType {
        return .value
    }
}

enum AutoPayParameter: String, EventParameter {
    case enroll_start
    case enroll_complete
    case unenroll_start
    case unenroll_complete
    case modify_start
    case modify_complete
         
    case network_submit_error
    case settings_changed
    case modify_bank
    case learn_more
    case terms
    
    case submitError = "submit"
    
    var type: ParameterType {
        switch self {
        case .submitError:
            return .error
        default:
            return .action
        }
    }
}

enum BudgetBillParameter: String, EventParameter {
    case learn_more
    case enroll_start
    case enroll_complete
    case unenroll_start
    case unenroll_complete
    case network_submit_error
    
    var type: ParameterType {
        return .action
    }
}

enum EBillParameter: String, EventParameter {
    case learn_more
    case enroll_start
    case enroll_complete
    case unenroll_start
    case unenroll_complete
    case network_submit_error
}

enum ForgotPasswordParameter: String, EventParameter {
    case complete
    case network_submit_error
}

enum ForgotUsernameParameter: String, EventParameter {
    case verification_complete
    case answer_question_complete
    case return_to_signin
    case network_submit_error
}

enum BillParameter: String, EventParameter {
    case view_pdf
    case history_view_more_upcoming_header
    case history_view_more_past_header
    case history_view_more_past_row
    case history_view_pdf
    
    case extension_cta
    case dpa_cta
    case reinstate_cta
    case assistance_cta
        
    // errors
    case bill_not_available
    case current_pdf_not_available
    case past_pdf_not_available
    
    var type: ParameterType {
        switch self {
        case .bill_not_available,
             .current_pdf_not_available,
             .past_pdf_not_available:
            return .error
        default:
            return .action
        }
    }
}

enum PaymentParameter: EventParameter {
    case switch_payment_method
    case view_terms
    case submit
    case cancel
    case card_complete
    case bank_complete
    case autopay
    case alternateContact(_ alternateContact: AlternateContact)
    
    enum AlternateContact: String, EventParameter {
        case email
        case text
        case both
        case none
    }
    
    var type: ParameterType {
        switch self {
        case .alternateContact:
            return .alternateContact
        default:
            return .action
        }
    }
    
    var value: String {
        switch self {
        case .alternateContact(let alternateContact):
            return alternateContact.rawValue
        default:
            return "\(self)"
        }
    }
}

enum OutageParameter: String, EventParameter {
    case emergency_number
    case phone_number_main
    case phone_number_emergency_gas
    case phone_number_emergency_electric
    case phone_number_gas_1
    case phone_number_gas_2
    case phone_number_electric_1
    case phone_number_electric_2
    case view_details
    case report_outage
    case report_complete
    case map
    case streetlight_map
    case account_number_help
}

enum HomeParameter: String, EventParameter {
    case view_screen
    case personalize_banner
    case personalize_button
    case personalize_complete
    case personalize_restore
    case bill_cta
    case bill_slide_to_pay
    case bill_choose_default_payment_method
    case bill_terms
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
    
    case extension_cta
    case dpa_cta
    case reinstate_cta
    case assistance_cta

    
    case balance_not_available
    
    var type: ParameterType {
        switch self {
        case .balance_not_available:
            return .error
        default:
            return .action
        }
    }
}

enum RegisterParameter: String, EventParameter {
    case resend_email
    case ebill_enroll
    case account_verify
}

enum AccountPickerParameter: String, EventParameter {
    case press
    case account_change
    case expand_premise
}

enum LoginParameter: String, EventParameter {
    case show_password
    case forgot_username_press
    case forgot_password_press
    case biometrics_press
}

enum GamificationParameter: EventParameter {
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
    
    case onboarding_card_version(_ version: Int)
    
    var value: Any {
        switch self {
        case .onboarding_card_version(let version):
            return version
        default:
            return "\(self)"
        }
    }
}

enum GamificationValueParameter: EventParameter {
    case current_point_total(_ points: Double)
    case curr_streak(_ streak: Int)
    case selected_bg(_ background: String)
    case selected_hat(_ hat: String)
    case selected_acc(_ account: String)
    
    var key: String {
        switch self {
        case .current_point_total:
            return "current_point_total"
        case .curr_streak:
            return "curr_streak"
        case .selected_bg:
            return "selected_bg"
        case .selected_hat:
            return "selected_hat"
        case .selected_acc:
            return "selected_acc"
        }
    }
    
    var value: Any {
        switch self {
        case .current_point_total(let points):
            return points
        case .curr_streak(let streak):
            return streak
        case .selected_bg(let background):
            return background
        case .selected_hat(let hat):
            return hat
        case .selected_acc(let account):
            return account
        }
    }
}

enum UnAuthParameter: String, EventParameter {
    case sign_in_register_press
    case report_outage_press
    case view_outage_press
    case billing_videos
}

enum WalletParameter: String, EventParameter {
    case add_bank_start
    case add_card_start
    case add_bank_complete
    case add_card_complete
    case delete_payment_method
    case edit_payment_method
    case scan_with_camera
}

enum AlertsParameter: String, EventParameter {
    case days_before_due_press
    case english
    case spanish
    case opco_update
    case bill_enroll_push_cancel
    case bill_enroll_push_continue
    case bill_unenroll_push_continue
}

enum ContactUsParameter: String, EventParameter {
    case online_form
    case emergency_number
    case phone_number_main
    case phone_number_emergency_gas
    case phone_number_emergency_electric
    case phone_number_gas_1
    case phone_number_gas_2
    case phone_number_electric_1
    case phone_number_electric_2
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
}

enum UsageParameter: String, EventParameter {
    case electric_segment_press
    case gas_segment_press
    case last_bill_graph_press
    case last_year_graph_press
    
    case previous_bar_press
    case current_bar_press
    case projected_bar_press
}

enum MoreParameter: String, EventParameter {
    case strong_password_complete
    case change_password_complete
    case default_account_help
    case set_default_account_complete
    case billing_videos
    case release_of_info_complete
    case alert_preferences_start
    case alert_preferences_complete
    case sign_out
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

enum Screen {
    // iOS
    case homeView(className: String)
    case billView(className: String)
    case outageView(className: String)
    case usageView(className: String)
    case moreView(className: String)
    
    case billActivityView(className: String)
    case autopayEnrolledView(className: String)
    case autopayUnenrolledView(className: String)
    case changePasswordView(className: String)
    case releaseOfInfoView(className: String)
    case unauthenticatedOutageValidationView(className: String)
    case unauthenticatedOutageSelectView(className: String)
    case unauthenticatedOutageView(className: String)
    case paymentView(className: String)
    case alertPreferencesView(className: String)
    
    // Apple Watch
    case watchSignInView(className: String)
    case watchAccountListView(className: String)
    case watchOutageView(className: String)
    case watchReportOutageView(className: String)
    case watchUsageView(className: String)
    case watchBillView(className: String)
    
    var screenName: String {
        switch self {
        case .homeView:
            return "HomeView"
        case .billView:
            return "BillView"
        case .billActivityView:
            return "BillActivityView"
        case .outageView:
            return "OutageView"
        case .autopayEnrolledView:
            return "AutopayEnrolledView"
        case .autopayUnenrolledView:
            return "AutopayUnenrolledView"
        case .usageView:
            return "UsageView"
        case .moreView:
            return "MoreView"
        case .changePasswordView:
            return "ChangePasswordView"
        case .releaseOfInfoView:
            return "ReleaseOfInfoView"
        case .unauthenticatedOutageValidationView:
            return "UnauthenticatedOutageValidationView"
        case .unauthenticatedOutageSelectView:
            return "UnauthenticatedOutageSelectView"
        case .unauthenticatedOutageView:
            return "UnauthenticatedOutageView"
        case .paymentView:
            return "PaymentView"
        case .alertPreferencesView:
            return "AlertPreferencesView"
            
        case .watchSignInView:
            return "sign_in_screen_view"
        case .watchAccountListView:
            return "account_list_screen_view"
        case .watchOutageView:
            return "outage_screen_view"
        case .watchReportOutageView:
            return "report_outage_screen_view"
        case .watchUsageView:
            return "usage_screen_view"
        case .watchBillView:
            return "bill_screen_view"
        }
    }
        
    var className: String {
        switch self {
        case .homeView(let className),
             .billView(let className),
             .billActivityView(let className),
             .outageView(let className),
             .autopayEnrolledView(let className),
             .autopayUnenrolledView(let className),
             .usageView(let className),
             .moreView(let className),
             .changePasswordView(let className),
             .releaseOfInfoView(let className),
             .unauthenticatedOutageValidationView(let className),
             .unauthenticatedOutageSelectView(let className),
             .unauthenticatedOutageView(let className),
             .paymentView(let className),
             .alertPreferencesView(let className),
             
             .watchSignInView(let className),
             .watchAccountListView(let className),
             .watchOutageView(let className),
             .watchReportOutageView(let className),
             .watchUsageView(let className),
             .watchBillView(let className):
            return className
        }
    }
}

struct FirebaseUtility {
    
    /// This method should only be called once from App Delegate: Configures Firebase
    public static func configure() {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info-\(Configuration.shared.environmentName.rawValue)-Flavor\(Configuration.shared.opco.rawValue)", ofType: "plist"),
            let fileopts = FirebaseOptions(contentsOfFile: filePath) else {
                return Log.error("Failed to load Firebase Analytics")
        }

        FirebaseApp.configure(options: fileopts)
    }
    
    public static func logEvent(_ event: FirebaseEvent) {
        if let parameters = event.parameters {
            Log.info("📊🔥 Firebase Event: \(event.name)")
            parameters.forEach { parameter in
                Log.info("\(parameter.key): \(parameter.value)")
            }
        }

        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    /// Sets a User Property on the current user, all future events are auto tagged with User Properties
    ///
    /// - Parameters:
    ///   - userProperty: Name of the user property
    ///   - value: `String` value of property
    public static func setUserProperty(_ userProperty: UserProperty, value: String? = nil) {
        Log.info("👤 Set User Property: \(userProperty.rawValue)")
        
        Analytics.setUserProperty(value, forName: userProperty.rawValue)
    }
    
    public static func logScreenView(_ screen: Screen) {
        FirebaseUtility.logEvent(.screenView(screen))
    }
}

// MARK: - Watch Analytics

extension FirebaseUtility {
    public static func logWatchScreenView(_ screen: Screen) {
        Log.info("📊🔥⌚️ Firebase Event: \(screen.className)")
        FirebaseUtility.logScreenView(screen)
    }
}
