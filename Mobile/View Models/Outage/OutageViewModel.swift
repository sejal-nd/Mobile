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
    
    private var currentGetOutageStatusDisposable: Disposable?
    
    var currentOutageStatus: OutageStatus?

    required init(accountService: AccountService, outageService: OutageService) {
        self.accountService = accountService
        self.outageService = outageService
    }
    
    deinit {
        if let disposable = currentGetOutageStatusDisposable {
            disposable.dispose()
        }
    }
    
    func getOutageStatus(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {

        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        if let disposable = currentGetOutageStatusDisposable {
            disposable.dispose()
        }
        
        currentGetOutageStatusDisposable = outageService.fetchOutageStatus(account: AccountsStore.sharedInstance.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { outageStatus in
                self.currentOutageStatus = outageStatus
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnAccountFinaled.rawValue {
                    self.currentOutageStatus = OutageStatus.from(["flagFinaled": true])
                    onSuccess()
                } else if serviceError.serviceCode == ServiceErrorCode.FnAccountNoPay.rawValue {
                    self.currentOutageStatus = OutageStatus.from(["flagNoPay": true])
                    onSuccess()
                } else if serviceError.serviceCode == ServiceErrorCode.FnNonService.rawValue {
                    self.currentOutageStatus = OutageStatus.from(["flagNonService": true])
                    onSuccess()
                } else {
                    self.currentOutageStatus = nil
                    onError(NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")) // Generic error message from the home bill card
                }
            })
    }
    
    func getReportedOutage() -> ReportedOutageResult? {
        return outageService.outageMap[AccountsStore.sharedInstance.currentAccount.accountNumber]
    }
    
    func getEstimatedRestorationDateString() -> String {
        if let reportedOutage = getReportedOutage() {
            if let reportedETR = reportedOutage.etr {
                return Environment.sharedInstance.opcoDateFormatter.string(from: reportedETR)
            }
        } else {
            if let statusETR = currentOutageStatus!.etr {
                return Environment.sharedInstance.opcoDateFormatter.string(from: statusETR)
            }
        }
        return NSLocalizedString("Assessing Damage", comment: "")
    }
    
    func getOutageReportedDateString() -> String {
        if let reportedOutage = getReportedOutage() {
            let timeString = Environment.sharedInstance.opcoDateFormatter.string(from: reportedOutage.reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        
        return NSLocalizedString("Reported", comment: "")
    }
    
    func getFooterTextViewText() -> String {
        switch Environment.sharedInstance.opco {
            case .bge:
                return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123", comment: "")
            case .comEd:
                return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-EDISON-1", comment: "")
            case .peco:
                return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
        }
    }
    
    func getGasOnlyMessage() -> String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("This account receives gas service only.  We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo report a gas emergency, please call 1-800-685-0123.  For downed or sparking power lines or dim / flickering lights, please call 1-877-778-2222.", comment: "")
        case .peco:
            return NSLocalizedString("This account receives gas service only. We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo issue a Gas Emergency Order, please call 1-800-841-4141.", comment: "")
        default:
            return NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.", comment: "")
        }
    }
    
    func getAccountNonPayFinaledMessage() -> String {
        if Environment.sharedInstance.opco == .bge {
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
}
