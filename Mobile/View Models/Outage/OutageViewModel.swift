//
//  OutageViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class OutageViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService
    private var outageService: OutageService
    private var authService: AuthenticationService
    
    private var currentGetMaintenanceModeStatusDisposable: Disposable?
    private var currentGetOutageStatusDisposable: Disposable?
    
    var currentOutageStatus: OutageStatus?
    
    var hasPressedStreetlightOutageMapButton = false

    required init(accountService: AccountService, outageService: OutageService, authService: AuthenticationService) {
        self.accountService = accountService
        self.outageService = outageService
        self.authService = authService
    }
    
    deinit {
        currentGetMaintenanceModeStatusDisposable?.dispose()
        currentGetOutageStatusDisposable?.dispose()
    }
    
    func fetchData(onSuccess: @escaping () -> Void,
                   onError: @escaping (ServiceError) -> Void,
                   onMaintenance: @escaping () -> Void) {
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        currentGetMaintenanceModeStatusDisposable?.dispose()
        currentGetOutageStatusDisposable?.dispose()
        
        currentGetMaintenanceModeStatusDisposable = authService.getMaintenanceMode()
            .subscribe(onNext: { [weak self] status in
                if status.outageStatus {
                    onMaintenance()
                } else {
                    self?.getOutageStatus(onSuccess: onSuccess, onError: onError)
                }
                }, onError: { [weak self] _ in
                    self?.getOutageStatus(onSuccess: onSuccess, onError: onError)
            })
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
                guard let `self` = self else { return }
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
    
    var reportedOutage: ReportedOutageResult? {
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
    
    var footerTextViewText: String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123", comment: "")
        case .comEd:
            return NSLocalizedString("To report a downed or sparking power line, please call 1-800-334-7661", comment: "")
        case .peco:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
        }
    }
    
    var gasOnlyMessage: String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo report a gas emergency or a downed or sparking power line, please call 1-800-685-0123.", comment: "")
        case .peco:
            return NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo issue a Gas Emergency Order, please call 1-800-841-4141.", comment: "")
        default:
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
    
    var shouldShowPayBillButton: Bool {
        return currentOutageStatus!.flagNoPay
    }
    
    var showReportStreetlightOutageButton: Bool {
        switch Environment.shared.opco {
        case .comEd:
            return false // should change to true once the map is ready
        case .bge, .peco:
            return false
        }
    }
}
