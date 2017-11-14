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
    
    case AutoPayModifySettingsOffer = "AutoPayModifySettingOffer"
    case AutoPayModifySettingsOfferNew = "AutoPayModifySettingOfferNew"
    case AutoPayModifySettingsSubmit = "AutoPayModifySettingSubmit"
    case AutoPayModifySettingsComplete = "AutoPayModifySettingComplete"
    case AutoPayModifySettingsCompleteNew = "AutoPayModifySettingCompleteNew"

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
    case HomeOfferComplete = "HomeOfferComplete";
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
    
    case CardOffer = "CardOffer"
    case CardAddNewWallet = "CardAddNewWallet"
    case CardSubmit = "CardSubmit"
    case CardComplete = "CardComplete"
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
    case OneTouchCardOffer = "OneTouchCardOffer"
    case OneTouchCardComplete = "OneTouchCardComplete"
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
}

enum AnalyticsOutageSource {
    case Report
    case Status
}

enum Dimensions: UInt {
    case KeepMeSignedIn = 3;
    case FingerprintUsed = 4;
    case ErrorCode = 5;
    case OTPEnabled = 6;
    case Link = 7;
}

func isAnalyticsEnabled() -> Bool {
    if(Environment.sharedInstance.environmentName == "STAGE" || Environment.sharedInstance.environmentName == "PROD") {
        return true
    }
    
    return false
}

struct Analytics {
    func logScreenView(_ screenName: String) {
        if(isAnalyticsEnabled()) {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker?.set(kGAIScreenName, value: screenName)
            tracker?.send(GAIDictionaryBuilder.createScreenView()
                .build() as! [AnyHashable : Any]!)
        } else {
            dLog("Analytics: " + screenName)
        }
    }
    
    func logScreenView(_ screenName: String, dimensionIndex: Dimensions, dimensionValue: String) {
        if(isAnalyticsEnabled()) { print(dimensionIndex);print(dimensionValue);
            let tracker = GAI.sharedInstance().defaultTracker
            tracker?.set(kGAIScreenName, value: screenName)
            tracker?.send(GAIDictionaryBuilder.createScreenView()
                .set(dimensionValue, forKey: GAIFields.customDimension(for: dimensionIndex.rawValue))
                
                .build() as! [AnyHashable : Any]!)
        } else {
            dLog("Analytics: " + screenName)
        }
    }
    
    func logSignIn(_ screenName: String, keepSignedIn: String, usedFingerprint: String) {
        if(isAnalyticsEnabled()) {
            let tracker = GAI.sharedInstance().defaultTracker
            tracker?.set(kGAIScreenName, value: screenName)
            tracker?.send(GAIDictionaryBuilder.createScreenView()
                .set(keepSignedIn, forKey: GAIFields.customDimension(for: Dimensions.KeepMeSignedIn.rawValue))
                .set(usedFingerprint, forKey: GAIFields.customDimension(for: Dimensions.FingerprintUsed.rawValue))
                .build() as! [AnyHashable : Any]!)
        } else {
            dLog("Analytics: " + screenName)
        }
    }
    
}
