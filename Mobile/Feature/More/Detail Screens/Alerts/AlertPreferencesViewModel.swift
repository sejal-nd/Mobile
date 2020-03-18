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
    var shownSections = Set<Int>() // Set of section numbers that should be expanded
    
    // Notification Preferences
    let highUsage = BehaviorRelay(value: false)
    let billThreshold: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let billThresholdPlacheHolder = BehaviorRelay(value: "Bill Threshold (Optional)")
    let peakTimeSavings = BehaviorRelay(value: false)
    let smartEnergyRewards = BehaviorRelay(value: false)
    let energySavingsDayResults = BehaviorRelay(value: false)
    
    let outage = BehaviorRelay(value: false)
    let scheduledMaint = BehaviorRelay(value: false)
    let severeWeather = BehaviorRelay(value: false)
    let billReady = BehaviorRelay(value: false)
    let paymentDue = BehaviorRelay(value: false)
    let paymentDueDaysBefore = BehaviorRelay(value: 1)
    let paymentPosted = BehaviorRelay(value: false)
    let paymentPastDue = BehaviorRelay(value: false)
    let budgetBilling = BehaviorRelay(value: false)
    let appointmentTracking = BehaviorRelay(value: false)
    let forYourInfo = BehaviorRelay(value: false)
    let energyBuddyUpdates = BehaviorRelay(value: false)
    let english = BehaviorRelay(value: true) // Language selection. False = Spanish
    
    var hasPreferencesChanged = BehaviorRelay(value: false)
    
    let isError = BehaviorRelay(value: false)
    let alertPrefs = BehaviorRelay<AlertPreferences?>(value: nil)
    
    var initialBillReadyValue = false
    var initialEnglishValue = true
    var initialEnergyBuddyUpdatesValue = UserDefaults.standard.bool(forKey: UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference)
    var initialBillThresholdValue = ""
    
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
    
    func toggleSectionVisibility(_ section: Int) {
        if !shownSections.contains(section) {
            shownSections.insert(section)
        } else {
            shownSections.remove(section)
        }
    }
    
    // MARK: Web Services
    
    func fetchData(onCompletion: @escaping () -> Void) {
        isError.accept(false)
        
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
                    let showHighUsageSection = self.accountDetail.isAMIAccount && !self.accountDetail.isFinaled && !self.accountDetail.isBGEControlGroup
                    
                    var usageOptions: [AlertPreferencesOptions] = []
                    if showHighUsageSection {
                        usageOptions.append(.highUsage)
                    }
                    
                    if self.accountDetail.isSERAccount {
                        usageOptions.append(contentsOf: [.smartEnergyRewards, .energySavingsDayResults])
                    }
                    
                    self.sections = [
                        (NSLocalizedString("Usage", comment: ""), usageOptions),
                        (NSLocalizedString("Outage", comment: ""),
                         [.outage, .scheduledMaintenanceOutage, .severeWeather]),
                        (NSLocalizedString("Billing", comment: ""),
                         [.billIsReady]),
                        (NSLocalizedString("Payment", comment: ""),
                         [.paymentDueReminder, .paymentPosted, .paymentPastDue]),
                        (NSLocalizedString("Customer Appointments", comment: ""),
                         [.appointmentTracking]),
                        (NSLocalizedString("News", comment: ""),
                         [.forYourInformation])
                    ]
                    let isGameUser = UserDefaults.standard.string(forKey: UserDefaultKeys.gameAccountNumber) != nil
                    if isGameUser {
                        self.sections.append((NSLocalizedString("BGE's Play-n-Save Pilot", comment: ""), [.energyBuddyUpdates]))
                    }
                case .comEd:
                    let showHighUsageSection = self.accountDetail.isAMIAccount && !self.accountDetail.isFinaled
                    
                    var usageOptions: [AlertPreferencesOptions] = []
                    if showHighUsageSection {
                        usageOptions.append(.highUsage)
                    }
                    
                    if self.accountDetail.isPTSAccount {
                        usageOptions.append(.peakTimeSavings)
                    }
                    
                    self.sections = [
                        (NSLocalizedString("Usage", comment: ""), usageOptions),
                        (NSLocalizedString("Outage", comment: ""), [.outage, .severeWeather])]
                    
                    if self.accountDetail.isResidential && !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady]))
                    }
                    
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentDueReminder, .paymentPosted, .paymentPastDue]
                    if self.accountDetail.isBudgetBillEnrollment {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("Customer Appointments", comment: ""), [.appointmentTracking]))
                    self.sections.append((NSLocalizedString("News", comment: ""), [.forYourInformation]))
                    
                case .peco:
                    self.sections = [
                        (NSLocalizedString("Usage", comment: ""),
                         [.highUsage]),
                        (NSLocalizedString("Outage", comment: ""),
                         [.outage, .severeWeather])]
                    
                    if self.accountDetail.isResidential && !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady]))
                    }
                    
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentDueReminder, .paymentPosted, .paymentPastDue]
                    if self.accountDetail.isBudgetBillEnrollment {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("Customer Appointments", comment: ""), [.appointmentTracking]))
                    self.sections.append((NSLocalizedString("News", comment: ""), [.forYourInformation]))
                }
                
                onCompletion()
            }, onError: { [weak self] err in
                self?.isError.accept(true)
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
                
                self.highUsage.accept(alertPrefs.usage)
                if let threshold = alertPrefs.alertThreshold {
                    self.initialBillThresholdValue = String(threshold)
                    self.billThreshold.accept(String(threshold))
                }
                
                self.alertPrefs.accept(alertPrefs)
                self.outage.accept(alertPrefs.outage)
                self.scheduledMaint.accept(alertPrefs.scheduledMaint)
                self.severeWeather.accept(alertPrefs.severeWeather)
                self.billReady.accept(alertPrefs.billReady)
                
                self.initialBillReadyValue = alertPrefs.billReady
                self.paymentDue.accept(alertPrefs.paymentDue)
                self.paymentDueDaysBefore.accept(alertPrefs.paymentDueDaysBefore)
                self.paymentPosted.accept(alertPrefs.paymentPosted)
                self.paymentPastDue.accept(alertPrefs.paymentPastDue)
                self.budgetBilling.accept(alertPrefs.budgetBilling)
                self.appointmentTracking.accept(alertPrefs.appointmentTracking)
                self.forYourInfo.accept(alertPrefs.forYourInfo)
                self.energyBuddyUpdates.accept(UserDefaults.standard.bool(forKey: UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference))
            })
            .mapTo(())
    }
    
    private func fetchAlertLanguage() -> Observable<Void> {
        return alertsService
            .fetchAlertLanguage(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
            .do(onNext: { [weak self] language in
                self?.initialEnglishValue = language == "English"
                self?.english.accept(language == "English")
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
        
        UserDefaults.standard.set(energyBuddyUpdates.value, forKey: UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference)
        if !energyBuddyUpdates.value {
            FirebaseUtility.logEvent(.gamification, parameters: [EventParameter(parameterName: .action, value: .push_opt_out)])
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["game_weekly_reminder"])
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
    
    private lazy var paymentDaysBeforeChanged = paymentDueDaysBefore.asObservable()
        .withLatestFrom(alertPrefs.asObservable().unwrap())
        { $0 != $1.paymentDueDaysBefore }
    
    private lazy var booleanPrefsChanged = Observable<Bool>
        .combineLatest([highUsage.asObservable(),
                        peakTimeSavings.asObservable(),
                        smartEnergyRewards.asObservable(),
                        energySavingsDayResults.asObservable(),
                        outage.asObservable(),
                        scheduledMaint.asObservable(),
                        severeWeather.asObservable(),
                        billReady.asObservable(),
                        paymentDue.asObservable(),
                        paymentPosted.asObservable(),
                        paymentPastDue.asObservable(),
                        budgetBilling.asObservable(),
                        appointmentTracking.asObservable(),
                        forYourInfo.asObservable()])
        .map { prefs in
            AlertPreferences(usage: prefs[0],
                             peakTimeSavings: prefs[1],
                             smartEnergyRewards: prefs[2],
                             energySavingsDayResults: prefs[3],
                             outage: prefs[4],
                             scheduledMaint: prefs[5],
                             severeWeather: prefs[6],
                             billReady: prefs[7],
                             paymentDue: prefs[8],
                             paymentDueDaysBefore: 0,
                             paymentPosted: prefs[9],
                             paymentPastDue: prefs[10],
                             budgetBilling: prefs[11],
                             appointmentTracking: prefs[12],
                             forYourInfo: prefs[13])
    }
    .withLatestFrom(alertPrefs.asObservable().unwrap())
    { $0.isDifferent(fromOriginal: $1) }
    
    private lazy var billThresholdPrefChanged = billThreshold.asObservable()
        .map { [weak self] in
            return $0 ?? "" != self?.initialBillThresholdValue ?? ""
    }
    
    private lazy var languagePrefChanged = english.asObservable()
        .map { [weak self] in $0 != self?.initialEnglishValue ?? false }
    
    private lazy var energyBuddyUpdatesPrefChanged = energyBuddyUpdates.asObservable()
        .map { [weak self] in $0 != self?.initialEnergyBuddyUpdatesValue ?? false }
    
    private(set) lazy var prefsChanged = Observable
        .combineLatest(booleanPrefsChanged, paymentDaysBeforeChanged, languagePrefChanged, energyBuddyUpdatesPrefChanged, billThresholdPrefChanged)
        { $0 || $1 || $2 || $3 || $4 }
        .startWith(false)
        .share(replay: 1, scope: .forever)
    
    private func saveAlertPreferences() -> Observable<Void> {
        let alertPreferences = AlertPreferences(usage: highUsage.value,
                                                alertThreshold: Int(billThreshold.value ?? ""),
                                                peakTimeSavings: peakTimeSavings.value,
                                                smartEnergyRewards: smartEnergyRewards.value,
                                                energySavingsDayResults: energySavingsDayResults.value,
                                                outage: outage.value,
                                                scheduledMaint: scheduledMaint.value,
                                                severeWeather: severeWeather.value,
                                                billReady: billReady.value,
                                                paymentDue: paymentDue.value,
                                                paymentDueDaysBefore: paymentDueDaysBefore.value,
                                                paymentPosted: paymentPosted.value,
                                                paymentPastDue: paymentPastDue.value,
                                                budgetBilling: budgetBilling.value,
                                                appointmentTracking: appointmentTracking.value,
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
    
    enum AlertPreferencesOptions {
        // Usage
        case highUsage, peakTimeSavings, smartEnergyRewards, energySavingsDayResults
        // Outage
        case outage, scheduledMaintenanceOutage, severeWeather
        // Billing
        case billIsReady
        // Payment
        case paymentDueReminder, paymentPosted, paymentPastDue, budgetBillingReview
        // Customer Appointments
        case appointmentTracking
        // News
        case forYourInformation
        // Energy Buddy
        case energyBuddyUpdates
        
        var titleText: String {
            switch self {
            case .highUsage:
                return NSLocalizedString("High Usage", comment: "")
            case .peakTimeSavings:
                return NSLocalizedString("Peak Time Savings", comment: "")
            case .smartEnergyRewards:
                return NSLocalizedString("Smart Energy Rewards", comment: "")
            case .energySavingsDayResults:
                return NSLocalizedString("Energy Savings Day Results", comment: "")
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
            case .paymentPosted:
                return NSLocalizedString("Payment Posted", comment: "")
            case .paymentPastDue:
                return NSLocalizedString("Payment Past Due", comment: "")
            case .budgetBillingReview:
                return NSLocalizedString("Budget Billing Review", comment: "")
            case .appointmentTracking:
                return NSLocalizedString("Appointment Tracking", comment: "")
            case .forYourInformation:
                return NSLocalizedString("For Your Information", comment: "")
            case .energyBuddyUpdates:
                return NSLocalizedString("Lumi Updates", comment: "")
            }
        }
        
        var detailText: String {
            switch (self, Environment.shared.opco) {
                
                // High Usage
            case (.highUsage, .bge): fallthrough
            case (.highUsage, .peco): fallthrough
            case (.highUsage, .comEd):
                return NSLocalizedString("Receive an alert if you are headed towards a bill that is higher than usual. This alert gives you time to reduce your usage before your next bill and helps to prevent billing surprises.", comment: "")
                
            // Peak Time Savings
            case (.peakTimeSavings, .bge): fallthrough
            case (.peakTimeSavings, .peco):
                return ""
            case (.peakTimeSavings, .comEd):
                return NSLocalizedString("Receive an alert on the day Peak Time Savings Hours occur — as early as 9 a.m. or at least 30 minutes prior to the start of the event.", comment: "")
                
            // Smart Energy Rewards
            case (.smartEnergyRewards, .bge):
                return NSLocalizedString("BGE may notify you up to 6 times per summer of an upcoming Energy Savings Day. Earn $1.25 for every kilowatt-hour you reduce on an Energy Savings Day compared to your typical usage on days with similar weather.", comment: "")
            case (.smartEnergyRewards, .peco): fallthrough
            case (.smartEnergyRewards, .comEd):
                return ""
                
            // Smart Energy Rewards
            case (.energySavingsDayResults, .bge):
                return NSLocalizedString("BGE may notify you following an Energy Savings Day to let you know how much you saved. Your credits will automatically appear on your next bill.", comment: "")
            case (.energySavingsDayResults, .peco): fallthrough
            case (.energySavingsDayResults, .comEd):
                return ""
                
            // Outage
            case (.outage, .bge):
                return NSLocalizedString("Receive updates on unplanned outages due to storms.", comment: "")
            case (.outage, .comEd):
                return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.\n\nNOTE: Outage Notifications will be provided by ComEd on a 24/7 basis. You may be updated with outage information during the overnight hours or over holidays where applicable.", comment: "")
            case (.outage, .peco):
                return NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.", comment: "")
                
            // Scheduled Maintenance Outage
            case (.scheduledMaintenanceOutage, .bge):
                return NSLocalizedString("From time to time, BGE must temporarily stop service in order to perform system maintenance or repairs. BGE typically informs customers of planned outages in their area by letter, however, in emergency situations we can inform customers by push notification. Planned outage information will also be available on the planned outages web page on BGE.com.", comment: "")
            case (.scheduledMaintenanceOutage, .comEd): fallthrough
            case (.scheduledMaintenanceOutage, .peco):
                return ""
                
            // Severe Weather
            case (.severeWeather, .bge):
                return NSLocalizedString("BGE may choose to contact you if a severe-impact storm, such as a hurricane or blizzard, is imminent in our service area to encourage you to prepare for potential outages.", comment: "")
            case (.severeWeather, .comEd):
                return NSLocalizedString("Receive an alert about weather conditions that could potentially impact ComEd service in your area.", comment: "")
            case (.severeWeather, .peco):
                return NSLocalizedString("Receive an alert about weather conditions that could potentially impact PECO service in your area.", comment: "")
                
            // Bill is Ready
            case (.billIsReady, .bge):
                return NSLocalizedString("Receive an alert when your bill is ready to be viewed online. This alert will contain the bill due date and total amount due.", comment: "")
            case (.billIsReady, .comEd): fallthrough
            case (.billIsReady, .peco):
                return NSLocalizedString("Receive an alert when your monthly bill is ready to be viewed online. By choosing to receive this notification, you will no longer receive a paper bill through the mail.", comment: "")
                
            // Payment Due Reminder
            case (.paymentDueReminder, .bge):
                return NSLocalizedString("Choose to receive an alert 1 to 14 days before your payment due date. Customers are responsible for payment for the total amount due on their account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
            case (.paymentDueReminder, .comEd): fallthrough
            case (.paymentDueReminder, .peco):
                return NSLocalizedString("Receive an alert 1 to 7 days before your payment due date. If enrolled in AutoPay, the alert will notify you of when a payment will be deducted from your bank account.\n\nNOTE: You are responsible for payment of the total amount due on your account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
                
            // Payment Posted
            case (.paymentPosted, _):
                return NSLocalizedString("Receive a confirmation when your payment has posted to your account. We will include the date and the amount of the posting, as well as your updated total account balance.", comment: "")
                
            // Payment Past Due
            case (.paymentPastDue, _):
                return NSLocalizedString("Receive a friendly reminder 1 day after your due date when you are late in making a payment.", comment: "")
                
            // Budget Billing Review
            case (.budgetBillingReview, .bge):
                return ""
            case (.budgetBillingReview, .comEd):
                return NSLocalizedString("Your monthly Budget Bill Payment may be adjusted every six months to keep your account current with your actual electricity usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
            case (.budgetBillingReview, .peco):
                return NSLocalizedString("Your monthly Budget Bill payment may be adjusted every four months to keep your account current with your actual energy usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
                
            // Appointment Tracking
            case (.appointmentTracking, _):
                return NSLocalizedString("Receive notifications such as confirmations, reminders, and relevant status updates for your scheduled service appointment.", comment: "")
                
            // For Your Information
            case (.forYourInformation, .bge):
                return NSLocalizedString("Occasionally, BGE may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            case (.forYourInformation, .comEd):
                return NSLocalizedString("Occasionally, ComEd may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            case (.forYourInformation, .peco):
                return NSLocalizedString("Occasionally, PECO may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
                
            // Energy Buddy
            case (.energyBuddyUpdates, _):
                return NSLocalizedString("Receive a notification when Lumi has new data, tips, and insights to help you save energy and money.", comment: "")
            }
        }
    }
    
    struct AlertPrefTextFieldOptions {
        var text: String?
        var placeholder: String?
        var showToolTip = false
        var textFieldType: TextFieldType
        
        enum TextFieldType {
            case string
            case number
            case decimal
            case currency
        }
        
        init(text: String? = nil, placeHolder: String? = nil, showToolTip: Bool = false, textFieldType: TextFieldType = .string) {
            self.text = text
            self.placeholder = placeHolder
            self.showToolTip = showToolTip
            self.textFieldType = textFieldType
        }
    }
}



