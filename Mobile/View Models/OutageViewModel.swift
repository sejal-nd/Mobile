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
    
    var currentAccount: Account?
    var currentOutageStatus: OutageStatus?

    required init(accountService: AccountService, outageService: OutageService) {
        self.accountService = accountService
        self.outageService = outageService
    }
    
    func getAccounts(onSuccess: @escaping ([Account]) -> Void, onError: @escaping (String) -> Void) {
        accountService.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { accounts in
                self.currentAccount = accounts[0]
                onSuccess(accounts)
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func getOutageStatus(forAccount account: Account, onSuccess: @escaping (OutageStatus) -> Void, onError: @escaping (String) -> Void) {

        outageService.fetchOutageStatus(account: account)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { outageStatus in
                self.currentOutageStatus = outageStatus
                onSuccess(outageStatus)
            }, onError: { error in
                self.currentOutageStatus = nil
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func getReportedOutage() -> ReportedOutageResult? {
        return outageService.outageMap[currentAccount!.accountNumber]
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
        return "Assessing Damage"
    }
    
    func getOutageReportedDateString() -> String {
        if let reportedOutage = getReportedOutage() {
            let timeString = Environment.sharedInstance.opcoDateFormatter.string(from: reportedOutage.reportedTime)
            return "Reported \(timeString)"
        }
        return "Reported"
    }
    
    func getFooterTextViewText() -> String {
        var string = ""
        switch Environment.sharedInstance.opco {
            case "BGE":
                string = "To report a gas emergency, please call 1-800-685-0123\nFor downed or sparking power lines or dim / flickering lights, please call 1-877-778-2222"
                break
            case "ComEd":
                string = "To report a gas emergency or a downed or sparking power line, please call 1-800-EDISON-1"
                break
            case "PECO":
                string = "To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141"
                break
            default:
                break
        }
        return string
    }
    
    func getGasOnlyMessage() -> String {
        var string = ""
        if Environment.sharedInstance.opco == "BGE" {
            string = "To report a gas emergency, please call 1-800-685-0123.  For downed or sparking power lines or dim / flickering lights, please call 1-877-778-2222."
        } else {
            string = "We currently do not allow reporting of gas issues online but want to hear from you right away."
        }
        return string
    }
    
    func getAccountNonPayFinaledMessage() -> String {
        var string = ""
        if Environment.sharedInstance.opco == "BGE" {
            string = "Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information."
        } else {
            if currentOutageStatus!.flagFinaled {
                string = "Outage Status and Outage Reporting are not available for this account."
            } else if currentOutageStatus!.flagNoPay {
                string = "Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment."
            }
        }
        return string
    }
}
