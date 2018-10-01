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
    
    private let accountService: AccountService
    private let alertsService: AlertsService
    private let billService: BillService
    
    var accountDetail: AccountDetail! // Passed from AlertsViewController
    
    var sections: [(String, [AlertPreferencesOptions])] = []
    
    // Notification Preferences
    let outage = Variable(false)
    let scheduledMaint = Variable(false)
    let severeWeather = Variable(false)
    let billReady = Variable(false)
    let paymentDue = Variable(false)
    let paymentDueDaysBefore = Variable(1)
    let budgetBilling = Variable(false)
    let forYourInfo = Variable(false)
    let english = Variable(true) // Language selection. False = Spanish
    
    let isError = Variable(false)
    let alertPrefs = Variable<AlertPreferences?>(nil)
    
    var initialBillReadyValue = false
    var initialEnglishValue = true
    
    var shouldEnrollPaperlessEBill: Bool {
        if Environment.shared.opco == .bge { return false }
        return initialBillReadyValue == false && billReady.value == true
    }
    
    var devicePushNotificationsEnabled = false
    
    required init(alertsService: AlertsService, billService: BillService, accountService: AccountService) {
        self.alertsService = alertsService
        self.billService = billService
        self.accountService = accountService
    }
    
    // MARK: Web Services
    
    func fetchData(onCompletion: @escaping () -> Void) {
        isError.value = false
        
        var observables = [fetchAccountDetail(), fetchAlertPreferences()]
        if Environment.shared.opco == .comEd {
            observables.append(fetchAlertLanguage())
        }
        
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                switch Environment.shared.opco {
                case .bge:
                    self.sections = [
                        (NSLocalizedString("Outage", comment: ""),
                         [.outage, .scheduledMaintenanceOutage, .severeWeather]),
                        (NSLocalizedString("Billing", comment: ""),
                         [.billIsReady]),
                        (NSLocalizedString("Payment", comment: ""),
                         [.paymentDueReminder]),
                        (NSLocalizedString("News", comment: ""),
                         [.forYourInformation])
                    ]
                case .comEd, .peco:
                    self.sections = [(NSLocalizedString("Outage", comment: ""),
                                      [.outage, .severeWeather])]
                    
                    if self.accountDetail.isResidential && !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady]))
                    }
                    
                    var paymentOptions = [AlertPreferencesOptions.paymentDueReminder]
                    if !self.accountDetail.isBudgetBillEnrollment {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("News", comment: ""), [.forYourInformation]))
                }
                
                onCompletion()
            }, onError: { [weak self] err in
                self?.isError.value = true
                onCompletion()
            })
            .disposed(by: disposeBag)
    }
    
    func fetchAccountDetail() -> Observable<Void> {
        return accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] accountDetail in
                self?.accountDetail = accountDetail
            })
            .mapTo(())
    }
    
    private func fetchAlertPreferences() -> Observable<Void> {
        return alertsService
            .fetchAlertPreferences(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
            .do(onNext: { [weak self] alertPrefs in
                guard let self = self else { return }
                
                self.alertPrefs.value = alertPrefs
                self.outage.value = alertPrefs.outage
                self.scheduledMaint.value = alertPrefs.scheduledMaint
                self.severeWeather.value = alertPrefs.severeWeather
                self.billReady.value = alertPrefs.billReady
                self.initialBillReadyValue = alertPrefs.billReady
                self.paymentDue.value = alertPrefs.paymentDue
                self.paymentDueDaysBefore.value = alertPrefs.paymentDueDaysBefore
                self.budgetBilling.value = alertPrefs.budgetBilling
                self.forYourInfo.value = alertPrefs.forYourInfo
            })
            .mapTo(())
    }
    
    private func fetchAlertLanguage() -> Observable<Void> {
        return alertsService
            .fetchAlertLanguage(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
            .do(onNext: { [weak self] language in
                self?.initialEnglishValue = language == "English"
                self?.english.value = language == "English"
            })
            .mapTo(())
    }
    
    func saveChanges(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var observables = [saveAlertPreferences()]
        if Environment.shared.opco == .comEd && english.value != initialEnglishValue {
            observables.append(saveAlertLanguage())
        }
        
        if shouldEnrollPaperlessEBill {
            observables.append(enrollPaperlessEBill())
        }
        
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(NSLocalizedString("We’re sorry, we could not update all of your preferences at this time. Please try again later or contact our Customer Care Center for assistance.", comment: ""))
            })
            .disposed(by: disposeBag)
    }
    
    private lazy var mainPrefsChanged = Observable
        .combineLatest(outage.asObservable(),
                       scheduledMaint.asObservable(),
                       severeWeather.asObservable(),
                       billReady.asObservable(),
                       paymentDue.asObservable(),
                       paymentDueDaysBefore.asObservable(),
                       budgetBilling.asObservable(),
                       forYourInfo.asObservable())
        .map {
            AlertPreferences(outage: $0,
                             scheduledMaint: $1,
                             severeWeather: $2,
                             billReady: $3,
                             paymentDue: $4,
                             paymentDueDaysBefore: $5,
                             budgetBilling: $6,
                             forYourInfo: $7)
        }
        .withLatestFrom(alertPrefs.asObservable().unwrap())
        { $0.isDifferent(fromOriginal: $1) }
    
    private lazy var languagePrefChanged = english.asObservable()
        .map { [weak self] in $0 != self?.initialEnglishValue ?? false }
    
    private(set) lazy var prefsChanged = Observable
        .combineLatest(mainPrefsChanged, languagePrefChanged)
        { $0 || $1 }
        .startWith(false)
        .share(replay: 1, scope: .forever)
    
    private func saveAlertPreferences() -> Observable<Void> {
        let alertPreferences = AlertPreferences(outage: outage.value,
                                                scheduledMaint: scheduledMaint.value,
                                                severeWeather: severeWeather.value,
                                                billReady: billReady.value,
                                                paymentDue: paymentDue.value,
                                                paymentDueDaysBefore: paymentDueDaysBefore.value,
                                                budgetBilling: budgetBilling.value,
                                                forYourInfo: forYourInfo.value)
        return alertsService
            .setAlertPreferences(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                 alertPreferences: alertPreferences)
    }
    
    private func saveAlertLanguage() -> Observable<Void> {
        return alertsService
            .setAlertLanguage(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                              english: english.value)
    }
    
    private func enrollPaperlessEBill() -> Observable<Void> {
        return billService
            .enrollPaperlessBilling(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                    email: accountDetail.customerInfo.emailAddress)
    }
    
    private(set) lazy var saveButtonEnabled: Driver<Bool> = prefsChanged.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var paymentDueDaysBeforeButtonText: Driver<String> = self.paymentDueDaysBefore.asDriver().map {
        if $0 == 1 {
            return NSLocalizedString("1 Day Before", comment: "")
        }
        return String(format: NSLocalizedString("%d Days Before", comment: ""), $0)
    }
    
    var showAccountInfoBar: Bool {
        switch Environment.shared.opco {
        case .bge:
            return false
        case .comEd, .peco:
            return true
        }
    }
    
    var showNotificationSettingsView: Bool {
        return !devicePushNotificationsEnabled
    }
    
    var showTopSection: Bool {
        return showAccountInfoBar || showNotificationSettingsView
    }
    
    var showLanguageSection: Bool {
        switch Environment.shared.opco {
        case .comEd:
            return true
        case .bge, .peco:
            return false
        }
    }
    
    // MARK: Detail Label Strings
    
    var outageDetailLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Receive updates on unplanned outages due to storms.", comment: "")
        case .comEd:
            return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.\n\nNOTE: Outage Notifications will be provided by ComEd on a 24/7 basis. You may be updated with outage information during the overnight hours or over holidays where applicable.", comment: "")
        case .peco:
            return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.", comment: "")
        }
    }
    
    var scheduledMaintDetailLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("From time to time, BGE must temporarily stop service in order to perform system maintenance or repairs. BGE typically informs customers of planned outages in their area by letter, however, in emergency situations we can inform customers by push notification. Planned outage information will also be available on the planned outages web page on BGE.com.", comment: "")
        case .comEd, .peco:
            return nil
        }
    }
    
    var severeWeatherDetailLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("BGE may choose to contact you if a severe-impact storm, such as a hurricane or blizzard, is imminent in our service area to encourage you to prepare for potential outages.", comment: "")
        case .comEd:
            return NSLocalizedString("Receive an alert about weather conditions that could potentially impact ComEd service in your area.", comment: "")
        case .peco:
            return NSLocalizedString("Receive an alert about weather conditions that could potentially impact PECO service in your area.", comment: "")
        }
    }
    
    var billReadyDetailLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Receive an alert when your bill is ready to be viewed online. This alert will contain the bill due date and amount due.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Receive an alert when your monthly bill is ready to be viewed online. By choosing to receive this notification, you will no longer receive a paper bill through the mail.", comment: "")
        }
    }
    
    var paymentDueDetailLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Choose to receive an alert 1 to 14 days before your payment due date. Customers are responsible for payment for the total amount due on their account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Receive an alert 1 to 7 days before your payment due date. If enrolled in AutoPay, the alert will notify you of when a payment will be deducted from your bank account.\n\nNOTE: You are responsible for payment of the total amount due on your account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
        }
    }
    
    var budgetBillingDetailLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return nil
        case .comEd:
            return NSLocalizedString("Your monthly Budget Bill Payment may be adjusted every six months to keep your account current with your actual electricity usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
        case .peco:
            return NSLocalizedString("Your monthly Budget Bill payment may be adjusted every four months to keep your account current with your actual energy usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
        }
    }
    
    var forYourInfoDetailLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Occasionally, BGE may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
        case .comEd:
            return NSLocalizedString("Occasionally, ComEd may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
        case .peco:
            return NSLocalizedString("Occasionally, PECO may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
        }
    }
    
    enum AlertPreferencesOptions {
        // Outage
        case outage, scheduledMaintenanceOutage, severeWeather
        // Billing
        case billIsReady
        // Payment
        case paymentDueReminder, budgetBillingReview
        // News
        case forYourInformation
        
        var titleText: String {
            switch self {
            case .outage:
                return NSLocalizedString("Outage", comment: "")
            case .scheduledMaintenanceOutage:
                return NSLocalizedString("Scheduled Maintenance Outage", comment: "")
            case .severeWeather:
                return NSLocalizedString("Severe Weather", comment: "")
            case .billIsReady:
                return NSLocalizedString("Bill is Ready", comment: "")
            case .paymentDueReminder:
                return NSLocalizedString("Payment Due Reminder", comment: "")
            case .budgetBillingReview:
                return NSLocalizedString("Budget Billing Review", comment: "")
            case .forYourInformation:
                return NSLocalizedString("For Your Information", comment: "")
            }
        }
        
        var detailText: String {
            switch (self, Environment.shared.opco) {
                
            // Outage
            case (.outage, .bge):
                return NSLocalizedString("Receive updates on unplanned outages due to storms.", comment: "")
            case (.outage, .comEd):
                return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.\n\nNOTE: Outage Notifications will be provided by ComEd on a 24/7 basis. You may be updated with outage information during the overnight hours or over holidays where applicable.", comment: "")
            case (.outage, .peco):
                return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.", comment: "")
                
            // Scheduled Maintenance Outage
            case (.scheduledMaintenanceOutage, _):
                return NSLocalizedString("From time to time, BGE must temporarily stop service in order to perform system maintenance or repairs. BGE typically informs customers of planned outages in their area by letter, however, in emergency situations we can inform customers by push notification. Planned outage information will also be available on the planned outages web page on BGE.com.", comment: "")
                
            // Severe Weather
            case (.severeWeather, .bge):
                return NSLocalizedString("BGE may choose to contact you if a severe-impact storm, such as a hurricane or blizzard, is imminent in our service area to encourage you to prepare for potential outages.", comment: "")
            case (.severeWeather, .comEd):
                return NSLocalizedString("Receive an alert about weather conditions that could potentially impact ComEd service in your area.", comment: "")
            case (.severeWeather, .peco):
                return NSLocalizedString("Receive an alert about weather conditions that could potentially impact PECO service in your area.", comment: "")
                
            // Bill is Ready
            case (.billIsReady, .bge):
                return NSLocalizedString("Receive an alert when your bill is ready to be viewed online. This alert will contain the bill due date and amount due.", comment: "")
            case (.billIsReady, .comEd): fallthrough
            case (.billIsReady, .peco):
                return NSLocalizedString("Receive an alert when your monthly bill is ready to be viewed online. By choosing to receive this notification, you will no longer receive a paper bill through the mail.", comment: "")
                
            // Payment Due Reminder
            case (.paymentDueReminder, .bge):
                return NSLocalizedString("Choose to receive an alert 1 to 14 days before your payment due date. Customers are responsible for payment for the total amount due on their account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
            case (.paymentDueReminder, .comEd): fallthrough
            case (.paymentDueReminder, .peco):
                return NSLocalizedString("Receive an alert 1 to 7 days before your payment due date. If enrolled in AutoPay, the alert will notify you of when a payment will be deducted from your bank account.\n\nNOTE: You are responsible for payment of the total amount due on your account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
                
            // Budget Billing Review
            case (.budgetBillingReview, .bge):
                return ""
            case (.budgetBillingReview, .comEd):
                return NSLocalizedString("Your monthly Budget Bill Payment may be adjusted every six months to keep your account current with your actual electricity usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
            case (.budgetBillingReview, .peco):
                return NSLocalizedString("Your monthly Budget Bill payment may be adjusted every four months to keep your account current with your actual energy usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
                
            // For Your Information
            case (.forYourInformation, .bge):
                return NSLocalizedString("Occasionally, BGE may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            case (.forYourInformation, .comEd):
                return NSLocalizedString("Occasionally, ComEd may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            case (.forYourInformation, .peco):
                return NSLocalizedString("Occasionally, PECO may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            }
        }
    }
}



