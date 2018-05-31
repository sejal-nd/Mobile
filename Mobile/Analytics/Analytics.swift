//
//  File.swift
//  Mobile
//
//  Created by Kenny Roethel on 8/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

enum AnalyticsPageView: String {
    case AutoPayEnrollOffer = "AutoPayEnrollOffer"
    case AutoPayEnrollSelectBank = "AutoPayEnrollSelectBank"
    case AutoPayEnrollSubmit = "AutoPayEnrollSubmit"
    case AutoPayEnrollComplete = "AutoPayEnrollComplete"
    
    case AutoPayUnenrollOffer = "AutoPayUnEnrollOffer"
    case AutoPayUnenrollComplete = "AutoPayUnEnrollComplete"
    
    case AutoPayModifySettingOffer = "AutoPayModifySettingOffer"
    case AutoPayModifySettingOfferNew = "AutoPayModifySettingOfferNew"
    case AutoPayModifySettingSubmit = "AutoPayModifySettingSubmit"
    case AutoPayModifySettingComplete = "AutoPayModifySettingComplete"
    case AutoPayModifySettingCompleteNew = "AutoPayModifySettingCompleteNew"

    case AutoPayModifyWallet = "AutoPayModifyWallet"
    case AutoPayModifyBankView = "AutoPayModifyBankView"
    case AutoPayModifyBankSave = "AutoPayModifyBankSave"
    case AutoPayModifyBankComplete = "AutoPayModifyBankComplete"
    
    case BudgetBillEnrollOffer = "BudgetBillEnrollOffer"
    case BudgetBillEnrollComplete = "BudgetBillEnrollComplete"
    case BudgetBillUnEnrollOffer = "BudgetBillUnEnrollOffer"
    case BudgetBillUnEnrollComplete = "BudgetBillUnEnrollComplete"
    case BudgetBillUnEnrollOK = "BudgetBillUnenrollOK"
    case BudgetBillUnEnrollCancel = "BudgetBillUnenrollCancel"
    
    case EBillEnrollOffer = "EbillEnrollOffer"
    case EBillEnrollComplete = "EbillEnrollComplete"
    case EBillUnEnrollOffer = "EbillUnenrollOffer"
    case EBillUnEnrollComplete = "EbillUnenrollComplete"
    
    case LoginOffer = "LoginOffer"
    case LoginComplete = "LoginComplete"
    case LoginError = "LoginError"
    
    case ForgotPasswordOffer = "ForgotPWDOffer"
    case ForgotPasswordComplete = "ForgotPWDComplete"
    case ForgotUsernameOffer = "ForgotUsernameOffer"
    case ForgotUsernameAccountValidate = "ForgotUsernameAcctValidate"
    case ForgotUsernameSecuritySubmit = "ForgotUsernameSecuritySubmit"
    case ForgotUsernameCompleteAutoPopup = "ForgotUsernameCompleteAutopop"
    case ForgotUsernameCompleteAccountValidation = "ForgotUsernameCompleteAcctVal"

    case RegisterOffer = "RegisterOffer"
    case RegisterAccountValidation = "RegisterAcctVal"
    case RegisterAccountSetup = "RegisterAcctSetup"
    case RegisterAccountSecurityQuestions = "RegisterAcctSecurityQuestions"
    case RegisterAccountComplete = "RegisterComplete"
    case RegisterResendEmail = "RegisterResendEmail"
    case RegisterEBillEnroll = "RegisterEbillEnroll"
    case RegisterAccountVerify = "RegisterAccountVerify"
    
    case BillingOfferComplete = "BillingOfferComplete"
    case HomeOfferComplete = "HomeOfferComplete"
    case CheckBalanceError = "CheckBalanceError"
    
    case OutageStatusDetails = "OutageStatusDetails"
    case OutageStatusOfferComplete = "OutageStatusOfferComplete"
    case BillViewCurrentOfferComplete = "BillViewCurrentOfferComplete"
    case BillViewCurrentError = "BillViewCurrentError"
    case BillViewPastOfferComplete = "BillViewPastOfferComplete"
    case BillViewPastError = "BillViewPastError"
    
    case ViewMapOfferComplete = "ViewMapOfferComplete"
    
    case ECheckOffer = "EcheckOffer"
    case ECheckAddNewWallet = "EcheckAddNewWallet"
    case ECheckSubmit = "EcheckSubmit"
    case ECheckComplete = "EcheckComplete"
    case EcheckError = "EcheckError"
    
    case CardOffer = "CardOffer"
    case CardAddNewWallet = "CardAddNewWallet"
    case CardSubmit = "CardSubmit"
    case CardComplete = "CardComplete"
    case CardError = "CardError"
    case ConfirmationScreenAutopayEnroll = "ConfirmationScreenAutoPayEnroll"
    
