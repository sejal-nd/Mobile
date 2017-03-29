//
//  OutageViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

class OutageViewModel {
    
    private var accountService: AccountService
    private var outageService: OutageService
    
    var currentAccount: Account?
    var currentOutageStatus: OutageStatus?

    required init(accountService: AccountService, outageService: OutageService) {
        self.accountService = accountService
        self.outageService = outageService
    }
    
    func getAccounts(onSuccess: @escaping ([Account]) -> Void, onError: @escaping (String) -> Void) {
        accountService.fetchAccounts(page: 0, offset: 0) { (result: ServiceResult<AccountPage>) in
            switch(result) {
                case .Success(let accountPage):
                    self.currentAccount = accountPage.accounts[0]
                    onSuccess(accountPage.accounts)
                    break
                case .Failure(let error):
                    onError(error.localizedDescription)
                    break
            }
        }
    }
    
    func getOutageStatus(forAccount account: Account, onSuccess: @escaping (OutageStatus) -> Void, onError: @escaping (String) -> Void) {
        outageService.fetchOutageStatus(account: account) { (result: ServiceResult<OutageStatus>) in
            switch(result) {
                case .Success(let outageStatus):
                    self.currentOutageStatus = outageStatus
                    onSuccess(outageStatus)
                    break
                case .Failure(let error):
                    onError(error.localizedDescription)
                    break
            }
        }
    }
    
    func getEstimatedRestorationDateString() -> String {
        if let restorationTime = currentOutageStatus!.restorationTime {
            return Environment.sharedInstance.opcoDateFormatter.string(from: restorationTime)
        }
        return NSLocalizedString("Assessing Damage", comment: "")
    }
    
    func getOutageReportedDateString() -> String {
        if let reportedTime = currentOutageStatus!.outageInfo?.reportedTime {
            let timeString = Environment.sharedInstance.opcoDateFormatter.string(from: reportedTime)
            return NSLocalizedString("Reported \(timeString)", comment: "")
        }
        return NSLocalizedString("Reported", comment: "")
    }
    
    func getFooterTextViewText() -> String {
        var string = ""
        switch Environment.sharedInstance.opco {
            case "BGE":
                string = NSLocalizedString("To report a gas emergency, please call 1-800-685-0123\nFor downed or sparking power lines or dim / flickering lights, please call 1-877-778-2222", comment: "")
                break
            case "ComEd":
                string = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-EDISON-1", comment: "")
                break
            case "PECO":
                string = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
                break
            default:
                break
        }
        return string
    }
    
    func getGasOnlyMessage() -> String {
        var string = ""
        if Environment.sharedInstance.opco == "BGE" {
            string = NSLocalizedString("To report a gas emergency, please call 1-800-685-0123.  For downed or sparking power lines or dim / flickering lights, please call 1-877-778-2222.", comment: "")
        } else {
            string = NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.", comment: "")
        }
        return string
    }
    
    func getAccountNonPayFinaledMessage() -> String {
        var string = ""
        if Environment.sharedInstance.opco == "BGE" {
            string = NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
        } else {
            if currentOutageStatus!.accountFinaled {
                string = NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if !currentOutageStatus!.accountPaid {
                string = NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
        }
        return string
    }
}
