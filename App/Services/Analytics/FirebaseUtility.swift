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
    case stormOutage(parameters: [OutageParameter]?)

    
    case outageTracker(parameters: [OutageTrackerParameter]?)
    
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
    
    // ISUM
    case stopService(parameters: [StopServiceParameter])
    case authMoveService(parameters: [MoveServiceParameter])
    case unauthMoveService(parameters: [MoveServiceParameter])
    
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
        case .outageTracker:
            return "outageTracker"
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
        case .stopService:
            return "authStop"
        case .authMoveService:
            return "authMove"
        case .unauthMoveService:
            return "unauthMove"
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
             .outageTracker(let parameters as [EventParameter]?),
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
             .biometricsToggle(let parameters as [EventParameter]?),
             .stopService(let parameters as [EventParameter]?),
             .authMoveService(let parameters as [EventParameter]?),
             .unauthMoveService(let parameters as [EventParameter]?)
            :
            
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
    case bill_view_pdf
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

enum OutageTrackerParameter: String, EventParameter {
    case active_outage
    case power_restored_definitive
    case power_restored_non_definitive
    case power_on
    case account_gas_only
    case account_inactive
    case partial_restoration
    case crew_on_site_diverted
    case crew_en_route_diverted
    case extensive_damage
    case safety_hazard
    case nested_outage
    
    case technical_error
    
    var type: ParameterType {
        switch self {
        case .technical_error:
            return .error
        default:
            return .action
        }
    }
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
    case complete
    case account_invalid
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
    case change_my_security_complete
    case default_account_help
    case set_default_account_complete
    case billing_videos
    case release_of_info_complete
    case alert_preferences_start
    case alert_preferences_complete
    case report_outage_enroll_alerts
    case sign_out
}

enum StopServiceParameter: String, EventParameter {
    case commercial
    case calendar
    case exit
    case account_changed
    case submit
    case complete_resolved
    case complete_unresolved
    case finaled
    case pending_disconnect
    
    case submit_error
    case api_error
    
    var type: ParameterType {
        switch self {
        case .submit_error, .api_error:
            return .error
        default:
            return .action
        }
    }
}

enum MoveServiceParameter: String, EventParameter {
    case commercial
    case calendar_stop_date
    case calendar_start_date
    case exit
    case account_changed
    case submit
    case complete_resolved
    case complete_unresolved
    case finaled
    case pending_disconnect
    case ebill_selected
    
    case submit_error
    case api_error
    case validation_error
    
    var type: ParameterType {
        switch self {
        case .submit_error, .api_error, .validation_error:
            return .error
        default:
            return .action
        }
    }
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
    case mySecurityView(className: String)
    case releaseOfInfoView(className: String)
    case unauthenticatedOutageValidationView(className: String)
    case unauthenticatedOutageSelectView(className: String)
    case unauthenticatedOutageView(className: String)
    case paymentView(className: String)
    case alertPreferencesView(className: String)
    
    
    // ISUM Auth Stop
    case stopLandingView(className: String)
    case stopSelectStopDateView(className: String)
    case stopFinalBillAddressView(className: String)
    case stopReviewSubmitView(className: String)
    case stopConfirmationView(className: String)
    
    // ISUM Auth Move
    case moveLandingView(className: String)
    case moveSelectStopDateView(className: String)
    case moveNewAddressView(className: String)
    case moveNewAddressStreetView(className: String)
    case moveNewAddressApartmentView(className: String)
    case moveIdVerificationView(className: String)
    case moveSelectStartDateView(className: String)
    case moveFinalBillAddressView(className: String)
    case moveReviewView(className: String)
    case moveReviewSubmitView(className: String)
    case moveConfirmationView(className: String)
    
    // ISUM Unauth Move
    case unauthMoveValidationView(className: String)
    case unauthMoveAccountPickerView(className: String)
    case unauthMoveLandingView(className: String)
    case unauthMoveSelectStopDateView(className: String)
    case unauthMoveNewAddressView(className: String)
    case unauthMoveNewAddressStreetView(className: String)
    case unauthMoveNewAddressApartmentView(className: String)
    case unauthMoveIdVerificationView(className: String)
    case unauthMoveSelectStartDateView(className: String)
    case unauthMoveFinalBillAddressView(className: String)
    case unauthMoveReviewView(className: String)
    case unauthMoveReviewSubmitView(className: String)
    case unauthMoveConfirmationView(className: String)
    
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
        case .mySecurityView:
            return "MySecurityView"
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
            
