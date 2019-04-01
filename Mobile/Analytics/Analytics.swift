//
//  File.swift
//  Mobile
//
//  Created by Kenny Roethel on 8/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

enum AnalyticsEvent: String {
    case autoPayEnrollOffer = "AutoPayEnrollOffer"
    case autoPayEnrollSelectBank = "AutoPayEnrollSelectBank"
    case autoPayEnrollSubmit = "AutoPayEnrollSubmit"
    case autoPayEnrollComplete = "AutoPayEnrollComplete"
    
    case autoPayUnenrollOffer = "AutoPayUnEnrollOffer"
    case autoPayUnenrollComplete = "AutoPayUnEnrollComplete"
    
    case autoPayModifySettingOffer = "AutoPayModifySettingOffer"
    case autoPayModifySettingOfferNew = "AutoPayModifySettingOfferNew"
    case autoPayModifySettingSubmit = "AutoPayModifySettingSubmit"
    case autoPayModifySettingComplete = "AutoPayModifySettingComplete"
    case autoPayModifySettingCompleteNew = "AutoPayModifySettingCompleteNew"

    case autoPayModifyWallet = "AutoPayModifyWallet"
    case autoPayModifyBankView = "AutoPayModifyBankView"
    case autoPayModifyBankSave = "AutoPayModifyBankSave"
    case autoPayModifyBankComplete = "AutoPayModifyBankComplete"
    
    case budgetBillEnrollOffer = "BudgetBillEnrollOffer"
    case budgetBillEnrollComplete = "BudgetBillEnrollComplete"
    case budgetBillUnEnrollOffer = "BudgetBillUnEnrollOffer"
    case budgetBillUnEnrollComplete = "BudgetBillUnEnrollComplete"
    case budgetBillUnEnrollOK = "BudgetBillUnenrollOK"
    case budgetBillUnEnrollCancel = "BudgetBillUnenrollCancel"
    
    case eBillEnrollOffer = "EbillEnrollOffer"
    case eBillEnrollComplete = "EbillEnrollComplete"
    case eBillUnEnrollOffer = "EbillUnenrollOffer"
    case eBillUnEnrollComplete = "EbillUnenrollComplete"
    
    case loginOffer = "LoginOffer"
    case loginComplete = "LoginComplete"
    case loginError = "LoginError"
    
    case forgotPasswordOffer = "ForgotPWDOffer"
    case forgotPasswordComplete = "ForgotPWDComplete"
    case forgotUsernameOffer = "ForgotUsernameOffer"
    case forgotUsernameAccountValidate = "ForgotUsernameAcctValidate"
    case forgotUsernameSecuritySubmit = "ForgotUsernameSecuritySubmit"
    case forgotUsernameCompleteAutoPopup = "ForgotUsernameCompleteAutopop"
    case forgotUsernameCompleteAccountValidation = "ForgotUsernameCompleteAcctVal"

    case registerOffer = "RegisterOffer"
    case registerAccountValidation = "RegisterAcctVal"
    case registerAccountSetup = "RegisterAcctSetup"
    case registerAccountSecurityQuestions = "RegisterAcctSecurityQuestions"
    case registerAccountComplete = "RegisterComplete"
    case registerResendEmail = "RegisterResendEmail"
    case registerEBillEnroll = "RegisterEbillEnroll"
    case registerAccountVerify = "RegisterAccountVerify"
    
    case billingOfferComplete = "BillingOfferComplete"
    case homeOfferComplete = "HomeOfferComplete"
    case checkBalanceError = "CheckBalanceError"
    
    case outageStatusDetails = "OutageStatusDetails"
    case outageStatusOfferComplete = "OutageStatusOfferComplete"
    case billViewCurrentOfferComplete = "BillViewCurrentOfferComplete"
    case billViewCurrentError = "BillViewCurrentError"
    case billViewPastOfferComplete = "BillViewPastOfferComplete"
    case billViewPastError = "BillViewPastError"
    
    case viewMapOfferComplete = "ViewMapOfferComplete"
    
    case eCheckOffer = "EcheckOffer"
    case eCheckAddNewWallet = "EcheckAddNewWallet"
    case eCheckSubmit = "EcheckSubmit"
    case eCheckComplete = "EcheckComplete"
    case eCheckError = "EcheckError"
    
    case cardOffer = "CardOffer"
    case cardAddNewWallet = "CardAddNewWallet"
    case cardSubmit = "CardSubmit"
    case cardComplete = "CardComplete"
    case cardError = "CardError"
    case confirmationScreenAutopayEnroll = "ConfirmationScreenAutoPayEnroll"
    
    case addBankNewWallet = "AddBankNewWallet"
    case addCardNewWallet = "AddCardNewWallet"
    
    case changePasswordOffer = "ChangePWDOffer"
    case changePasswordComplete = "ChangePWDComplete"
    case changePasswordDone = "ChangePWDDone"

