//
//  HomeOutageCardViewModel.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/2/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class HomeOutageCardViewModel {
    
    private let outageService: OutageService
    private let maintenanceModeEvents: Observable<Event<Maintenance>>
    private let fetchDataObservable: Observable<FetchingAccountState>
    private let refreshFetchTracker: ActivityTracker
    private let switchAccountFetchTracker: ActivityTracker
    
    
    // MARK: - Init
    
    required init(outageService: OutageService,
                  maintenanceModeEvents: Observable<Event<Maintenance>>,
                  fetchDataObservable: Observable<FetchingAccountState>,
                  refreshFetchTracker: ActivityTracker,
                  switchAccountFetchTracker: ActivityTracker) {
        self.outageService = outageService
        self.maintenanceModeEvents = maintenanceModeEvents
        self.fetchDataObservable = fetchDataObservable
        self.refreshFetchTracker = refreshFetchTracker
        self.switchAccountFetchTracker = switchAccountFetchTracker
    }
    
    
    // MARK: - Retrieve Outage Status
    
    private lazy var outageStatusEvents: Observable<Event<OutageStatus>> = self.maintenanceModeEvents
        .filter { !($0.element?.outageStatus ?? false) && !($0.element?.homeStatus ?? false) }
        .withLatestFrom(self.fetchDataObservable)
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: $0) },
                        requestSelector: { [unowned self] _ in self.retrieveOutageStatus() })
    
    // MARK: - Variables
    
    private let outageReported = RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var currentOutageStatus: Driver<OutageStatus> = self.outageStatusEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowContentView: Driver<Bool> = Driver.combineLatest(isOutageErrorStatus, shouldShowMaintenanceModeState, isCustomError)
        { !$0 && !$1 && !$2 }
        .distinctUntilChanged()
    
    private lazy var isOutageErrorStatus: Driver<Bool> = self.outageStatusEvents
        .asDriver(onErrorDriveWith: .empty())
        .map { $0.error != nil }
        .startWith(false)

    private(set) lazy var shouldShowErrorState: Driver<Bool> = Driver.combineLatest(isOutageErrorStatus, shouldShowMaintenanceModeState)
        { $0 && !$1 }
        .distinctUntilChanged()
    
    private(set) lazy var shouldShowMaintenanceModeState: Driver<Bool> = self.maintenanceModeEvents
        .map { $0.element?.outageStatus ?? false }
        .startWith(false)
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var powerStatusImage: Driver<UIImage> = self.currentOutageStatus
        .map { $0.activeOutage ? #imageLiteral(resourceName: "ic_lightbulb_off") : #imageLiteral(resourceName: "ic_outagestatus_on") }
    
    private(set) lazy var powerStatus: Driver<String> = self.currentOutageStatus
        .map { $0.activeOutage ? "POWER IS OUT" : "POWER IS ON" }
    
    private lazy var storedEtr: Observable<Date> = self.outageReported
        .asObservable()
        .startWith(())
        .map {
            guard AccountsStore.shared.currentAccount != nil else { return nil }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            return ReportedOutagesStore.shared[accountNumber]?.etr
        }
        .unwrap()
    
    private lazy var fetchedEtr: Observable<Date> = self.currentOutageStatus
        .map {
            
            if let etr = $0.etr {
                return etr
            }
            
            guard AccountsStore.shared.currentAccount != nil else { return nil }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            return ReportedOutagesStore.shared[accountNumber]?.etr
        }
        .asObservable().unwrap()
    
    private(set) lazy var etrText: Driver<String?> = Observable.merge(self.storedEtr,
                                                                              self.fetchedEtr)
        .map {
            String.localizedStringWithFormat("Estimated Restoration\n%@",
                                             DateFormatter.outageOpcoDateFormatter.string(from: $0))
        }
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var reportedOutageTime: Driver<String?> = Driver.merge(self.outageReported.startWith(()),
                                                                             self.currentOutageStatus.map(to: ()))
        .map {
            guard AccountsStore.shared.currentAccount != nil else { return nil }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            guard let reportedTime = ReportedOutagesStore.shared[accountNumber]?.reportedTime else {
                return nil
            }
            return String.localizedStringWithFormat("Outage reported %@",
                                                    DateFormatter.outageOpcoDateFormatter.string(from: reportedTime))
        }
        .distinctUntilChanged()
    
    private(set) lazy var showReportedOutageTime: Driver<Bool> = Driver.merge(self.outageReported, self.currentOutageStatus.map(to: ())).map {
        guard AccountsStore.shared.currentAccount != nil else { return false }
        return ReportedOutagesStore.shared[AccountsStore.shared.currentAccount.accountNumber] != nil
    }
        .distinctUntilChanged()
    
    private(set) lazy var callToActionButtonText: Driver<String> = self.showReportedOutageTime
        .map { $0 ? NSLocalizedString("View Outage Map", comment: "") : NSLocalizedString("Report Outage", comment: "")}

    private(set) lazy var shouldShowRestorationTime: Driver<Bool> = Driver.combineLatest(self.outageReported.startWith(()), self.currentOutageStatus)
    { (_, outageStatus) in
        guard AccountsStore.shared.currentAccount != nil else { return false }
        return ReportedOutagesStore.shared[AccountsStore.shared.currentAccount.accountNumber]?.etr != nil || outageStatus.etr != nil
        }
        .startWith(false)
        .distinctUntilChanged()
    
    private lazy var isCustomError: Driver<Bool> = self.outageStatusEvents
        .map { event in
            guard let outageStatus = event.element else { return false }
            return outageStatus.flagFinaled || outageStatus.flagNoPay ||
                outageStatus.flagNonService || outageStatus.flagGasOnly
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var isOutstandingBalance: Driver<Bool> = self.outageStatusEvents
        .map { event in
            guard let outageStatus = event.element else { return false }
            return outageStatus.flagFinaled || outageStatus.flagNoPay || outageStatus.flagNonService
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var isGasOnly: Driver<Bool> = self.outageStatusEvents
        .map { $0.element?.flagGasOnly ?? false }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showCustomErrorView: Driver<Bool> = Driver.combineLatest(isCustomError, shouldShowMaintenanceModeState)
    { $0 && !$1 }
        .distinctUntilChanged()
    
    private(set) lazy var showOutstandingBalanceWarning: Driver<Bool> = Driver.combineLatest(isOutstandingBalance, shouldShowMaintenanceModeState)
    { $0 && !$1 }
        .distinctUntilChanged()
    
    private(set) lazy var showGasOnly: Driver<Bool> = Driver.combineLatest(isGasOnly, showOutstandingBalanceWarning)
    { $0 && !$1 }
        .distinctUntilChanged()
    
    private(set) lazy var accountNonPayFinaledMessage: Driver<NSAttributedString> = currentOutageStatus
        .map { outageStatus -> String in
            if Environment.shared.opco == .bge {
                return NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
            } else if outageStatus.flagFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if outageStatus.flagNoPay {
                return NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
            return ""
        }
        .map { text -> NSAttributedString in
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            
            style.minimumLineHeight = 20
            attributeString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.count))
            attributeString.addAttribute(.foregroundColor, value: UIColor.deepGray, range: NSMakeRange(0, text.count))
            attributeString.addAttribute(.font, value: OpenSans.regular.of(textStyle: .footnote), range: NSMakeRange(0, text.count))
            
            return attributeString
    }
    
    // MARK: - Service
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh:
            return refreshFetchTracker
        case .switchAccount:
            return switchAccountFetchTracker
        }
    }
    
    private func retrieveOutageStatus() -> Observable<OutageStatus> {
        return outageService.fetchOutageStatus(account: AccountsStore.shared.currentAccount)
            .catchError { error -> Observable<OutageStatus> in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnAccountFinaled.rawValue {
                    return .just(OutageStatus.from(["flagFinaled": true])!)
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountNoPay.rawValue {
                    return .just(OutageStatus.from(["flagNoPay": true])!)
                } else if serviceError.serviceCode == ServiceErrorCode.fnNonService.rawValue {
                    return .just(OutageStatus.from(["flagNonService": true])!)
                } else {
                    return .error(serviceError)
                }
        }
    }
    
}
