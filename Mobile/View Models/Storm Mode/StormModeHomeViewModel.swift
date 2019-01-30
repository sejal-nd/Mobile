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
    
    let stormModePollInterval = 30.0
    
    private let authService: AuthenticationService
    private var outageService: OutageService
    private let alertsService: AlertsService
    
    private var currentGetOutageStatusDisposable: Disposable?
    
    private let disposeBag = DisposeBag()
    
    var currentOutageStatus: OutageStatus?
    let stormModeUpdate = Variable<OpcoUpdate?>(nil)
    
    var stormModeEnded = false
    
    init(authService: AuthenticationService, outageService: OutageService, alertsService: AlertsService) {
        self.authService = authService
        self.outageService = outageService
        self.alertsService = alertsService
    }
    
    deinit {
        currentGetOutageStatusDisposable?.dispose()
    }
    
    func startStormModePolling() -> Driver<Void> {
        return Observable<Int>
            .interval(stormModePollInterval, scheduler: MainScheduler.instance)
            .mapTo(())
            // Start polling immediately
            .startWith(())
            .toAsyncRequest { [weak self] in
                self?.authService.getMaintenanceMode(postNotification: false) ?? .empty()
            }
            // Ignore errors and positive storm mode responses
            .elements()
            .filter { !$0.stormModeStatus }
            // Stop polling after storm mode ends
            .take(1)
            .mapTo(())
            .asDriver(onErrorDriveWith: .empty())
            .do(onNext: { [weak self] in self?.stormModeEnded = true })
    }
    
    func fetchData(onSuccess: @escaping () -> Void,
                   onError: @escaping (ServiceError) -> Void) {
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        currentGetOutageStatusDisposable?.dispose()
        
        getOutageStatus(onSuccess: onSuccess, onError: onError)
        
    }
    
    func getOutageStatus(onSuccess: @escaping () -> Void, onError: @escaping (ServiceError) -> Void) {
        
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        currentGetOutageStatusDisposable?.dispose()
        
        currentGetOutageStatusDisposable = outageService.fetchOutageStatus(account: AccountsStore.shared.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] outageStatus in
                self?.currentOutageStatus = outageStatus
                onSuccess()
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    let serviceError = error as! ServiceError
                    if serviceError.serviceCode == ServiceErrorCode.fnAccountFinaled.rawValue {
                        self.currentOutageStatus = OutageStatus.from(["flagFinaled": true])
                        onSuccess()
                    } else if serviceError.serviceCode == ServiceErrorCode.fnAccountNoPay.rawValue {
                        self.currentOutageStatus = OutageStatus.from(["flagNoPay": true])
                        onSuccess()
                    } else if serviceError.serviceCode == ServiceErrorCode.fnNonService.rawValue {
                        self.currentOutageStatus = OutageStatus.from(["flagNonService": true])
                        onSuccess()
                    } else {
                        self.currentOutageStatus = nil
                        onError(serviceError)
                    }
            })
    }
    
    func getStormModeUpdate() {
        alertsService.fetchOpcoUpdates(stormOnly: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] opcoUpdates in
                if opcoUpdates.count > 0 {
                    self?.stormModeUpdate.value = opcoUpdates[0]
                }
            }).disposed(by: disposeBag)
    }
    
    var reportedOutage: ReportedOutageResult? {
        guard AccountsStore.shared.currentAccount != nil else { return nil }
        return outageService.getReportedOutageResult(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
    }
    
    var estimatedRestorationDateString: String {
        if let reportedOutage = reportedOutage {
            if let reportedETR = reportedOutage.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: reportedETR)
            }
        } else {
            if let statusETR = currentOutageStatus!.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: statusETR)
            }
        }
        return NSLocalizedString("Assessing Damage", comment: "")
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage {
            let timeString = DateFormatter.outageOpcoDateFormatter.string(from: reportedOutage.reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        
        return NSLocalizedString("Reported", comment: "")
    }
    
    var footerLabelText: String {
        switch Environment.shared.opco {
        case .bge, .peco:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call", comment: "")
        case .comEd:
            return NSLocalizedString("To report a downed or sparking power line, please call", comment: "")
        }
    }
    
    var footerPhoneLabelText: String {
        switch Environment.shared.opco {
        case .bge:
            return "1-800-685-0123"
        case .comEd:
            return "1-800-334-7661"
        case .peco:
            return "1-800-841-4141"
        }
    }
    
    var gasOnlyMessage: String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo report a gas emergency or a downed or sparking power line, please call", comment: "")
        case .peco:
            return NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo issue a Gas Emergency Order, please call", comment: "")
        case .comEd:
            return NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.", comment: "")
        }
    }
    
    var accountNonPayFinaledMessage: String {
        if Environment.shared.opco == .bge {
            return NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
        } else {
            if currentOutageStatus!.flagFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if currentOutageStatus!.flagNoPay {
                return NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
        }
        return ""
    }
    
    var reportOutageEnabled: Bool {
        return !(currentOutageStatus?.flagFinaled ?? false ||
            currentOutageStatus?.flagNoPay ?? false ||
            currentOutageStatus?.flagNonService ?? false)
    }
}
