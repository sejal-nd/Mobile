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
    let selectedOutageStatus = Variable<OutageStatus?>(nil)
    
    var reportedOutage: ReportedOutageResult? {
        return outageService.getReportedOutageResult(accountNumber: accountNumber.value)
    }
    
    let outageService: OutageService!
    private var authService: AuthenticationService


    required init(authService: AuthenticationService,
                  outageService: OutageService) {
        self.authService = authService
        self.outageService = outageService
    }
    
    func fetchOutageStatus(overrideAccountNumber: String? = nil, onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let phone: String? = phoneNumber.value.isEmpty ? nil : phoneNumber.value
        let accountNum: String? = overrideAccountNumber ?? (accountNumber.value.isEmpty ? nil : accountNumber.value)
        
        selectedOutageStatus.value = nil
        outageService.fetchOutageStatusAnon(phoneNumber: phone, accountNumber: accountNum)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] outageStatusArray in
                guard let self = self else { return }
                if outageStatusArray.isEmpty { // Should never happen, but just in case
                    onError(NSLocalizedString("Error", comment: ""), NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: ""))
                } else if outageStatusArray.count == 1 {
                    self.selectedOutageStatus.value = outageStatusArray[0]
                    if self.selectedOutageStatus.value!.flagGasOnly {
                        if Environment.shared.opco == .bge {
                            onError(NSLocalizedString("Outage status unavailable", comment: ""), NSLocalizedString("This account receives gas service only. We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo report a gas emergency or a downed or sparking power line, please call 1-800-685-0123.", comment: ""))
                            return
                        } else if Environment.shared.opco == .peco {
                            onError(NSLocalizedString("Gas Only Account", comment: ""), NSLocalizedString("This account receives gas service only. We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo issue a Gas Emergency Order, please call 1-800-841-4141.", comment: ""))
                            return
                        }
                    }
                } else {
                    if overrideAccountNumber == nil { // Don't replace our original array when fetching again from Results screen
                        self.outageStatusArray = outageStatusArray
                    } else { // Should never happen, but if we call again from result screen and still get multiple results, just use the first
                        self.selectedOutageStatus.value = outageStatusArray[0]
                    }
                }
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnAccountFinaled.rawValue {
                    onError(NSLocalizedString("Finaled Account", comment: ""), NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: ""))
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountNoPay.rawValue {
                    if Environment.shared.opco == .bge {
                        onError(NSLocalizedString("Outage status unavailable", comment: ""), NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: ""))
                    } else {
                        onError(NSLocalizedString("Cut for non pay", comment: ""), NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: ""))
                    }
                } else if serviceError.serviceCode == ServiceErrorCode.fnNonService.rawValue {
                    onError(NSLocalizedString("Outage status unavailable", comment: ""), NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: ""))
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountNotFound.rawValue {
                    onError(NSLocalizedString("Error", comment: ""), self.accountNotFoundMessage)
                } else {
                    onError(NSLocalizedString("Error", comment: ""), error.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }
    
    var continueButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(phoneNumberTextFieldEnabled, phoneNumberHasTenDigits, accountNumberTextFieldEnabled, accountNumberHasTenDigits).map {
            return ($0 && $1) || ($2 && $3)
        }
    }
    
    private(set) lazy var selectAccountButtonEnabled: Driver<Bool> =
        self.selectedOutageStatus.asDriver().isNil().not()
    
    var phoneNumberTextFieldEnabled: Driver<Bool> {
        return accountNumber.asDriver().map { $0.isEmpty }
    }
    
    var accountNumberTextFieldEnabled: Driver<Bool> {
        return phoneNumber.asDriver().map { $0.isEmpty }
    }
    
    var phoneNumberHasTenDigits: Driver<Bool> {
        return self.phoneNumber.asDriver().map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10
        }
    }
    
    var accountNumberHasTenDigits: Driver<Bool> {
        return self.accountNumber.asDriver().map {
            $0.count == 10
        }
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage {
            let timeString = DateFormatter.outageOpcoDateFormatter.string(from: reportedOutage.reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        return NSLocalizedString("Reported", comment: "")
    }
    
    var estimatedRestorationDateString: String {
        if let reportedOutage = reportedOutage {
            if let reportedETR = reportedOutage.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: reportedETR)
            }
        } else if let statusETR = selectedOutageStatus.value!.etr {
            return DateFormatter.outageOpcoDateFormatter.string(from: statusETR)
        }
        return NSLocalizedString("Assessing Damage", comment: "")
    }
    
    var accountNonPayFinaledMessage: String {
        if Environment.shared.opco == .bge {
            return NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
        } else {
            if selectedOutageStatus.value!.flagFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if selectedOutageStatus.value!.flagNoPay {
                return NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
        }
        return ""
    }
    
    var accountNotFoundMessage: String {
        if Environment.shared.opco == .bge {
            return NSLocalizedString("The information entered does not match our records. Please double check that the information entered is correct and try again.\n\nStill not working? Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further assistance.", comment: "")
        } else if Environment.shared.opco == .peco {
            return NSLocalizedString("The information entered does not match our records. Please double check that the information is correct and try again. Still not working? Please call Customer Service at 1-800-494-4000 for further assistance.", comment: "")
        } else {
            return NSLocalizedString("The information entered does not match our records. Please double check that the information is correct and try again. Still not working? Please call Customer Service at 1-800-334-7661 for further assistance.", comment: "")
        }
    }
    
    var footerTextViewText: NSAttributedString {
        var localizedString: String
        let phoneNumbers: [String]
        switch Environment.shared.opco {
        case .bge:
            let phone1 = "1-800-685-0123"
            let phone2 = "1-877-778-7798"
            let phone3 = "1-877-778-2222"
            phoneNumbers = [phone1, phone2, phone3]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, leave the area immediately and call %@ or %@\n
                For downed or sparking power lines, please call %@ or %@
                """
                , phone1, phone2, phone1, phone3)
        case .comEd:
            let phone1 = "1-800-334-7661"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a downed or sparking power line, please call %@", phone1)
        case .peco:
            let phone1 = "1-800-841-4141"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a gas emergency or a downed or sparking power line, please call %@", phone1)
        }
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: $0)
            }
        }
        return attributedText
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }

    func checkForMaintenance(onOutageOnly: @escaping (Maintenance) -> Void, onNeither: @escaping () -> Void) {
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenanceInfo in
                if !maintenanceInfo.allStatus && maintenanceInfo.outageStatus {
                    onOutageOnly(maintenanceInfo)
                } else {
                    onNeither()
                }
            }, onError: { _ in
                onNeither()
            })
            .disposed(by: disposeBag)
    }
}