    case releaseInfoOffer = "ReleaseInfoOffer"
    case releaseInfoComplete = "ReleaseInfoComplete"
    case releaseInfoSubmit = "ReleaseInfoSubmit"
    case setDefaultAccountChange = "SetDefaultAcctChange"
    case setDefaultAccountCancel = "SetDefaultAcctCancel"
    case touchIDEnable = "TouchIDEnable"
    case touchIDDisable = "TouchIDDisable"
    case reportOutageAuthSubmit = "ReportOutageAuthSubmit"
    
    case reportOutageAuthCircuitBreak = "ReportOutageAuthCircuitBreak"
    case reportOutageEmergencyCall = "ReportOutageEmergencyCall"
    case reportOutageAuthComplete = "ReportOutageAuthComplete"
    case reportOutageAuthOffer = "ReportOutageAuthOffer"
    case outageAuthEmergencyCall = "OutageAuthEmergencyCall"

    case oneTouchBankOffer = "OneTouchBankOffer"
    case oneTouchBankComplete = "OneTouchBankComplete"
    case oneTouchBankError = "OneTouchBankError"
    case oneTouchCardOffer = "OneTouchCardOffer"
    case oneTouchCardComplete = "OneTouchCardComplete"
    case oneTouchCardError = "OneTouchCardError"
    case oneTouchTermsView = "OneTouchTermsView"
    case oneTouchEnabledBillCard = "OneTouchPayEnableBillCard"
    case viewBillBillCard = "ViewBillBillCard"
    case homePromoCard = "HomePromoCard"
    case addWalletCameraOffer = "AddWalletCameraOffer"
    case addWalletComplete = "AddWalletComplete"
    
    case outageStatusUnAuthOffer = "OutageStatusUnAuthOffer"
    case outageStatusUnAuthComplete = "OutageStatusUnAuthComplete"
    case outageStatusUnAuthAcctValidate = "OutageStatusUnAuthAcctValidate"
    case outageStatusUnAuthAcctSelect = "OutageStatusUnAuthAcctSelect"
    case outageStatusUnAuthStatusButton = "OutageStatusUnAuthStatusButton"
    case outageStatusUnAuthAcctValEmergencyPhone = "OutageStatusUnAuthAcctValEmergencyPhone"
    case viewOutageMapUnAuthOfferComplete = "ViewOutageMapUnAuthOfferComplete"
    case viewOutageMapGuestMenu = "ViewOutageMapGuestMenu"
    case viewOutageUnAuthMenu = "ViewOutageUnAuthMenu"
    case reportAnOutageUnAuthOffer = "ReportAnOutageUnAuthOffer"
    case reportAnOutageUnAuthOutScreen = "ReportAnOutageUnAuthOutScreen"
    case reportAnOutageUnAuthSubmitAcctVal = "ReportAnOutageUnAuthSubmitAcctVal"
    case reportAnOutageUnAuthSubmitAcctSelection = "ReportAnOutageUnAuthSubmitAcctSelection"
    case reportAnOutageUnAuthSubmit = "ReportAnOutageUnAuthSubmit"
    case reportAnOutageUnAuthCircuitBreakCheck = "ReportAnOutageUnAuthCircuitBreakCheck"
    case reportAnOutageUnAuthEmergencyPhone = "ReportAnOutageUnAuthEmergencyPhone"
    case reportAnOutageUnAuthComplete = "ReportAnOutageUnAuthComplete"
    case reportAnOutageUnAuthScreenView = "ReportAnOutageUnAuthScreenView"
    case outageScreenUnAuthEmergencyPhone = "OutageScreenUnAuthEmergencyPhone"
    
    case contactUsAuthCall = "ContactUsAuthCall"
    case contactUsUnAuthCall = "ContactUsUnAuthCall"
    case contactUsForm = "ContactUsForm"
    case unAuthContactUsForm = "UnAuthContactUsForm"
    
    case alertsPrefCenterOffer = "PrefCenterOffer"
    case alertsPrefCenterSave = "PrefCenterSave"
    case alertsPrefCenterComplete = "PrefCenterComplete"
    case alertsPayRemind = "AlertsPayRemind"
    case alertsEnglish = "AlertsEnglish"
    case alertsSpanish = "AlertsSpanish"
    case alertsMainScreen = "AlertsMainScreen"
    case alertsiOSPushInitial = "AlertsiOSPushInitial"
    case alertsiOSPushDontAllowInitial = "AlertsiOSPushDontAllowInitial"
    case alertsiOSPushOKInitial = "AlertsiOSPushOKInitial"
    case alertsOpCoUpdate = "AlertsOpCoUpdate"
    case alertseBillEnrollPush = "AlertseBillEnrollPush"
    case alertseBillEnrollPushCancel = "AlertseBillEnrollPushCancel"
    case alertseBillEnrollPushContinue = "AlertseBillEnrollPushContinue"
    case alertseBillUnenrollPush = "AlertseBillUnenrollPush" // not currently used
    case alertseBillUnenrollPushCancel = "AlertseBillUnenrollPushCancel"
    case alertseBillUnenrollPushContinue = "AlertseBillUnenrollPushContinue"
    case alertsDevSet = "AlertsDevSet"