    case AddBankNewWallet = "AddBankNewWallet"
    case AddCardNewWallet = "AddCardNewWallet"
    
    case ChangePasswordOffer = "ChangePWDOffer"
    case ChangePasswordComplete = "ChangePWDComplete"
    case ChangePasswordDone = "ChangePWDDone"

    case ReleaseInfoOffer = "ReleaseInfoOffer"
    case ReleaseInfoComplete = "ReleaseInfoComplete"
    case ReleaseInfoSubmit = "ReleaseInfoSubmit"
    case SetDefaultAccountChange = "SetDefaultAcctChange"
    case SetDefaultAccountCancel = "SetDefaultAcctCancel"
    case TouchIDEnable = "TouchIDEnable"
    case TouchIDDisable = "TouchIDDisable"
    case ReportOutageAuthSubmit = "ReportOutageAuthSubmit"
    
    case ReportOutageAuthCircuitBreak = "ReportOutageAuthCircuitBreak"
    case ReportOutageEmergencyCall = "ReportOutageEmergencyCall"
    case ReportOutageAuthComplete = "ReportOutageAuthComplete"
    case ReportOutageAuthOffer = "ReportOutageAuthOffer"
    case OutageAuthEmergencyCall = "OutageAuthEmergencyCall"

    case OneTouchBankOffer = "OneTouchBankOffer"
    case OneTouchBankComplete = "OneTouchBankComplete"
    case OneTouchBankError = "OneTouchBankError"
    case OneTouchCardOffer = "OneTouchCardOffer"
    case OneTouchCardComplete = "OneTouchCardComplete"
    case OneTouchCardError = "OneTouchCardError"
    case OneTouchTermsView = "OneTouchTermsView"
    case OneTouchEnabledBillCard = "OneTouchPayEnableBillCard"
    case ViewBillBillCard = "ViewBillBillCard"
    case HomePromoCard = "HomePromoCard"
    case AddWalletCameraOffer = "AddWalletCameraOffer"
    case AddWalletComplete = "AddWalletComplete"
    
    case OutageStatusUnAuthOffer = "OutageStatusUnAuthOffer"
    case OutageStatusUnAuthComplete = "OutageStatusUnAuthComplete"
    case OutageStatusUnAuthAcctValidate = "OutageStatusUnAuthAcctValidate"
    case OutageStatusUnAuthAcctSelect = "OutageStatusUnAuthAcctSelect"
    case OutageStatusUnAuthStatusButton = "OutageStatusUnAuthStatusButton"
    case OutageStatusUnAuthAcctValEmergencyPhone = "OutageStatusUnAuthAcctValEmergencyPhone"
    case ViewOutageMapUnAuthOfferComplete = "ViewOutageMapUnAuthOfferComplete"
    case ViewOutageMapGuestMenu = "ViewOutageMapGuestMenu"
    case ViewOutageUnAuthMenu = "ViewOutageUnAuthMenu"
    case ReportAnOutageUnAuthOffer = "ReportAnOutageUnAuthOffer"
    case ReportAnOutageUnAuthOutScreen = "ReportAnOutageUnAuthOutScreen"
    case ReportAnOutageUnAuthSubmitAcctVal = "ReportAnOutageUnAuthSubmitAcctVal"
    case ReportAnOutageUnAuthSubmitAcctSelection = "ReportAnOutageUnAuthSubmitAcctSelection"
    case ReportAnOutageUnAuthSubmit = "ReportAnOutageUnAuthSubmit"
    case ReportAnOutageUnAuthCircuitBreakCheck = "ReportAnOutageUnAuthCircuitBreakCheck"
    case ReportAnOutageUnAuthEmergencyPhone = "ReportAnOutageUnAuthEmergencyPhone"
    case ReportAnOutageUnAuthComplete = "ReportAnOutageUnAuthComplete"
    case ReportAnOutageUnAuthScreenView = "ReportAnOutageUnAuthScreenView"
    case OutageScreenUnAuthEmergencyPhone = "OutageScreenUnAuthEmergencyPhone"
    
    case ContactUsAuthCall = "ContactUsAuthCall"
    case ContactUsUnAuthCall = "ContactUsUnAuthCall"
    
