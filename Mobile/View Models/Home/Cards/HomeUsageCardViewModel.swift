//
//  HomeUsageCardViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeUsageCardViewModel {
    
    let disposeBag = DisposeBag()
    
    private let maintenanceModeEvents: Observable<Event<Maintenance>>
    let accountDetailEvents: Observable<Event<AccountDetail>>
    private let accountService: AccountService
    private let usageService: UsageService
    
    private let fetchData: Observable<FetchingAccountState>
    
    let refreshFetchTracker: ActivityTracker
    let switchAccountFetchTracker: ActivityTracker
    let loadingTracker = ActivityTracker()
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh: return refreshFetchTracker
        case .switchAccount: return switchAccountFetchTracker
        }
    }
    
    let electricGasSelectedSegmentIndex = Variable<Int>(0)
    
    /*
     * 0 = No Data
     * 1 = Previous
     * 2 = Current
     */
    let barGraphSelectionStates = Variable([Variable(false), Variable(false), Variable(true)])
    
    required init(fetchData: Observable<FetchingAccountState>,
                  maintenanceModeEvents: Observable<Event<Maintenance>>,
                  accountDetailEvents: Observable<Event<AccountDetail>>,
                  accountService: AccountService,
                  usageService: UsageService,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        self.fetchData = fetchData
        self.maintenanceModeEvents = maintenanceModeEvents
        self.accountDetailEvents = accountDetailEvents
        self.accountService = accountService
        self.usageService = usageService
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
    }
    
    private(set) lazy var showLoadingState: Driver<Bool> = switchAccountFetchTracker.asDriver()
        .skip(1)
        .startWith(true)
        .distinctUntilChanged()
    
    private(set) lazy var serResultEvents: Observable<Event<[SERResult]>> = maintenanceModeEvents
        .filter {
            guard let maint = $0.element else { return false }
            return !maint.allStatus && !maint.usageStatus && !maint.homeStatus
        }
        .withLatestFrom(fetchData)
        .toAsyncRequest(activityTracker: { [weak self] fetchingState in
            self?.fetchTracker(forState: fetchingState)
            }, requestSelector: { [weak self] _ in
                self?.accountService
                    .fetchSERResults(accountNumber: AccountsStore.shared.currentAccount.accountNumber) ?? .empty()
        })
    
    private(set) lazy var billComparisonEvents: Observable<Event<BillComparison>> = Observable
        .merge(accountDetailChanged, segmentedControlChanged).share(replay: 1)
    
    private(set) lazy var accountDetailChanged = Observable
        .combineLatest(accountDetailEvents, serResultEvents)
        .filter { $0.element != nil && $1.element != nil }
        .map { accountDetailEvent, _ in accountDetailEvent }
        .do(onNext: { [weak self] _ in self?.usageService.clearCache() })
        .elements()
        .withLatestFrom(maintenanceModeEvents) { ($0, $1.element?.usageStatus ?? false) }
        .filter { $0.isEligibleForUsageData && !$1 }
        .map { accountDetail, _ in accountDetail }
        .withLatestFrom(Observable.combineLatest(fetchData,
                                                 electricGasSelectedSegmentIndex.asObservable()))
        { ($0, $1.0, $1.1) }
        .toAsyncRequest { [unowned self] data -> Observable<BillComparison> in
            let (accountDetail, fetchState, segmentIndex) = data
            guard let premiseNumber = accountDetail.premiseNumber else { return .empty() }

            var gas = false // Default to electric
            if accountDetail.serviceType?.uppercased() == "GAS" { // If account is gas only
                gas = true
            } else if accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC" { // Use value of segmented control
                gas = segmentIndex == 1
            }
            
            return self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, yearAgo: false, gas: gas)
                .trackActivity(self.fetchTracker(forState: fetchState))
        }
    
    private(set) lazy var segmentedControlChanged = self.electricGasSelectedSegmentIndex.asObservable()
        .skip(1)
        .withLatestFrom(accountDetailEvents.elements().filter { $0.isEligibleForUsageData })
        { ($0, $1) }
        .toAsyncRequest { [unowned self] segmentIndex, accountDetail -> Observable<BillComparison> in
            guard let premiseNumber = accountDetail.premiseNumber else { return .empty() }
            
            var gas = false // Default to electric
            if accountDetail.serviceType?.uppercased() == "GAS" { // If account is gas only
                gas = true
            } else if accountDetail.serviceType?.uppercased() == "GAS/ELECTRIC" { // Use value of segmented control
                gas = segmentIndex == 1
            }
            
            return self.usageService.fetchBillComparison(accountNumber: accountDetail.accountNumber, premiseNumber: premiseNumber, yearAgo: false, gas: gas)
                .trackActivity(self.loadingTracker)
        }
    
    private(set) lazy var accountDetailDriver: Driver<AccountDetail> = self.accountDetailEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var billComparisonDriver: Driver<BillComparison> = self.billComparisonEvents.elements().asDriver(onErrorDriveWith: .empty())
    
    
    // MARK: Bill Comparison
    
    private(set) lazy var showBillComparison: Driver<Void> = billComparisonEvents.elements()
        .filter { $0.reference != nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showErrorState: Driver<Void> = Observable
        .combineLatest(accountDetailEvents, serResultEvents)
        .filter { $0.error != nil || $1.error != nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    let errorLabelText: String = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    
    private(set) lazy var showUnavailableState: Driver<Void> = Observable
        .combineLatest(accountDetailEvents, serResultEvents)
        .withLatestFrom(maintenanceModeEvents) { ($0.0, $0.1, $1.element?.usageStatus ?? false) }
        .filter { accountDetailEvent, eventResultsEvent, isMaintenanceMode in
            guard let accountDetail = accountDetailEvent.element,
                let eventResults = eventResultsEvent.element else {
                    return false
            }
            
            if isMaintenanceMode {
                return false
            }
            
            if accountDetail.isBGEControlGroup {
                return !accountDetail.isSERAccount || eventResults.isEmpty // BGE Control Group + SER enrollment get the SER graph on usage card
            }
            
            return !accountDetail.isEligibleForUsageData
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showMaintenanceModeState: Driver<Void> = maintenanceModeEvents.elements()
        .filter { $0.usageStatus }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showBillComparisonEmptyState: Driver<Void> = billComparisonEvents
        .filter { $0.element?.reference == nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showSmartEnergyRewards: Driver<Void> = Observable
        .combineLatest(accountDetailEvents.elements(), serResultEvents.elements())
        .withLatestFrom(maintenanceModeEvents) { ($0.0, $0.1, $1.element?.usageStatus ?? false) }
        .filter { accountDetail, eventResults, isMaintenanceMode in
            !isMaintenanceMode &&
                accountDetail.isBGEControlGroup &&
                accountDetail.isSERAccount &&
                !eventResults.isEmpty
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showSmartEnergyEmptyState: Driver<Void> = Observable
        .combineLatest(accountDetailEvents.elements(), serResultEvents.elements())
        .withLatestFrom(maintenanceModeEvents) { ($0.0, $0.1, $1.element?.usageStatus ?? false) }
        .filter { accountDetail, eventResults, isMaintenanceMode in
            if isMaintenanceMode {
                return false
            }
            
            if accountDetail.isBGEControlGroup && accountDetail.isSERAccount {
                return eventResults.isEmpty
            }
            
            return false
        }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showElectricGasSegmentedControl: Driver<Bool> = accountDetailEvents.map {
        $0.element?.serviceType?.uppercased() == "GAS/ELECTRIC"
    }
    .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var noPreviousData: Driver<Bool> = billComparisonDriver.map {
        return $0.compared == nil
    }
    
    // MARK: No Data Bar Drivers
    
    private(set) lazy var noDataBarDateLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        let lastMonthDate = Calendar.opCo.date(byAdding: .month, value: -1, to: reference.endDate)!
        return lastMonthDate.shortMonthAndDayString.uppercased()
    }
    
    // MARK: Previous Bar Drivers
    
    private(set) lazy var previousBarHeightConstraintValue: Driver<CGFloat> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return 134 }
        guard let compared = $0.compared else { return 0 }
        if compared.charges < 0 {
            return 3
        } else if compared.charges >= reference.charges {
                return 134
        } else {
            let fraction = CGFloat(134.0 * (compared.charges / reference.charges))
            return fraction > 3 ? fraction : 3
        }
    }
    
    private(set) lazy var previousBarDollarLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let compared = $0.compared else { return nil }
        return compared.charges.currencyString
    }
    
    private(set) lazy var previousBarDateLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let compared = $0.compared else { return nil }
        return compared.endDate.shortMonthAndDayString.uppercased()
    }
    
    // MARK: Current Bar Drivers
    
    private(set) lazy var currentBarHeightConstraintValue: Driver<CGFloat> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return 0 }
        guard let compared = $0.compared else { return 134 }
        if reference.charges < 0 {
            return 3
        } else if reference.charges >= compared.charges {
                return 134
        } else {
            let fraction = CGFloat(134.0 * (reference.charges / compared.charges))
            return fraction > 3 ? fraction : 3
        }
    }
    
    private(set) lazy var currentBarDollarLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        return reference.charges.currencyString
    }
    
    private(set) lazy var currentBarDateLabelText: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        return reference.endDate.shortMonthAndDayString.uppercased()
    }
    
    // MARK: Bar Graph Button Accessibility Drivers
    
    private(set) lazy var previousBarA11yLabel: Driver<String?> = self.billComparisonDriver.map {
        guard let compared = $0.compared else { return nil }
        
        let dateString = "\(compared.startDate.fullMonthAndDayString) to \(compared.endDate.fullMonthAndDayString)"
        
        let localizedString = NSLocalizedString("Total bill: %@. Usage: %d %@", comment: "")
        let detailString = String(format: localizedString, compared.charges.currencyString, Int(compared.usage), $0.meterUnit)
        
        return "\(dateString). \(detailString)"
    }
    
    private(set) lazy var currentBarA11yLabel: Driver<String?> = self.billComparisonDriver.map {
        guard let reference = $0.reference else { return nil }
        
        let dateString = "\(reference.startDate.fullMonthAndDayString) to \(reference.endDate.fullMonthAndDayString)"
        
        let localizedString = NSLocalizedString("Total bill: %@. Usage: %d %@", comment: "")
        let detailString = String(format: localizedString, reference.charges.currencyString, Int(reference.usage), $0.meterUnit)
        
        return "\(dateString). \(detailString)"
    }
    
    // MARK: Bar Description Box Drivers
    
    private(set) lazy var barDescriptionDateLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let self = self else { return nil }
            if selectionStates[0].value { // No data
                return NSLocalizedString("Previous Bill - Not enough data available.", comment: "")
            } else if selectionStates[1].value { // Previous
                if let compared = billComparison.compared {
                    return "\(compared.startDate.fullMonthAndDayString) - \(compared.endDate.fullMonthAndDayString)"
                }
            } else if selectionStates[2].value { // Current
                if let reference = billComparison.reference {
                    return "\(reference.startDate.fullMonthAndDayString) - \(reference.endDate.fullMonthAndDayString)"
                }
            }
            return nil
        }
    
    private(set) lazy var barDescriptionTotalBillTitleLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let self = self else { return nil }
            if selectionStates[0].value {
                return nil
            } else {
                return NSLocalizedString("Total Bill", comment: "")
            }
        }
    
    private(set) lazy var barDescriptionTotalBillValueLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let self = self else { return nil }
            if selectionStates[1].value { // Previous
                if let compared = billComparison.compared {
                    return compared.charges.currencyString
                }
            } else if selectionStates[2].value { // Current
                if let reference = billComparison.reference {
                    return reference.charges.currencyString
                }
            }
            return nil
        }
    
    private(set) lazy var barDescriptionUsageTitleLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let self = self else { return nil }
            if selectionStates[0].value {
                return nil
            } else {
                return NSLocalizedString("Usage", comment: "")
            }
        }
    
    private(set) lazy var barDescriptionUsageValueLabelText: Driver<String?> =
        Driver.combineLatest(self.billComparisonDriver, self.barGraphSelectionStates.asDriver()) { [weak self] billComparison, selectionStates in
            guard let self = self else { return nil }
            if selectionStates[1].value { // Previous
                if let compared = billComparison.compared {
                    return "\(Int(compared.usage)) \(billComparison.meterUnit)"
                }
            } else if selectionStates[2].value { // Current
                if let reference = billComparison.reference {
                    return "\(Int(reference.usage)) \(billComparison.meterUnit)"
                }
            }
            return nil
        }
    
    // MARK: Selection States
    
    func setBarSelected(tag: Int) {
        for i in stride(from: 0, to: barGraphSelectionStates.value.count, by: 1) {
            let boolVar = barGraphSelectionStates.value[i]
            boolVar.value = i == tag
        }
        barGraphSelectionStates.value = barGraphSelectionStates.value // Trigger Variable onNext
    }
    
    // MARK: Smart Energy Rewards
    
    private(set) lazy var smartEnergyRewardsSeasonLabelText: Driver<String?> = self.serResultEvents.elements()
        .map { eventResults in
            if let mostRecentEvent = eventResults.last {
                let latestEventYear = Calendar.opCo.component(.year, from: mostRecentEvent.eventStart)
                return String(format: NSLocalizedString("Summer %d", comment: ""), latestEventYear)
            }
            return nil
        }
        .asDriver(onErrorDriveWith: .empty())

    // MARK: Bill Comparison Empty State
    
    private(set) lazy var billComparisonEmptyStateText: Driver<String> = Driver
        .combineLatest(electricGasSelectedSegmentIndex.asDriver(),
                       showElectricGasSegmentedControl)
        .map { segmentIndex, showSegmentedControl in
            if showSegmentedControl {
                let gasElectricString = NSLocalizedString(segmentIndex == 0 ? "electric" : "gas", comment: "")
                return String.localizedStringWithFormat("Your %@ usage overview will be available here once we have two full months of data.", gasElectricString)
            } else {
                return NSLocalizedString("Your usage overview will be available here once we have two full months of data.", comment: "")
            }
        }
}