    case viewUsageOfferComplete = "ViewUsageOfferComplete"
    case viewUsagePeakRewards = "ViewUsagePeakRewards"
    case viewUsageElectricity = "ViewUsageElectricity"
    case viewUsageGas = "ViewUsageGas"
    case viewUsageLink = "ViewUsageLink"
    case viewSmartEnergyRewards = "ViewSmartEnergyRewards"
    case viewPeakTimeSavings = "ViewPeakTimeSavings"
    
    case peakTimePromo = "PeakTimePromo"
    case hourlyPricing = "HourlyPricing"
    
    case emptyStatePeakSmart = "EmptyStatePeakSmart"
    case emptyStateUsageOverview = "EmptyStateUsageOverview"
    case emptyStateSmartEnergyHome = "EmptyStateSmartEnergyHome"
    
    case allSavingsUsage = "AllSavingsUsage"
    case allSavingsSmartEnergy = "AllSavingsSmartEnergy"
    
    // Bill Analysis
    case billNeedHelp = "BillNeedHelp"
    case billElectricityToggle = "BillElectricityToggle"
    case billGasToggle = "BillGasToggle"
    case billLastYearToggle = "BillLastYearToggle"
    case billPreviousToggle = "BillPreviousToggle"
    case billPreviousReason = "BillPreviousReason"
    case billWeatherReason = "BillWeatherReason"
    case billOtherReason = "BillOtherReason"
    
    case viewHomeProfile = "ViewHomeProfile"
    case homeProfileSave = "HomeProfileSave"
    case homeProfileConfirmation = "HomeProfileConfirmation"
    
    case viewTopTips = "ViewTopTips"

    case wakeSave = "WakeSave"
    case wakeToast = "WakeToast"
    case leaveSave = "LeaveSave"
    case leaveToast = "LeaveToast"
    case returnSave = "ReturnSave"
    case returnToast = "ReturnToast"
    case sleepSave = "SleepSave"
    case sleepToast = "SleepToast"
    case adjustThermSave = "AdjustThermSave"
    case adjustThermToast = "AdjustThermToast"
    case systemCool = "SystemCool"
    case systemHeat = "SystemHeat"
    case systemOff = "SystemOff"
    case fanAuto = "FanAuto"
    case fanCirculate = "FanCirculate"
    case fanOn = "FanOn"
    case permanentHoldOn = "PermanentHoldOn"
    case permanentHoldOff = "PermanentHoldOff"
    case overrideSave = "OverrideSave"
    case overrideToast = "OverrideToast"
    case cancelOverride = "CancelOverride"
    case cancelOverrideToast = "CancelOverrideToast"
    
    case strongPasswordOffer = "StrongPasswordOffer"
    case strongPasswordComplete = "StrongPasswordComplete"
    
    case viewStreetlightMapOfferComplete = "ViewStreetlightMapOfferComplete"
    case profileLoaded = "ProfileLoaded"
}

enum AnalyticsOutageSource {
    case report
    case status
}

enum AnalyticsDimension: UInt {
    case keepMeSignedIn = 3
    case fingerprintUsed = 4
    case errorCode = 5
    case otpEnabled = 6
    case link = 7
    case residentialAMI = 8 // "Residential/AMI", "Residential/Non-AMI", "Commercial/AMI", or "Commercial/Non-AMI"
    case hourlyPricingEnrollment = 9 // "enrolled" or "unenrolled"
    case bgeControlGroup = 10 // "true" or "false"
    case peakSmart = 11 // "true" or "false"
    case paymentTempWalletItem = 13 // "true" or "false"
}

struct Analytics {
    private init() {}
    
    static var isAnalyticsEnabled: Bool {
        switch Environment.shared.environmentName {
        case .stage, .prodbeta, .prod:
            return true
        default:
            return false
        }
    }
    
    static func log(event: AnalyticsEvent, dimensions: [AnalyticsDimension: String] = [:]) {
        #if DEBUG
        NSLog("📊 %@", event.rawValue)
        #endif
        
        guard isAnalyticsEnabled else { return }
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: event.rawValue)
        
        let dimensionBuilder = GAIDictionaryBuilder.createScreenView()!
        dimensions.forEach { dimension, value in
            dimensionBuilder.set(value, forKey: GAIFields.customDimension(for: dimension.rawValue))
        }
        
        tracker?.send(dimensionBuilder.build() as? [AnyHashable: Any])
    }
}