        // ISUM Stop
        case .stopLandingView:
            return "StopLandingView"
        case .stopSelectStopDateView:
            return "StopSelectStopDateView"
        case .stopFinalBillAddressView:
            return "StopFinalBillAddressView"
        case .stopReviewSubmitView:
            return "StopReviewSubmitView"
        case .stopConfirmationView:
            return "StopConfirmationView"

      
            
        // ISUM Move
        case .moveLandingView:
            return "MoveLandingView"
        case .moveSelectStopDateView:
            return "MoveSelectStopDateView"
        case .moveNewAddressView:
            return "MoveNewAddressView"
        case .moveNewAddressStreetView:
            return "MoveNewAddressStreetView"
        case .moveNewAddressApartmentView:
            return "MoveNewAddressApartmentView"
        case .moveIdVerificationView:
            return "MoveIdVerificationView"
        case .moveSelectStartDateView:
            return "MoveSelectStartDateView"
        case .moveFinalBillAddressView:
            return "MoveFinalBillAddressView"
        case .moveReviewView:
            return "MoveReviewView"
        case .moveReviewSubmitView:
            return "MoveReviewSubmitView"
        case .moveConfirmationView:
            return "MoveConfirmationView"
            
        case .unauthMoveValidationView:
            return "UnauthMoveValidationView"
        case .unauthMoveAccountPickerView:
            return "UnauthMoveAccountPickerView"
        case .unauthMoveLandingView:
            return "UnauthMoveLandingView"
        case .unauthMoveSelectStopDateView:
            return "UnauthMoveSelectStopDateView"
        case .unauthMoveNewAddressView:
            return "UnauthMoveNewAddressView"
        case .unauthMoveNewAddressStreetView:
            return "UnauthMoveNewAddressStreetView"
        case .unauthMoveNewAddressApartmentView:
            return "UnauthMoveNewAddressApartmentView"
        case .unauthMoveIdVerificationView:
            return "UnauthMoveIdVerificationView"
        case .unauthMoveSelectStartDateView:
            return "UnauthMoveSelectStartDateView"
        case .unauthMoveFinalBillAddressView:
            return "UnauthMoveFinalBillAddressView"
        case .unauthMoveReviewView:
            return "UnauthMoveReviewView"
        case .unauthMoveReviewSubmitView:
            return "UnauthMoveReviewSubmitView"
        case .unauthMoveConfirmationView:
            return "UnauthMoveConfirmationView"
            
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
             .mySecurityView(let className),
             .releaseOfInfoView(let className),
             .unauthenticatedOutageValidationView(let className),
             .unauthenticatedOutageSelectView(let className),
             .unauthenticatedOutageView(let className),
             .paymentView(let className),
             .alertPreferencesView(let className),
             .stopLandingView(let className),
             .stopSelectStopDateView(let className),
             .stopFinalBillAddressView(let className),
             .stopReviewSubmitView(let className),
             .stopConfirmationView(let className),
           

             .moveLandingView(let className),
             .moveSelectStopDateView(let className),
             .moveNewAddressView(let className),
             .moveNewAddressStreetView(let className),
             .moveNewAddressApartmentView(let className),
             .moveIdVerificationView(let className),
             .moveSelectStartDateView(let className),
             .moveFinalBillAddressView(let className),
             .moveReviewView(let className),
             .moveReviewSubmitView(let className),
             .moveConfirmationView(let className),
            
             .unauthMoveValidationView(let className),
             .unauthMoveAccountPickerView(let className),
             .unauthMoveLandingView(let className),
             .unauthMoveSelectStopDateView(let className),
             .unauthMoveNewAddressView(let className),
             .unauthMoveNewAddressStreetView(let className),
             .unauthMoveNewAddressApartmentView(let className),
             .unauthMoveIdVerificationView(let className),
             .unauthMoveSelectStartDateView(let className),
             .unauthMoveFinalBillAddressView(let className),
             .unauthMoveReviewView(let className),
             .unauthMoveReviewSubmitView(let className),
             .unauthMoveConfirmationView(let className),
             
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
        var parameterLogs = ""
        if let parameters = event.parameters {
            parameterLogs = " ["
            parameters.forEach { parameter in
                parameterLogs.append("(\(parameter.key): \(parameter.value))")
            }
            parameterLogs.append("]")
        }
        
        Log.info("📊🔥 Firebase Event: \(event.name)\(parameterLogs)")

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
