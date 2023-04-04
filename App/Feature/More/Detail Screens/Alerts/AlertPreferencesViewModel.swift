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
    
    var sections: [(String, [AlertPreferencesOptions])] = []
    var shownSections = Set<Int>() // Set of section numbers that should be expanded
    
    // Notification Preferences
    let highUsage = BehaviorRelay(value: false)
    let billThreshold: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    let billThresholdPlacheHolder = BehaviorRelay(value: "Bill Threshold (Optional)")
    let peakTimeSavings = BehaviorRelay(value: false)
    let peakSavingsDayAlert = BehaviorRelay(value: false)
    let peakSavingsDayResults = BehaviorRelay(value: false)

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
    let advancedNotification = BehaviorRelay(value: false)
    let forYourInfo = BehaviorRelay(value: false)
    let energyBuddyUpdates = BehaviorRelay(value: false)
    let english = BehaviorRelay(value: true) // Language selection. False = Spanish
    let grantStatus = BehaviorRelay(value: false)
    
    var hasPreferencesChanged = BehaviorRelay(value: false)
    
    let isError = BehaviorRelay(value: false)
    let alertPrefs = BehaviorRelay<AlertPreferences?>(value: nil)
    
    var initialBillReadyValue = false
    var initialEnglishValue = true
    var initialEnergyBuddyUpdatesValue = UserDefaults.standard.bool(forKey: UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference)
    var initialBillThresholdValue = ""
    var initiatedFromOutageView = false
    
    var shouldEnrollPaperlessEBill: Bool {
        if Configuration.shared.opco == .bge { return false }
        // enroll in paperless if not already enrolled and enrolling in "Bill is Ready' alerts
        return !accountDetail.isEBillEnrollment && (initialBillReadyValue == false && billReady.value == true)
    }
    
    var shouldShowHUABillThreshold: Bool {
        return !accountDetail.isBudgetBill && !accountDetail.hasThirdPartySupplier
    }
    
    var devicePushNotificationsEnabled = false
    
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
        if Configuration.shared.opco == .comEd {
            observables.append(fetchAlertLanguage())
        }
        
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                switch Configuration.shared.opco {
                case .bge:
                    var usageOptions: [AlertPreferencesOptions] = []
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentDueReminder, .paymentPosted, .paymentPastDue]
                    
                    if self.isHUAEligible {
                        usageOptions.append(.highUsage)
                    }
                    
                    if self.isPTREligible {
                        usageOptions.append(contentsOf: [.smartEnergyRewards, .energySavingsDayResults])
                    }
                    
                    if self.isOHEPEligible {
                        paymentOptions.append(.grantStatus)
                    }
                    
                    self.sections = [
                        (NSLocalizedString("Usage", comment: ""), usageOptions),
                        (NSLocalizedString("Outage", comment: ""),
                         [.outage, .scheduledMaintenanceOutage, .severeWeather]),
                        (NSLocalizedString("Billing", comment: ""),
                         [.billIsReady(self.accountDetail)]),
                        (NSLocalizedString("Payment", comment: ""),
                         paymentOptions),
                        (NSLocalizedString("Appointments", comment: ""),
                         [.appointmentTracking]),
                        (NSLocalizedString("News", comment: ""),
                         [.forYourInformation])
                    ]
                    let isGameUser = UserDefaults.standard.string(forKey: UserDefaultKeys.gameAccountNumber) != nil
                    if isGameUser && FeatureFlagUtility.shared.bool(forKey: .isGamificationEnabled) {
                        self.sections.append((NSLocalizedString("BGE's Play-n-Save Pilot", comment: ""), [.energyBuddyUpdates]))
                    }
                case .comEd:
                    var usageOptions: [AlertPreferencesOptions] = []
                    if self.isHUAEligible {
                        usageOptions.append(.highUsage)
                    }
                    
                    if self.isPTSEligible {
                        usageOptions.append(.peakTimeSavings)
                    }
                    
                    self.sections = [
                        (NSLocalizedString("Usage", comment: ""), usageOptions),
                        (NSLocalizedString("Outage", comment: ""), [.outage, .severeWeather])]
                    
                    if self.accountDetail.isResidential && !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady(self.accountDetail)]))
                    }
                    
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentDueReminder, .paymentPosted, .paymentPastDue]
                    if self.accountDetail.isBudgetBill {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("Customer Appointments", comment: ""), [.appointmentTracking]))
                    self.sections.append((NSLocalizedString("News", comment: ""), [.forYourInformation]))
                    
                case .peco:
                    self.sections = [(NSLocalizedString("Outage", comment: ""),
                                      [.outage, .severeWeather])]
                    
                    if self.accountDetail.isResidential && !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady(self.accountDetail)]))
                    }
                    
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentDueReminder, .paymentPosted, .paymentPastDue]
                    if self.accountDetail.isBudgetBill {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("Customer Appointments", comment: ""), [.appointmentTracking]))
                    self.sections.append((NSLocalizedString("News", comment: ""), [.forYourInformation]))
                case .pepco:
                    var usageOptions: [AlertPreferencesOptions] = []
                    if self.isPeakSavingsDayAlertsEligible() {
                        usageOptions.append(.peakSavingsDayAlert)
                        usageOptions.append(.peakSavingsDayResults)
                    }
                    if self.isHUAEligible {
                        usageOptions.append(.highUsage)
                    }
                    self.sections = [(NSLocalizedString("Outage", comment: ""),
                                      [.outage, .severeWeather])]
                    
                    if !usageOptions.isEmpty {
                        self.sections.insert((NSLocalizedString("Usage", comment: ""), usageOptions), at: 0)
                    }
                    
                    if !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady(self.accountDetail)]))
                    }
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentPosted, .paymentPastDue]
                    if self.accountDetail.isBudgetBill && self.accountDetail.isResidential {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("Customer Appointments", comment: ""), [.appointmentTracking, .advancedNotification]))
                    self.sections.append((NSLocalizedString("News", comment: ""), [.forYourInformation]))
                case .ace:
                    var usageOptions: [AlertPreferencesOptions] = []
                    if self.isHUAEligible && FeatureFlagUtility.shared.bool(forKey: .isACEAMI) {
                        usageOptions.append(.highUsage)
                    }
                    self.sections = [(NSLocalizedString("Outage", comment: ""),
                         [.outage, .severeWeather])]
                   
                    if !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady(self.accountDetail)]))
                    }
                    
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentPosted, .paymentPastDue]
                    if self.accountDetail.isBudgetBill && self.accountDetail.isResidential {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("Customer Appointments", comment: ""), [.appointmentTracking, .advancedNotification]))
                    self.sections.append((NSLocalizedString("News", comment: ""), [.forYourInformation]))
                case .delmarva:
                    var usageOptions: [AlertPreferencesOptions] = []
                    if self.isPeakSavingsDayAlertsEligible() {
                        usageOptions.append(.peakSavingsDayAlert)
                        usageOptions.append(.peakSavingsDayResults)
                    }
                    if self.isHUAEligible {
                        usageOptions.append(.highUsage)
                    }
                    self.sections = [(NSLocalizedString("Outage", comment: ""),
                                      [.outage, .severeWeather])]
                    
                    if !usageOptions.isEmpty {
                        self.sections.insert((NSLocalizedString("Usage", comment: ""), usageOptions), at: 0)
                    }

                    if !self.accountDetail.isFinaled &&
                        (self.accountDetail.isEBillEligible || self.accountDetail.isEBillEnrollment) {
                        self.sections.append((NSLocalizedString("Billing", comment: ""),
                                              [.billIsReady(self.accountDetail)]))
                    }
                    
                    var paymentOptions: [AlertPreferencesOptions] = [.paymentPosted, .paymentPastDue]
                    if self.accountDetail.isBudgetBill && self.accountDetail.isResidential {
                        paymentOptions.append(.budgetBillingReview)
                    }
                    
                    self.sections.append((NSLocalizedString("Payment", comment: ""), paymentOptions))
                    self.sections.append((NSLocalizedString("Customer Appointments", comment: ""), [.appointmentTracking, .advancedNotification]))
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
        return AccountService.rx.fetchAccountDetails(alertPreferenceEligibilities: true)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] accountDetail in
                self?.accountDetail = accountDetail
            })
            .mapTo(())
    }
    
    private func fetchAlertPreferences() -> Observable<Void> {
        return AlertService.rx.fetchAlertPreferences(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
            .do(onNext: { [weak self] alertPrefs in
                guard let self = self else { return }
                
                self.alertPrefs.accept(alertPrefs) // original prefs
                
                // usage
                self.highUsage.accept(alertPrefs.highUsage)
                if let threshold = alertPrefs.alertThreshold {
                    self.initialBillThresholdValue = String(threshold)
                    self.billThreshold.accept(String(threshold))
                }
                else {
                    self.initialBillThresholdValue = ""
                    self.billThreshold.accept("")
                }
                self.peakTimeSavings.accept(alertPrefs.peakTimeSavings ?? false)
                self.peakSavingsDayAlert.accept(alertPrefs.peakTimeSavingsDayAlert ?? false)
                self.peakSavingsDayResults.accept(alertPrefs.peakTimeSavingsDayResults ?? false)
                self.smartEnergyRewards.accept(alertPrefs.smartEnergyRewards ?? false)
                self.energySavingsDayResults.accept(alertPrefs.energySavingsDayResults ?? false)
                                
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
                self.advancedNotification.accept(alertPrefs.advancedNotification)
                self.forYourInfo.accept(alertPrefs.forYourInfo)
                self.energyBuddyUpdates.accept(UserDefaults.standard.bool(forKey: UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference))
                self.grantStatus.accept(alertPrefs.grantStatus)
            })
            .mapTo(())
    }
    
    private func fetchAlertLanguage() -> Observable<Void> {
        return AlertService.rx.fetchAlertLanguage(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
            .do(onNext: { [weak self] result in
                let language = result.language
                self?.initialEnglishValue = language == "English"
                self?.english.accept(language == "English")
            })
            .mapTo(())
    }
    
    func saveChanges(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var observables = [saveAlertPreferences()]
        if Configuration.shared.opco == .comEd && english.value != initialEnglishValue {
            observables.append(saveAlertLanguage())
        }
        
        if shouldEnrollPaperlessEBill {
            observables.append(enrollPaperlessEBill())
        }
        
        UserDefaults.standard.set(energyBuddyUpdates.value, forKey: UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference)
        if !energyBuddyUpdates.value {
            FirebaseUtility.logEvent(.gamification(parameters: [.push_opt_out]))
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["game_weekly_reminder"])
        }
        
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .take(1)
            .subscribe(onError: { err in
                onError(NSLocalizedString("We’re sorry, we could not update all of your preferences at this time. Please try again later or contact our Customer Care Center for assistance.", comment: ""))
            }, onCompleted: {
                onSuccess()
            })
            .disposed(by: disposeBag)
    }
    
    private lazy var paymentDaysBeforeChanged = paymentDueDaysBefore.asObservable()
        .withLatestFrom(alertPrefs.asObservable().unwrap())
        { $0 != $1.paymentDueDaysBefore }
    
    private lazy var usagePrefs = Observable.combineLatest([highUsage.asObservable(),
                                                            peakTimeSavings.asObservable(),
                                                            smartEnergyRewards.asObservable(),
                                                            energySavingsDayResults.asObservable(),
                                                            peakSavingsDayAlert.asObservable(),
                                                            peakSavingsDayResults.asObservable()])
    
    private lazy var outagePrefs = Observable.combineLatest([outage.asObservable(),
                                                             scheduledMaint.asObservable(),
                                                             severeWeather.asObservable()])
    
    private lazy var billingPrefs = Observable.combineLatest([billReady.asObservable(),
                                                              budgetBilling.asObservable()])
    
    private lazy var paymentPrefs = Observable.combineLatest([paymentDue.asObservable(),
                                                              paymentPosted.asObservable(),
                                                              paymentPastDue.asObservable(),
                                                              grantStatus.asObservable()])
    
    private lazy var appointmentPrefs = Observable.combineLatest([
        appointmentTracking.asObservable(),
        advancedNotification.asObservable()
    ])
    
    private lazy var newsPrefs = Observable.combineLatest([forYourInfo.asObservable()])
    
    private lazy var newPrefs = Observable
        .combineLatest([usagePrefs, outagePrefs, billingPrefs, paymentPrefs, appointmentPrefs, newsPrefs])
    
    private lazy var booleanPrefsChanged =
        newPrefs
        .map { prefs -> AlertPreferences in
            let usagePrefs = prefs[0]
            let outagePrefs = prefs[1]
            let billingPrefs = prefs[2]
            let paymentPrefs = prefs[3]
            let appointmentPrefs = prefs[4]
            let newsPrefs = prefs[5]
            
            return AlertPreferences(highUsage: usagePrefs[0],
                                    peakTimeSavings: usagePrefs[1],
                                    smartEnergyRewards: usagePrefs[2],
                                    energySavingsDayResults: usagePrefs[3],
                                    outage: outagePrefs[0],
                                    scheduledMaint: outagePrefs[1],
                                    severeWeather: outagePrefs[2],
                                    billReady: billingPrefs[0],
                                    paymentDue: paymentPrefs[0],
                                    paymentDueDaysBefore: 0,
                                    paymentPosted: paymentPrefs[1],
                                    paymentPastDue: paymentPrefs[2],
                                    budgetBilling: billingPrefs[1],
                                    appointmentTracking: appointmentPrefs[0],
                                    advancedNotification: appointmentPrefs[1],
                                    forYourInfo: newsPrefs[0],
                                    grantStatus: paymentPrefs[3])
        }
        .withLatestFrom(alertPrefs.asObservable().unwrap())
            { $0.isDifferent(fromOriginal: $1) }
    
    private lazy var peakSavingsDayAlertChanged = peakSavingsDayAlert.asObservable()
        .withLatestFrom(alertPrefs.asObservable().unwrap())
        { $0 != $1.peakTimeSavingsDayAlert }
    
    private lazy var peakTimeSavingsDayResultsChanged = peakSavingsDayResults.asObservable()
        .withLatestFrom(alertPrefs.asObservable().unwrap())
        { $0 != $1.peakTimeSavingsDayResults }
    
    private lazy var billThresholdPrefChanged = billThreshold.asObservable()
        .map { [weak self] in
            return $0 != self?.initialBillThresholdValue
    }
    
    private lazy var billThresholdValid: Observable<Bool> = billThreshold.asObservable()
        .map { [weak self] in
            var isValid = false
            let thresholdStr = $0 ?? ""
            
            if (!thresholdStr.isEmpty) {
                let amount = Double(thresholdStr) ?? 0.0
                isValid = amount >= 1 && amount <= 10000
            }
            else {
                isValid = true
            }
            
            return isValid
    }
    
    private lazy var languagePrefChanged = english.asObservable()
        .map { [weak self] in $0 != self?.initialEnglishValue ?? false }
    
    private lazy var energyBuddyUpdatesPrefChanged = energyBuddyUpdates.asObservable()
        .map { [weak self] in $0 != self?.initialEnergyBuddyUpdatesValue ?? false }
    
    private(set) lazy var prefsChanged = Observable
        .combineLatest(booleanPrefsChanged, paymentDaysBeforeChanged, languagePrefChanged, energyBuddyUpdatesPrefChanged, billThresholdPrefChanged, peakSavingsDayAlertChanged, peakTimeSavingsDayResultsChanged)
        { $0 || $1 || $2 || $3 || $4 || $5 || $6 }
        .startWith(false)
        .share(replay: 1, scope: .forever)
    
    private(set) lazy var nonLanguagePrefsChanged = Observable // all alert prefs except language
        .combineLatest(booleanPrefsChanged, paymentDaysBeforeChanged, energyBuddyUpdatesPrefChanged, billThresholdPrefChanged, peakSavingsDayAlertChanged, peakTimeSavingsDayResultsChanged)
            { $0 || $1 || $2 || $3 || $4 || $5}
        .share(replay: 1, scope: .forever)
    
    private func saveAlertPreferences() -> Observable<Void> {
        let alertPreferences = AlertPreferences(highUsage: highUsage.value,
                                                alertThreshold: Int(billThreshold.value ?? ""),
                                                previousAlertThreshold: Int(initialBillThresholdValue),
                                                peakTimeSavings: isPTSEligible ? peakTimeSavings.value : nil,
                                                smartEnergyRewards: isPTREligible ? smartEnergyRewards.value : nil,
                                                energySavingsDayResults: isPTREligible ? energySavingsDayResults.value : nil,
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
                                                advancedNotification: advancedNotification.value,
                                                forYourInfo: forYourInfo.value,
                                                peakTimeSavingsDayAlert: peakSavingsDayAlert.value,
                                                peakTimeSavingsDayResults: peakSavingsDayResults.value,
                                                grantStatus: grantStatus.value)
        let alertPreferenceRequest = AlertPreferencesRequest(alertPreferences: alertPreferences)
        
        return nonLanguagePrefsChanged.flatMap {
            return $0 ? AlertService.rx.setAlertPreferences(accountNumber: AccountsStore.shared.currentAccount.accountNumber, request: alertPreferenceRequest) : Observable.just(())
        }
    }
    
    private func saveAlertLanguage() -> Observable<Void> {
        return AlertService.rx.setAlertLanguage(accountNumber: AccountsStore.shared.currentAccount.accountNumber, request: AlertLanguageRequest(language: english.value ? "English" : "Spanish"))
    }
    
    private func isPeakSavingsDayAlertsEligible() -> Bool {
        if let accountDetail = accountDetail {
            let configuration = Configuration.shared.opco
            if configuration == .delmarva {
                return (accountDetail.subOpco == .delmarvaDelaware || accountDetail.subOpco == .delmarvaMaryland) && accountDetail.isResidential && (accountDetail.isPESCEligible ?? false)
            } else if configuration == .pepco {
                return accountDetail.subOpco == .pepcoMaryland && accountDetail.isResidential && (accountDetail.isPESCEligible ?? false)
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    private func enrollPaperlessEBill() -> Observable<Void> {
        return BillService.rx.enrollPaperlessBilling(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                    email: accountDetail.customerInfo.emailAddress)
    }
    
    private(set) lazy var saveButtonEnabled: Driver<Bool> = Observable<Bool>
        .combineLatest(prefsChanged, billThresholdValid)
        { $0 && $1}
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var paymentDueDaysBeforeButtonText: Driver<String> = self.paymentDueDaysBefore.asDriver().map {
        if $0 == 1 {
            return NSLocalizedString("1 Day Before", comment: "")
        }
        return String(format: NSLocalizedString("%d Days Before", comment: ""), $0)
    }
    
    var isHUAEligible: Bool {
        switch Configuration.shared.opco {
        case .bge, .comEd, .pepco, .delmarva:
            return self.accountDetail.isHUAEligible ?? false
        case .peco, .ace:
            return false
        
        }
    }
    
    var isPTSEligible: Bool {
        switch Configuration.shared.opco {
        case .bge, .peco, .pepco, .ace, .delmarva:
            return false
        case .comEd:
            return self.accountDetail.isPTSEligible ?? false
        }
    }
    
    var isPTREligible: Bool {
        switch Configuration.shared.opco {
        case .bge:
            return self.accountDetail.isPTREligible ?? false
        case .comEd, .peco, .pepco, .ace, .delmarva:
            return false
        }
    }
    
    var isOHEPEligible: Bool {
        switch Configuration.shared.opco {
        case .bge:
            return self.accountDetail.isOHEPEligible
        default:
            return false
        }
    }
    
    var showAccountInfoBar: Bool {
        switch Configuration.shared.opco {
        case .ace, .bge, .comEd, .delmarva, .peco, .pepco:
            return true
        }
    }
    
    var billThresholdToolTipText: String {
        switch Configuration.shared.opco {
        case .ace, .delmarva, .pepco:
            return NSLocalizedString("You can optionally set a bill threshold to alert you when your bill is projected to be higher than a specific amount each month. If no selection is made, we will alert you if your usage is 30% higher compared to the same time last year.", comment: "")
        case .bge:
            return NSLocalizedString("You can optionally set a bill threshold to alert you when your bill is projected to be higher than a specific amount each month. If no selection is made, we will alert you if your usage is 30% and $30 higher compared to the same time last year.", comment: "")
        case .comEd:
            return NSLocalizedString("Choose the bill amount that triggers your alert. If no selection is made, we will alert you if your usage is 30% higher compared to the same time last year.", comment: "")
        default:
            return ""
        }
    }
    
    var showNotificationSettingsView: Bool {
        return !devicePushNotificationsEnabled
    }
    
    var showTopSection: Bool {
        return showAccountInfoBar || showNotificationSettingsView
    }
    
    var showLanguageSection: Bool {
        switch Configuration.shared.opco {
        case .comEd:
            return true
        case .bge, .peco, .pepco, .ace, .delmarva:
            return false
        }
    }
    
    enum AlertPreferencesOptions {
        // Usage
        case highUsage, peakTimeSavings, smartEnergyRewards, energySavingsDayResults, peakSavingsDayAlert, peakSavingsDayResults
        // Outage
        case outage, scheduledMaintenanceOutage, severeWeather
        // Billing
        case billIsReady(AccountDetail)
        // Payment
        case paymentDueReminder, paymentPosted, paymentPastDue, budgetBillingReview, grantStatus
        // Customer Appointments
        case appointmentTracking
        // Advance Notification
        case advancedNotification
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
            case .peakSavingsDayAlert:
                return NSLocalizedString("Peak Savings Day Alert", comment: "")
            case .peakSavingsDayResults:
                return NSLocalizedString("Peak Savings Day Results", comment: "")
            case .smartEnergyRewards:
                return NSLocalizedString("Energy Savings Day Alert", comment: "")
            case .energySavingsDayResults:
                return NSLocalizedString("Energy Savings Day Results", comment: "")
            case .outage:
                return Configuration.shared.opco.isPHI ? NSLocalizedString("Outage Alerts", comment: "") : NSLocalizedString("Outage", comment: "")
            case .scheduledMaintenanceOutage:
                return NSLocalizedString("Scheduled Maintenance Outage", comment: "")
            case .severeWeather:
                return Configuration.shared.opco.isPHI ? NSLocalizedString("Severe Weather Alert", comment: "") : NSLocalizedString("Severe Weather", comment: "")
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
                if Configuration.shared.opco == .bge {
                    return NSLocalizedString("Service Appointments", comment: "")
                } else if Configuration.shared.opco.isPHI {
                    return NSLocalizedString("Customer Appointment", comment: "")
                } else {
                    return NSLocalizedString("Appointment Tracking", comment: "")
                }
            case .advancedNotification:
                return NSLocalizedString("Advanced Notification", comment: "")
            case .forYourInformation:
                return Configuration.shared.opco.isPHI ? NSLocalizedString("Updates & General News", comment: "") : NSLocalizedString("For Your Information", comment: "")
            case .energyBuddyUpdates:
                return NSLocalizedString("LUMI℠ Updates", comment: "")
            case .grantStatus:
                return NSLocalizedString("Payment Assistance Grant Status", comment: "")
            }
        }
        
        var detailText: String {
            switch (self, Configuration.shared.opco) {
                
                // High Usage
            case (.highUsage, .bge): fallthrough
            case (.highUsage, .peco): fallthrough
            case (.highUsage, .comEd):
                return NSLocalizedString("Receive an alert if you are headed towards a bill that is higher than usual. This alert gives you time to reduce your usage before your next bill and helps to prevent billing surprises.", comment: "")
            
            case (.highUsage, .delmarva): fallthrough
            case (.highUsage, .pepco):
                return NSLocalizedString("Receive an alert when we notice your usage is trending higher than normal. You remain responsible for your actual energy use whether or not you receive an alert.", comment: "")
                
            // Peak Time Savings
            case (.peakTimeSavings, .bge): fallthrough
            case (.peakTimeSavings, .peco):
                return ""
            case (.peakTimeSavings, .comEd):
                return NSLocalizedString("Receive an alert on the day Peak Time Savings Hours occur — as early as 9 a.m. or at least 30 minutes prior to the start of the event.", comment: "")
            
            case (.peakSavingsDayAlert, .delmarva): fallthrough
            case (.peakSavingsDayAlert, .pepco):
                return NSLocalizedString("Receive an alert with the date and time of an upcoming Peak Savings Day. Earn $1.25 off your bill for every kilowatt-hour you save below your average energy use on a Peak Savings Day.", comment: "")
                
            case (.peakSavingsDayResults, .delmarva): fallthrough
            case (.peakSavingsDayResults, .pepco):
                return NSLocalizedString("Receive an alert following a Peak Savings Day to let you know how much you saved. Your credit will automatically appear on your next bill.", comment: "")
                
            // Smart Energy Rewards
            case (.smartEnergyRewards, .bge):
                return NSLocalizedString("Receive alerts before the start of upcoming Energy Savings Days. Earn $1.25 for every kilowatt - hour you reduce on an Energy Savings Day compared to your typical usage on days with similar weather.", comment: "")
            case (.smartEnergyRewards, .peco): fallthrough
            case (.smartEnergyRewards, .comEd):
                return ""
                
            // Smart Energy Rewards
            case (.energySavingsDayResults, .bge):
                return NSLocalizedString("Receive alerts to learn how much you saved during an Energy Savings Day event. Your credits will automatically appear on your next bill. You can also view your savings online on BGE.com or the BGE mobile app under Smart Energy Rewards.", comment: "")
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
            case (.outage, .ace): fallthrough
            case (.outage, .delmarva): fallthrough
            case (.outage, .pepco):
                return NSLocalizedString("Get updates on outages affecting your account. Alerts are sent when your account is part of a known outage, when power is restored in your area and if your estimated time of restoration changes.", comment: "")

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
            case (.severeWeather, .ace): fallthrough
            case (.severeWeather, .delmarva): fallthrough
            case (.severeWeather, .pepco):
                return NSLocalizedString("Get updates about weather conditions that could potentially impact service in your area.", comment: "")
                
            // Bill is Ready
            case (.billIsReady, .bge):
                return NSLocalizedString("Receive an alert when your bill is ready to be viewed online. This alert will contain the bill due date and total amount due.", comment: "")
            case (.billIsReady, .comEd): fallthrough
            case (.billIsReady, .peco):
                return NSLocalizedString("Receive an alert when your monthly bill is ready to be viewed online. By choosing to receive this notification, you will no longer receive a paper bill through the mail.", comment: "")
            case (.billIsReady(_), .ace): fallthrough
            case (.billIsReady(_), .delmarva): fallthrough
            case (.billIsReady(_), .pepco):
                return NSLocalizedString("Receive an alert when your bill is ready to be viewed online. If you are signed up for AutoPay or Direct Debit, this alert will notify you when a payment will be deducted from your bank account.\n\nPlease note that this notification is required for customers enrolled in Paperless eBill or AutoPay.", comment: "")
               
            // Payment Due Reminder
            case (.paymentDueReminder, .bge):
                return NSLocalizedString("Choose to receive an alert 1 to 14 days before your payment due date. Customers are responsible for payment for the total amount due on their account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
            case (.paymentDueReminder, .comEd): fallthrough
            case (.paymentDueReminder, .peco):
                return NSLocalizedString("Receive an alert 1 to 7 days before your payment due date. If enrolled in AutoPay, the alert will notify you of when a payment will be deducted from your bank account.\n\nNOTE: You are responsible for payment of the total amount due on your account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
            case (.paymentDueReminder, .ace): fallthrough
            case (.paymentDueReminder, .delmarva): fallthrough
            case (.paymentDueReminder, .pepco):
                return NSLocalizedString("Receive an alert 1 to 7 days before your payment due date.\n\nNote: Failure to receive this reminder for any reason, including due to technical issues, does not extend or release the payment due date.", comment: "")
                
            // Payment Posted
            case (.paymentPosted, .bge): fallthrough
            case (.paymentPosted, .comEd): fallthrough
            case (.paymentPosted, .peco):
                return NSLocalizedString("Receive a confirmation when your payment has posted to your account. We will include the date and the amount of the posting, as well as your updated total account balance.", comment: "")
            case (.paymentPosted, .ace): fallthrough
            case (.paymentPosted, .delmarva): fallthrough
            case (.paymentPosted, .pepco):
                 return NSLocalizedString("Receive a notification when your payment has posted to your account.", comment: "")
                
            // Payment Past Due
            case (.paymentPastDue, .bge): fallthrough
            case (.paymentPastDue, .comEd): fallthrough
            case (.paymentPastDue, .peco):
                return NSLocalizedString("Receive a friendly reminder 1 day after your due date when you are late in making a payment.", comment: "")
            case (.paymentPastDue, .ace): fallthrough
            case (.paymentPastDue, .delmarva): fallthrough
            case (.paymentPastDue, .pepco):
                return NSLocalizedString("Receive a reminder 1 day after your due date when you are late in making a payment.", comment: "")
                
            // Budget Billing Review
            case (.budgetBillingReview, .bge):
                return ""
            case (.budgetBillingReview, .comEd):
                return NSLocalizedString("Your monthly Budget Bill Payment may be adjusted every six months to keep your account current with your actual electricity usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
            case (.budgetBillingReview, .peco):
                return NSLocalizedString("Your monthly Budget Bill payment may be adjusted every four months to keep your account current with your actual energy usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
           case (.budgetBillingReview, .ace): fallthrough
           case (.budgetBillingReview, .delmarva): fallthrough
           case (.budgetBillingReview, .pepco):
                return NSLocalizedString("Receive an alert when the monthly payment amount for your budget installment has been recalculated, typically twice per year.", comment: "")
               
                
            // Appointment Tracking
            case (.appointmentTracking, _):
                if Configuration.shared.opco == .bge {
                return NSLocalizedString("Receive push notifications such as confirmations, reminders, and relevant status updates to track your scheduled service appointments.", comment: "")
                } else {
                return NSLocalizedString("Receive notifications such as confirmations, reminders, and relevant status updates for your scheduled service appointment.", comment: "")
                }
            case (.advancedNotification, _):
                return "Receive enroute notification updates for your routine service appointments."
                
            // For Your Information
            case (.forYourInformation, .bge):
                return NSLocalizedString("Occasionally, BGE may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            case (.forYourInformation, .comEd):
                return NSLocalizedString("Occasionally, ComEd may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            case (.forYourInformation, .peco):
                return NSLocalizedString("Occasionally, PECO may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
            case (.forYourInformation, .ace): fallthrough
            case (.forYourInformation, .delmarva): fallthrough
            case (.forYourInformation, .pepco):
                return NSLocalizedString("Get updates, general news and special offers. We will not send you more than 3 of these messages each month.", comment: "")
            
                
            // Energy Buddy
            case (.energyBuddyUpdates, .bge):
                return NSLocalizedString("Receive a notification when LUMI℠ has new data, tips, and insights to help you save energy and money.", comment: "")
            case (.grantStatus, .bge):
                return NSLocalizedString("Receive a notification when your payment assistance grant has been approved and a second notification when the grant funds have been applied to your BGE account.", comment: "")
            default:
                return ""
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



