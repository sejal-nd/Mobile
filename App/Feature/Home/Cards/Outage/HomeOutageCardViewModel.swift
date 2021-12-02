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
    
    private let maintenanceModeEvents: Observable<Event<MaintenanceMode>>
    private let fetchDataObservable: Observable<Void>
    private let fetchTracker: ActivityTracker
    
    // MARK: - Init
    
    required init(maintenanceModeEvents: Observable<Event<MaintenanceMode>>,
                  fetchDataObservable: Observable<Void>,
                  fetchTracker: ActivityTracker) {
        self.maintenanceModeEvents = maintenanceModeEvents
        self.fetchDataObservable = fetchDataObservable
        self.fetchTracker = fetchTracker
    }
    
    // MARK: - Retrieve Outage Status
    
    private lazy var outageStatusEvents: Observable<Event<OutageStatus>> = self.maintenanceModeEvents
        .filter {
            guard let maint = $0.element else { return true }
            return !maint.all && !maint.outage && !maint.home
        }
        .withLatestFrom(self.fetchDataObservable)
        .toAsyncRequest(activityTracker: { [weak self] in self?.fetchTracker },
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
            return outageStatus.isFinaled || outageStatus.isNoPay || outageStatus.isNonService
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var isGasOnly: Driver<Bool> = self.outageStatusEvents
        .map { $0.element?.isGasOnly ?? false }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var isCustomError: Driver<Bool> = self.outageStatusEvents
        .map { event in
            guard let outageStatus = event.element else { return false }
            return outageStatus.isFinaled || outageStatus.isNoPay ||
                outageStatus.isNonService || outageStatus.isGasOnly
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var storedEtr: Driver<Date?> = self.outageReported
        .startWith(())
        .map { [weak self] in
            guard AccountsStore.shared.currentIndex != nil else { return nil }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            return OutageService.getReportedOutageResult(accountNumber: accountNumber)?.etr
    }
    
    private lazy var fetchedEtr: Driver<Date?> = self.currentOutageStatus.map { $0.estimatedRestorationDate }
    
    
    // MARK: - Show/Hide Views
    
    private(set) lazy var showLoadingState: Driver<Void> = fetchTracker
        .asDriver().filter { $0 }.mapTo(())
    
    private(set) lazy var showMaintenanceModeState: Driver<Void> = maintenanceModeEvents.elements()
        .filter { $0.outage }
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
        .filter { !$0.isOutstandingBalance && $0.isGasOnly }
        .mapTo(())
    
    private(set) lazy var showErrorState: Driver<Void> =  outageStatusEvents.errors()
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var getError: Driver<Error> =  outageStatusEvents.errors()
        .map{ $0 }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showReportedOutageTime: Driver<Bool> = Driver
        .merge(self.outageReported, self.currentOutageStatus.mapTo(()))
        .map { [weak self] in
            guard let this = self else { return false }
            guard AccountsStore.shared.currentIndex != nil else { return false }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            return OutageService.getReportedOutageResult(accountNumber: accountNumber) != nil
        }
        .distinctUntilChanged()
    
    
    // MARK: - View Content

    private(set) lazy var powerStatusImage: Driver<UIImage> = self.currentOutageStatus
        .map { $0.isActiveOutage ? #imageLiteral(resourceName: "ic_lightbulb_off") : #imageLiteral(resourceName: "ic_outagestatus_on") }
    
    private(set) lazy var powerStatus: Driver<String> = self.currentOutageStatus
        .map { $0.isActiveOutage ? "POWER IS OUT" : "POWER IS ON" }
    
    private(set) lazy var etrText: Driver<String> = Driver.merge(self.storedEtr, self.fetchedEtr)
        .map {
            guard let etrText = $0 else { return Configuration.shared.opco.isPHI ? NSLocalizedString("Pending Assessment", comment: "") : NSLocalizedString("Assessing Damage", comment: "") }
            return String.localizedStringWithFormat(DateFormatter.outageOpcoDateFormatter.string(from: etrText))
        }
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var reportedOutageTime: Driver<String?> = Driver.merge(self.outageReported.startWith(()),
                                                                             self.currentOutageStatus.mapTo(()))
        .map { [weak self] in
            guard let this = self else { return nil }
            guard AccountsStore.shared.currentIndex != nil else { return nil }
            let accountNumber = AccountsStore.shared.currentAccount.accountNumber
            guard let reportedTime = OutageService.getReportedOutageResult(accountNumber:    accountNumber)?.reportedTime else {
                return nil
            }
            return String.localizedStringWithFormat("Outage reported %@",
                                                    DateFormatter.outageOpcoDateFormatter.string(from: reportedTime))
        }
        .distinctUntilChanged()
    
    private(set) lazy var callToActionButtonText: Driver<String> = self.showReportedOutageTime
        .map { $0 ? NSLocalizedString("View Outage Map", comment: "") : NSLocalizedString("Report Outage", comment: "")}

    private(set) lazy var showEtr: Driver<Bool> = Driver
        .merge(self.currentOutageStatus.map { $0.isActiveOutage }, self.outageReported.mapTo(true))
        .distinctUntilChanged()
    
    private(set) lazy var accountNonPayFinaledMessage: Driver<NSAttributedString> = currentOutageStatus
        .map { outageStatus -> String in
            if Configuration.shared.opco == .bge {
                return NSLocalizedString("Our records indicate that your services have been disconnected due to non-payment. If you wish to restore services, please make a payment or contact Customer Service at 1-800-685-0123 for further assistance.", comment: "")
            } else if outageStatus.isFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if outageStatus.isNoPay {
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
        return Observable.create { observer -> Disposable in
            OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumberString: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { result in
                        switch result {
                        case .success(let outageStatus):
                            observer.onNext(outageStatus)
                            observer.onCompleted()
                        case .failure(let error):
                            observer.onError(error)
                        }
                    }
            return Disposables.create()
        }
    }
        
}

fileprivate extension OutageStatus {
    var isCustomError: Bool {
        return isFinaled || isNoPay || isNonService || isGasOnly
    }
    
    var isOutstandingBalance: Bool {
        return isFinaled || isNoPay || isNonService
    }
}
