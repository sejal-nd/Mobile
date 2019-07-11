//
//  OverrideViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 11/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class OverrideViewModel {
    
    let peakRewardsService: PeakRewardsService
    let accountDetail: AccountDetail
    let device: SmartThermostatDevice
    let overrideEvents: Observable<Event<[PeakRewardsOverride]>>
    
    let selectedDate = PublishSubject<Date>()
    
    var premiseNumber: String {
        return AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ??
            accountDetail.premiseNumber!
    }
    
    let saveAction = PublishSubject<Void>()
    let cancelAction = PublishSubject<Void>()
    
    let saveTracker = ActivityTracker()
    let refreshingOverrides: Driver<Bool>
    
    init(peakRewardsService: PeakRewardsService,
         accountDetail: AccountDetail,
         device: SmartThermostatDevice,
         overrideEvents: Observable<Event<[PeakRewardsOverride]>>,
         refreshingOverrides: Driver<Bool>) {
        self.peakRewardsService = peakRewardsService
        self.accountDetail = accountDetail
        self.device = device
        self.overrideEvents = overrideEvents
        self.refreshingOverrides = refreshingOverrides
    }
    
    private(set) lazy var dateButtonText: Driver<String> = self.selectedDate.asObservable()
        .map { String(format: NSLocalizedString("Date: %@", comment: ""), $0.mmDdYyyyString) }
        .startWith(NSLocalizedString("Select Date", comment: ""))
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var dateButtonA11yText: Driver<String> = self.selectedDate.asObservable()
        .map { String(format: NSLocalizedString("Date: %@", comment: ""), $0.fullMonthDayAndYearString) }
        .startWith(NSLocalizedString("Select Date", comment: ""))
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var scheduledOverride: Driver<PeakRewardsOverride?> = self.overrideEvents.elements()
        .map { [weak self] in
            guard let device = self?.device else { return nil }
            return $0.filter { $0.status == .scheduled && $0.serialNumber == device.serialNumber }.first
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var scheduledSerialText: String = String(format: NSLocalizedString("Serial #: %@", comment: ""), self.device.serialNumber)
    
    private(set) lazy var scheduledDateText: Driver<String?> = self.scheduledOverride
        .map {
            guard let dateString = $0?.start?.mmDdYyyyString else { return nil }
            return String(format: NSLocalizedString("Date: %@", comment: ""), dateString)
    }
    
    private(set) lazy var activeOverride: Driver<PeakRewardsOverride?> = self.overrideEvents.elements()
        .map { [weak self] in
            guard let device = self?.device else { return nil }
            return $0.filter { $0.status == .active && $0.serialNumber == device.serialNumber }.first
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var activeSerialText: String = String(format: NSLocalizedString("Serial #: %@", comment: ""), self.device.serialNumber)
    
    private(set) lazy var activeDateText: Driver<String?> = self.activeOverride
        .map {
            guard let dateString = $0?.start?.mmDdYyyyString else { return nil }
            return String(format: NSLocalizedString("Date: %@", comment: ""), dateString)
    }
    
    private(set) lazy var showMainLoadingState: Driver<Bool> = self.refreshingOverrides
    
    private(set) lazy var showMainContent: Driver<Bool> = Observable
        .combineLatest(self.overrideEvents.map { $0.error == nil },
                       self.refreshingOverrides.asObservable())
        .map { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showErrorLabel: Driver<Bool> = Observable
        .combineLatest(self.overrideEvents.map { $0.error != nil },
                       self.refreshingOverrides.asObservable())
        { $0 && !$1 }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var enableDateButton: Driver<Bool> = self.scheduledOverride.isNil()
    private(set) lazy var showScheduledOverride: Driver<Bool> = self.scheduledOverride.isNil().not()
    private(set) lazy var showActiveOverride: Driver<Bool> = self.activeOverride.isNil().not()
    private(set) lazy var enableSaveButton: Driver<Bool> = self.selectedDate.mapTo(true).startWith(false).asDriver(onErrorDriveWith: .empty())
    
    //MARK: - Actions
    private lazy var saveEvents: Observable<Event<Void>> = self.saveAction
        .do(onNext: { GoogleAnalytics.log(event: .overrideSave) })
        .withLatestFrom(self.selectedDate.asObservable())
        .flatMapLatest { [weak self] selectedDate -> Observable<Event<Void>> in
            guard let self = self else { return .empty() }
            return self.peakRewardsService.scheduleOverride(accountNumber: self.accountDetail.accountNumber,
                                                     premiseNumber: self.premiseNumber,
                                                     device: self.device,
                                                     date: selectedDate)
                .trackActivity(self.saveTracker)
                .materialize()
        }
        .share()
    
    private lazy var cancelEvents: Observable<Event<Void>> = self.cancelAction
        .do(onNext: { GoogleAnalytics.log(event: .cancelOverride) })
        .flatMapLatest { [weak self] _ -> Observable<Event<Void>> in
            guard let self = self else { return .empty() }
            return self.peakRewardsService.deleteOverride(accountNumber: self.accountDetail.accountNumber,
                                                          premiseNumber: self.premiseNumber,
                                                          device: self.device)
                .trackActivity(self.saveTracker)
                .materialize()
        }
        .share()
    
    private(set) lazy var saveSuccess: Observable<Void> = self.saveEvents.elements()
        .do(onNext: { GoogleAnalytics.log(event: .overrideToast) })
    
    private(set) lazy var cancelSuccess: Observable<Void> = self.cancelEvents.elements()
        .do(onNext: { GoogleAnalytics.log(event: .cancelOverrideToast) })
    
    private(set) lazy var error: Observable<(String?, String?)> = Observable.merge(self.saveEvents.errors(), self.cancelEvents.errors())
        .map {
            guard let error = $0 as? ServiceError else {
                return (NSLocalizedString("Error", comment: ""), $0.localizedDescription)
            }
            
            if error.serviceCode == ServiceErrorCode.fnOverExists.rawValue {
                return ("Override Already Active", nil)
            }
            
            return (NSLocalizedString("Error", comment: ""), error.errorDescription)
    }

}
