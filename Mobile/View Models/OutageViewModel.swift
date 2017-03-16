//
//  OutageViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

class OutageViewModel {
    
    private var accountService: AccountService?
    private var outageService: OutageService?
    
    var currentAccount: Account?
    var currentOutageStatus: OutageStatus?

    required init(accountService: AccountService, outageService: OutageService) {
        self.accountService = accountService
        self.outageService = outageService
    }
    
    func getAccounts(onSuccess: @escaping ([Account]) -> Void, onError: @escaping (String) -> Void) {
        accountService!.fetchAccounts(page: 0, offset: 0) { (result: ServiceResult<AccountPage>) in
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
        outageService!.fetchOutageStatus(account: account) { (result: ServiceResult<OutageStatus>) in
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
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a MM/dd/yy"
            return formatter.string(from: restorationTime)
        } else {
            return "Assessing Damage"
        }
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
    
    func getGasOnlyPhoneNumber() -> String {
        return "1-800-841-4141"
    }
    
    func getAccountNotPaidMessage() -> String {
        return "Outage Status and Outage Reporting are not available for accounts with an outstanding balance."
    }
}