    case AlertsPrefCenterOffer = "PrefCenterOffer"
    case AlertsPrefCenterSave = "PrefCenterSave"
    case AlertsPrefCenterComplete = "PrefCenterComplete"
    case AlertsPayRemind = "AlertsPayRemind"
    case AlertsEnglish = "AlertsEnglish"
    case AlertsSpanish = "AlertsSpanish"
    case AlertsMainScreen = "AlertsMainScreen"
    case AlertsiOSPushInitial = "AlertsiOSPushInitial"
    case AlertsiOSPushDontAllowInitial = "AlertsiOSPushDontAllowInitial"
    case AlertsiOSPushOKInitial = "AlertsiOSPushOKInitial"
    case AlertsOpCoUpdate = "AlertsOpCoUpdate"
    case AlertseBillEnrollPush = "AlertseBillEnrollPush"
    case AlertseBillEnrollPushCancel = "AlertseBillEnrollPushCancel"
    case AlertseBillEnrollPushContinue = "AlertseBillEnrollPushContinue"
    case AlertseBillUnenrollPush = "AlertseBillUnenrollPush"
    case AlertseBillUnenrollPushCancel = "AlertseBillUnenrollPushCancel"
    case AlertseBillUnenrollPushContinue = "AlertseBillUnenrollPushContinue"
    case AlertsDevSet = "AlertsDevSet"

    case ViewUsageOfferComplete = "ViewUsageOfferComplete"
    case ViewUsagePeakRewards = "ViewUsagePeakRewards"
    case ViewUsageElectricity = "ViewUsageElectricity"
    case ViewUsageGas = "ViewUsageGas"
    case ViewUsageLink = "ViewUsageLink"
    
    case PeakTimePromo = "PeakTimePromo"
    case HourlyPricing = "HourlyPricing"
    
    case EmptyStatePeakSmart = "EmptyStatePeakSmart"
    case EmptyStateUsageOverview = "EmptyStateUsageOverview"
    case EmptyStateSmartEnergyHome = "EmptyStateSmartEnergyHome"
    
    case AllSavingsUsage = "AllSavingsUsage"
    case AllSavingsSmartEnergy = "AllSavingsSmartEnergy"
    
    // Bill Analysis
    case BillNeedHelp = "BillNeedHelp"
    case BillElectricityToggle = "BillElectricityToggle"
    case BillGasToggle = "BillGasToggle"
    case BillLastYearToggle = "BillLastYearToggle"
    case BillPreviousToggle = "BillPreviousToggle"
    case BillPreviousReason = "BillPreviousReason"
    case BillWeatherReason = "BillWeatherReason"
    case BillOtherReason = "BillOtherReason"
    
    case ViewHomeProfile = "ViewHomeProfile"
    case HomeProfileSave = "HomeProfileSave"
    case HomeProfileConfirmation = "HomeProfileConfirmation"
    
    case ViewTopTips = "ViewTopTips"
    
    case WakeSave = "WakeSave"
    case WakeToast = "WakeToast"
    case LeaveSave = "LeaveSave"
    case LeaveToast = "LeaveToast"
    case ReturnSave = "ReturnSave"
    case ReturnToast = "ReturnToast"
    case SleepSave = "SleepSave"
    case SleepToast = "SleepToast"
    case AdjustThermSave = "AdjustThermSave"
    case AdjustThermToast = "AdjustThermToast"
    case SystemCool = "SystemCool"
    case SystemHeat = "SystemHeat"
    case SystemOff = "SystemOff"
    case FanAuto = "FanAuto"
    case FanCirculate = "FanCirculate"
    case FanOn = "FanOn"
    case PermanentHoldOn = "PermanentHoldOn"
    case PermanentHoldOff = "PermanentHoldOff"
    case OverrideSave = "OverrideSave"
    case OverrideToast = "OverrideToast"
    case CancelOverride = "CancelOverride"
    case CancelOverrideToast = "CancelOverrideToast"
}

enum AnalyticsOutageSource {
    case Report
    case Status
}

enum AnalyticsDimension: UInt {
    case KeepMeSignedIn = 3
    case FingerprintUsed = 4
    case ErrorCode = 5
    case OTPEnabled = 6
    case Link = 7
    case ResidentialAMI = 8 // "Residential/AMI", "Residential/Non-AMI", "Commercial/AMI", or "Commercial/Non-AMI"
    case HourlyPricingEnrollment = 9 // "enrolled" or "unenrolled"
    case BGEControlGroup = 10 // "true" or "false"
    case PeakSmart = 11 // "true" or "false"
}

struct Analytics {
    private init() {}
    
    static var isAnalyticsEnabled: Bool {
        switch Environment.shared.environmentName {
        case .stage, .prod:
            return true
        default:
            return false
        }
    }
    
    static func log(event: AnalyticsPageView, dimensions: [AnalyticsDimension: String] = [:]) {
        dLog("Analytics: " + event.rawValue)
        
        guard isAnalyticsEnabled else { return }
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: event.rawValue)
        
        let dimensionBuilder = GAIDictionaryBuilder.createScreenView()!
        dimensions.forEach { dimension, value in
            dimensionBuilder.set(value, forKey: GAIFields.customDimension(for: dimension.rawValue))
        }
        
        tracker?.send(dimensionBuilder.build() as! [AnyHashable: Any])
    }
}
