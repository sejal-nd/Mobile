//
//  StormModeHomeViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 8/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class StormModeHomeViewModel {
    
    let stormModePollInterval = 30
    
    private let authService: AuthenticationService
    private let alertsService: AlertsService
        
    private let disposeBag = DisposeBag()
    
    var currentOutageStatus: OutageStatus?
    let stormModeUpdate = BehaviorRelay<OpcoUpdate?>(value: nil)
    
    var stormModeEnded = false
    
    // Remote Config Value
    var outageMapURLString = RemoteConfigUtility.shared.string(forKey: .outageMapURL)
    
    
    init(authService: AuthenticationService, alertsService: AlertsService) {
        self.authService = authService
        self.alertsService = alertsService
    }
    
    func startStormModePolling() -> Driver<Void> {
        return Observable<Int>
            .interval(.seconds(stormModePollInterval), scheduler: MainScheduler.instance)
            .mapTo(())
            // Start polling immediately
            .startWith(())
            .toAsyncRequest { [weak self] in
                self?.getMaintenanceMode() ?? .empty()
            }
            // Ignore errors and positive storm mode responses
            .elements()
            .filter { !$0.storm }
            // Stop polling after storm mode ends
            .take(1)
            .mapTo(())
            .asDriver(onErrorDriveWith: .empty())
            .do(onNext: { [weak self] in self?.stormModeEnded = true })
    }
    
    func getMaintenanceMode() -> Observable<MaintenanceMode> {
        return Observable.create { observer -> Disposable in
            AnonymousService.maintenanceMode { result in
                switch result {
                case .success(let maintenanceMode):
                    observer.onNext(maintenanceMode)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchData(onSuccess: @escaping () -> Void,
                   onError: @escaping (NetworkingError) -> Void) {
        
        getOutageStatus(onSuccess: onSuccess, onError: onError)
    }
    
    func getOutageStatus(onSuccess: @escaping () -> Void, onError: @escaping (NetworkingError) -> Void) {
        OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumber: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { [weak self] result in
            switch result {
            case .success(let outageStatus):
                self?.currentOutageStatus = outageStatus
                onSuccess()
            case .failure(let error):
                self?.currentOutageStatus = nil
                onError(error)
            }
        }
    }
    
    func getStormModeUpdate() {
        alertsService.fetchOpcoUpdates(stormOnly: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] opcoUpdates in
                if opcoUpdates.count > 0 {
                    self?.stormModeUpdate.accept(opcoUpdates[0])
                }
            }).disposed(by: disposeBag)
    }
    
    var reportedOutage: ReportedOutageResult? {
        guard AccountsStore.shared.currentIndex != nil else { return nil }
        return OutageService.getReportedOutageResult(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
    }
    
    var estimatedRestorationDateString: String {
        if let reportedOutage = reportedOutage {
            if let reportedETR = reportedOutage.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: reportedETR)
            }
        } else {
            if let statusETR = currentOutageStatus?.estimatedRestorationDate {
                return DateFormatter.outageOpcoDateFormatter.string(from: statusETR)
            }
        }
        return NSLocalizedString("Assessing Damage", comment: "")
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage, let reportedTime = reportedOutage.reportedTime {
            let timeString = DateFormatter.outageOpcoDateFormatter.string(from: reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        
        return NSLocalizedString("Reported", comment: "")
    }
        
    var gasOnlyMessage: String {
        let firstLine = NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.", comment: "")
        let secondLine: String?
        switch Environment.shared.opco {
        case .bge:
            secondLine = NSLocalizedString("If you smell natural gas, leave the area immediately and call", comment: "")
        case .peco:
            secondLine = NSLocalizedString("To issue a Gas Emergency Order, please call", comment: "")
        case .comEd:
            secondLine = nil
        case .pepco:
            secondLine = NSLocalizedString("todo", comment: "")
        case .ace:
            secondLine = NSLocalizedString("todo", comment: "")
        case .delmarva:
            secondLine = NSLocalizedString("todo", comment: "")
        }
        
        if let secondLine = secondLine {
            return firstLine + "\n\n" + secondLine
        } else {
            return firstLine
        }
    }
    
    var accountNonPayFinaledMessage: String {
        if Environment.shared.opco == .bge {
            return NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
        } else {
            if currentOutageStatus!.isFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if currentOutageStatus!.isNoPay {
                return NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
        }
        return ""
    }
    
    var reportOutageEnabled: Bool {
        return !(currentOutageStatus?.isFinaled ?? false ||
            currentOutageStatus?.isNoPay ?? false ||
            currentOutageStatus?.isNonService ?? false)
    }
}
