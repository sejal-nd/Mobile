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
        .filter {
            guard let maint = $0.element else { return true }
            return !maint.allStatus && !maint.outageStatus && !maint.homeStatus
        }
        .withLatestFrom(self.fetchDataObservable)
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker(forState: $0 )},
                        requestSelector: { [unowned self] _ in self.retrieveOutageStatus() })
    
    // MARK: - Variables
    
    private(set) lazy var currentOutageStatus: Driver<OutageStatus> = self.outageStatusEvents.elements()
        .asDriver(onErrorDriveWith: .empty())
    
    private let outageReported = RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
    
    private lazy var isOutageErrorStatus: Driver<Bool> = self.outageStatusEvents
        .asDriver(onErrorDriveWith: .empty())
        .map { $0.error != nil }
        .startWith(false)
    
    private lazy var isOutstandingBalance: Driver<Bool> = self.outageStatusEvents
        .map { event in
            guard let outageStatus = event.element else { return false }
            return outageStatus.flagFinaled || outageStatus.flagNoPay || outageStatus.flagNonService
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var isGasOnly: Driver<Bool> = self.outageStatusEvents
        .map { $0.element?.flagGasOnly ?? false }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var isCustomError: Driver<Bool> = self.outageStatusEvents
        .map { event in
            guard let outageStatus = event.element else { return false }
            return outageStatus.flagFinaled || outageStatus.flagNoPay ||
                outageStatus.flagNonService || outageStatus.flagGasOnly
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var storedEtr: Driver<Date?> = self.outageReported
        .startWith(())
        .map { [weak self] in
            guard AccountsStore.shared.currentIndex != nil else { return nil }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            return self?.outageService.getReportedOutageResult(accountNumber: accountNumber)?.etr
    }
    
    private lazy var fetchedEtr: Driver<Date?> = self.currentOutageStatus.map { $0.etr }
    
    
    // MARK: - Show/Hide Views
    
    private(set) lazy var showLoadingState: Driver<Void> = switchAccountFetchTracker
        .asDriver().filter { $0 }.mapTo(())
    
    private(set) lazy var showMaintenanceModeState: Driver<Void> = maintenanceModeEvents.elements()
        .filter { $0.outageStatus }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showContentView: Driver<Void> = currentOutageStatus
        .filter { !$0.isCustomError }
        .mapTo(())
    
    private(set) lazy var showCustomErrorView: Driver<Void> = currentOutageStatus
        .filter { $0.isCustomError }
        .mapTo(())
    
    private(set) lazy var showOutstandingBalanceWarning: Driver<Void> = currentOutageStatus
        .filter { $0.isOutstandingBalance }
        .mapTo(())
    
    private(set) lazy var showGasOnly: Driver<Void> = currentOutageStatus
        .filter { !$0.isOutstandingBalance && $0.flagGasOnly }
        .mapTo(())
    
    private(set) lazy var showErrorState: Driver<Void> =  outageStatusEvents.errors()
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showReportedOutageTime: Driver<Bool> = Driver
        .merge(self.outageReported, self.currentOutageStatus.mapTo(()))
        .map { [weak self] in
            guard let this = self else { return false }
            guard AccountsStore.shared.currentIndex != nil else { return false }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            return this.outageService.getReportedOutageResult(accountNumber: accountNumber) != nil
        }
        .distinctUntilChanged()
    
    
    // MARK: - View Content

    private(set) lazy var powerStatusImage: Driver<UIImage> = self.currentOutageStatus
        .map { $0.activeOutage ? #imageLiteral(resourceName: "ic_lightbulb_off") : #imageLiteral(resourceName: "ic_outagestatus_on") }
    
    private(set) lazy var powerStatus: Driver<String> = self.currentOutageStatus
        .map { $0.activeOutage ? "POWER IS OUT" : "POWER IS ON" }
    
    private(set) lazy var etrText: Driver<String> = Driver.merge(self.storedEtr, self.fetchedEtr)
        .map {
            guard let etrText = $0 else { return NSLocalizedString("Estimated Restoration\nAssessing Damage", comment: "") }
            return String.localizedStringWithFormat("Estimated Restoration\n%@",
                                                    DateFormatter.outageOpcoDateFormatter.string(from: etrText))
        }
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var reportedOutageTime: Driver<String?> = Driver.merge(self.outageReported.startWith(()),
                                                                             self.currentOutageStatus.mapTo(()))
        .map { [weak self] in
            guard let this = self else { return nil }
            guard AccountsStore.shared.currentIndex != nil else { return nil }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            guard let reportedTime = this.outageService.getReportedOutageResult(accountNumber: accountNumber)?.reportedTime else {
                return nil
            }
            return String.localizedStringWithFormat("Outage reported %@",
                                                    DateFormatter.outageOpcoDateFormatter.string(from: reportedTime))
        }
        .distinctUntilChanged()
    
    private(set) lazy var callToActionButtonText: Driver<String> = self.showReportedOutageTime
        .map { $0 ? NSLocalizedString("View Outage Map", comment: "") : NSLocalizedString("Report Outage", comment: "")}

    private(set) lazy var showEtr: Driver<Bool> = Driver
        .merge(self.currentOutageStatus.map { $0.activeOutage }, self.outageReported.mapTo(true))
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
    
    private func fetchTracker(forState state: FetchingAccountState) -> ActivityTracker {
        switch state {
        case .refresh:
            return refreshFetchTracker
        case .switchAccount:
            return switchAccountFetchTracker
        }
    }
    
}

fileprivate extension OutageStatus {
    var isCustomError: Bool {
        return flagFinaled || flagNoPay || flagNonService || flagGasOnly
    }
    
    var isOutstandingBalance: Bool {
        return flagFinaled || flagNoPay || flagNonService
    }
}
