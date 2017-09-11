//
//  UnauthenticatedOutageViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 9/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class UnauthenticatedOutageViewModel {
    
    let disposeBag = DisposeBag()
    
    let phoneNumber = Variable("")
    let accountNumber = Variable("")
    
    var outageStatusArray: [OutageStatus]?
    var selectedOutageStatus: OutageStatus?
    var reportedOutage: ReportedOutageResult?
    
    let outageService: OutageService!
    
    required init(outageService: OutageService) {
        self.outageService = outageService
    }
    
    func fetchOutageStatus(onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let phone: String? = phoneNumber.value.isEmpty ? nil : phoneNumber.value
        let accountNum: String? = accountNumber.value.isEmpty ? nil : accountNumber.value
        outageService.fetchOutageStatusAnon(phoneNumber: phone, accountNumber: accountNum)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] outageStatusArray in
                if outageStatusArray.count == 1 {
                    self?.selectedOutageStatus = outageStatusArray[0]
                } else {
                    self?.outageStatusArray = outageStatusArray
                }
                onSuccess()
            }, onError: { error in
                //guard let `self` = self else { return }
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnAccountFinaled.rawValue {
                    //self.selectedOutageStatus = OutageStatus.from(["flagFinaled": true])
                    onError(NSLocalizedString("Finaled Account", comment: ""), NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: ""))
                } else if serviceError.serviceCode == ServiceErrorCode.FnAccountNoPay.rawValue {
                    //self.selectedOutageStatus = OutageStatus.from(["flagNoPay": true])
                    if Environment.sharedInstance.opco == .bge {
                        onError(NSLocalizedString("Outage status unavailable", comment: ""), NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: ""))
                    } else {
                        onError(NSLocalizedString("Cut for non pay", comment: ""), NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: ""))
                    }
                } else if serviceError.serviceCode == ServiceErrorCode.FnNonService.rawValue {
                    //self.selectedOutageStatus = OutageStatus.from(["flagNonService": true])
                    onError(NSLocalizedString("Outage status unavailable", comment: ""), NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: ""))
                } else {
                    //self.selectedOutageStatus = nil
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }
    
    var submitButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(phoneNumberTextFieldEnabled, phoneNumberHasTenDigits, accountNumberTextFieldEnabled, accountNumberHasTenDigits).map {
            return ($0 && $1) || ($2 && $3)
        }
    }
    
    var phoneNumberTextFieldEnabled: Driver<Bool> {
        return accountNumber.asDriver().map { $0.isEmpty }
    }
    
    var accountNumberTextFieldEnabled: Driver<Bool> {
        return phoneNumber.asDriver().map { $0.isEmpty }
    }
    
    var phoneNumberHasTenDigits: Driver<Bool> {
        return self.phoneNumber.asDriver().map { [weak self] text -> Bool in
            guard let `self` = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.characters.count == 10
        }
    }
    
    var accountNumberHasTenDigits: Driver<Bool> {
        return self.accountNumber.asDriver().map {
            $0.characters.count == 10
        }
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage {
            let timeString = Environment.sharedInstance.opcoDateFormatter.string(from: reportedOutage.reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        return NSLocalizedString("Reported", comment: "")
    }
    
    var estimatedRestorationDateString: String {
        if let reportedOutage = reportedOutage {
            if let reportedETR = reportedOutage.etr {
                return Environment.sharedInstance.opcoDateFormatter.string(from: reportedETR)
            }
        } else if let statusETR = selectedOutageStatus!.etr {
            return Environment.sharedInstance.opcoDateFormatter.string(from: statusETR)
        }
        return NSLocalizedString("Assessing Damage", comment: "")
    }
    
    var accountNonPayFinaledMessage: String {
        if Environment.sharedInstance.opco == .bge {
            return NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
        } else {
            if selectedOutageStatus!.flagFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if selectedOutageStatus!.flagNoPay {
                return NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
        }
        return ""
    }
    
    var footerText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123", comment: "")
        case .comEd:
            return NSLocalizedString("To report a downed or sparking power line, please call 1-800-334-7661", comment: "")
        case .peco:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
        }
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}
