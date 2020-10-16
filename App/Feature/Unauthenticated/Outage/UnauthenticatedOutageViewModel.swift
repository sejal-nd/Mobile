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
    
    let phoneNumber = BehaviorRelay(value: "")
    let accountNumber = BehaviorRelay(value: "")
    
    var outageStatusArray = [OutageStatus]()
    let selectedOutageStatus = BehaviorRelay<OutageStatus?>(value: nil)
    
    var reportedOutage: ReportedOutageResult? {
        return OutageService.getReportedOutageResult(accountNumber: accountNumber.value)
    }
    
    func fetchOutageStatus(overrideAccountNumber: String? = nil, onSuccess: @escaping () -> Void, onError: @escaping (String, String) -> Void) {
        let requestPhoneNumber: String? = phoneNumber.value.isEmpty ? nil : phoneNumber.value
        let requestAccountNumber: String? = overrideAccountNumber ?? (accountNumber.value.isEmpty ? nil : accountNumber.value)
        
        selectedOutageStatus.accept(nil)
        
        OutageService.fetchAnonOutageStatus(phoneNumber: requestPhoneNumber,
                                               accountNumber: requestAccountNumber) { result in
                                                switch result {
                                                case .success(let anonOutageStatusContainer):
                                                    let outageStatuses = anonOutageStatusContainer.statuses
                                                    if outageStatuses.isEmpty { // Should never happen, but just in case
                                                        onError(NSLocalizedString("Error", comment: ""), NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: ""))
                                                    } else if outageStatuses.count == 1 {
                                                        self.selectedOutageStatus.accept(outageStatuses.first!)
                                                        if outageStatuses.first!.isGasOnly {
                                                            switch Environment.shared.opco {
                                                            case .bge:
                                                                onError(NSLocalizedString("Outage status unavailable", comment: ""), NSLocalizedString("This account receives gas service only. We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo report a gas emergency or a downed or sparking power line, please call 1-800-685-0123.", comment: ""))
                                                                return
                                                            case .peco:
                                                                onError(NSLocalizedString("Gas Only Account", comment: ""), NSLocalizedString("This account receives gas service only. We currently do not allow reporting of gas issues online but want to hear from you right away.\n\nTo issue a Gas Emergency Order, please call 1-800-841-4141.", comment: ""))
                                                                return
                                                            case .delmarva:
                                                                onError(NSLocalizedString("Gas Only Account", comment: ""), NSLocalizedString("Natural gas emergencies cannot be reported online, but we want to hear from you right away.\n\nIf you smell natural gas, leave the area immediately and then call 302-454-0317.", comment: ""))
                                                                return
                                                            default:
                                                                break
                                                            }
                                                        }
                                                    } else {
                                                        if overrideAccountNumber == nil {
                                                            self.outageStatusArray = outageStatuses
                                                        } else {
                                                            self.selectedOutageStatus.accept(outageStatuses[0])
                                                        }
                                                    }
                                                    onSuccess()
                                                case .failure(let error):
                                                    onError(error.title, error.description)
                                                }
        }
    }
    
    var continueButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(phoneNumberTextFieldEnabled, phoneNumberHasTenDigits, accountNumberTextFieldEnabled, accountNumberHasValidlength).map {
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
    
    var accountNumberHasValidlength: Driver<Bool> {
        return self.accountNumber.asDriver().map {
            $0.count == (Environment.shared.opco.isPHI ? 11 : 10)
        }
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage, let reportedTime = reportedOutage.reportedTime {
            let timeString = DateFormatter.outageOpcoDateFormatter.string(from: reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        return NSLocalizedString("Reported", comment: "")
    }
    
    var estimatedRestorationDateString: String {
        if let reportedOutage = reportedOutage {
            if let reportedETR = reportedOutage.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: reportedETR)
            }
        } else if let statusETR = selectedOutageStatus.value!.estimatedRestorationDate {
            return DateFormatter.outageOpcoDateFormatter.string(from: statusETR)
        }
        return Environment.shared.opco.isPHI ? NSLocalizedString("Pending Assessment", comment: "") : NSLocalizedString("Assessing Damage", comment: "")
    }
    
    var accountNonPayFinaledMessage: String {
        if Environment.shared.opco == .bge {
            return NSLocalizedString("Outage status and report an outage may not be available for this account. Please call Customer Service at 1-877-778-2222 for further information.", comment: "")
        } else {
            if selectedOutageStatus.value!.isFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if selectedOutageStatus.value!.isNoPay {
                return NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
        }
        return ""
    }
    
    var accountNotFoundMessage: String {
        var contactNumber = ""
        switch Environment.shared.opco {
        case .ace:
            contactNumber = "1-800-642-3780"
        case .bge:
            contactNumber = "1-877-778-2222"
        case .comEd:
            contactNumber = "1-800-334-7661"
        case .delmarva:
            contactNumber = "1-800-375-7117"
        case .peco:
            contactNumber = "1-800-494-4000"
        case .pepco:
            contactNumber = "202-833-7500"
        }
        return NSLocalizedString("The information entered does not match our records. Please double check that the information entered is correct and try again.\n\n Still not working? Outage status and report an outage may not be available for this account. Please call Customer Service at \(contactNumber) for further assistance.", comment: "")
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
        case .pepco:
            let phone1 = "1-877-737-2662"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a downed or sparking power line, please call %@", phone1)
        case .ace:
            let phone1 = "1-800-833-7476"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a downed or sparking power line, please call %@", phone1)
        case .delmarva:
            let phone1 = "302-454-0317"
            let phone2 = "1-800-898-8042"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat("""
            If you smell natural gas, leave the area immediately and then call %@\n
            To report a downed or sparking power line, please call %@
            """, phone1, phone2)
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
    
    func checkForMaintenance(onOutageOnly: @escaping (MaintenanceMode) -> Void, onNeither: @escaping () -> Void) {
        AnonymousService.maintenanceMode { (result: Result<MaintenanceMode, Error>) in
            switch result {
            case .success(let maintenanceMode):
                if !maintenanceMode.all && maintenanceMode.outage {
                    onOutageOnly(maintenanceMode)
                } else {
                    onNeither()
                }
            case .failure(_):
                onNeither()
            }
        }
    }
}
