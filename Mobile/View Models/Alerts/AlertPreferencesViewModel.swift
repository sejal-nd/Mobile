//
//  AlertPreferencesViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 11/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertPreferencesViewModel {
    
    let disposeBag = DisposeBag()
    
    var accountDetail: AccountDetail! // Passed from AlertsViewController
    
    // Switch states
    let outage = Variable(false)
    let scheduledMaint = Variable(false)
    let severeWeather = Variable(false)
    let billReady = Variable(false)
    let paymentDue = Variable(false)
    let paymentDueDaysBefore = Variable(1)
    let budgetBilling = Variable(false)
    let forYourInfo = Variable(false)
    
    let english = Variable(true) // Language selection. False = Spanish
    
    required init() {
        
    }
    
    private(set) lazy var paymentDueDaysBeforeButtonText: Driver<String?> = self.paymentDueDaysBefore.asDriver().map {
        if $0 == 1 {
            return NSLocalizedString("1 Day Before", comment: "")
        }
        return String(format: NSLocalizedString("%d Days Before", comment: ""), $0)
    }
    
    // MARK: Detail Label Strings
    
    var outageDetailLabelText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Receive updates on unplanned outages due to storms.", comment: "")
        case .comEd:
            return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.\n NOTE: Outage Notifications will be provided by ComEd on a 24/7 basis. You may be updated with outage information during the overnight hours or over holidays where applicable.", comment: "")
        case .peco:
            return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.", comment: "")
        }
    }
    
    var scheduledMaintDetailLabelText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("From time to time, BGE must temporarily stop service in order to perform system maintenance or repairs. BGE typically informs customers of planned outages in their area by letter, however, in emergency situations we can inform customers by push notification. Planned outage information will also be available on the planned outages web page on BGE.com.", comment: "")
        case .comEd, .peco:
            return nil
        }
    }
    
    var severeWeatherDetailLabelText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("BGE may choose to contact you if a severe-impact storm, such as a hurricane or blizzard, is imminent in our service area to encourage you to prepare for potential outages.", comment: "")
        case .comEd:
            return NSLocalizedString("Receive an alert about weather conditions that could potentially impact ComEd service in your area.", comment: "")
        case .peco:
            return NSLocalizedString("Receive an alert about weather conditions that could potentially impact PECO service in your area.", comment: "")
        }
    }
    
    var billReadyDetailLabelText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Receive an alert when your bill is ready to be viewed online. This alert will contain the bill due date and amount due.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Receive an alert when your monthly bill is ready to be viewed online. By choosing to receive this notification, you will no longer receive a paper bill through the mail.", comment: "")
        }
    }
    
    var paymentDueDetailLabelText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Choose to receive an alert 1 to 14 days before your payment due date. Customers are responsible for payment for the total amount due on their account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
        case .comEd:
            return NSLocalizedString("Receive an alert 1 to 7 days before your payment due date. If enrolled in AutoPay, the alert will notify you of when a payment will be deducted from your bank account.", comment: "")
        case .peco:
            return NSLocalizedString("Receive an alert 1 to 7 days before your payment due date. If enrolled in AutoPay, the alert will notify you of when a payment will be deducted from your bank account.\nNOTE: You are responsible for payment of the total amount due on your account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
        }
    }
    
    var budgetBillingDetailLabelText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return nil
        case .comEd:
            return NSLocalizedString("Your monthly Budget Bill Payment may be adjusted every six months to keep your account current with your actual electricity usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
        case .peco:
            return NSLocalizedString("Your monthly Budget Bill payment may be adjusted every four months to keep your account current with your actual energy usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
        }
    }
    
    var forYourInfoDetailLabelText: String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Occasionally, BGE may contact you with general information such as tips for saving energy or company-sponsored alerts or events occurring in your neighborhood.", comment: "")
        case .comEd:
            return NSLocalizedString("Occasionally, ComEd may contact you with general information such as tips for saving energy or company-sponsored alerts or events occurring in your neighborhood.", comment: "")
        case .peco:
            return NSLocalizedString("Occasionally, PECO may contact you with general information such as tips for saving energy or company-sponsored alerts or events occurring in your neighborhood.", comment: "")
        }
    }
    
    

}
