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
                if status.allStatus {
                    onError(ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue))
                } else if status.outageStatus {
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
    
    var gasOnlyMessage: NSAttributedString {
        var localizedString: String
        let phoneNumbers: [String]
        switch Environment.shared.opco {
        case .bge:
            let phone1 = "1-800-685-0123"
            let phone2 = "1-877-778-7798"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                We currently do not allow reporting of gas issues online but want to hear from you right away.\n
                If you smell natural gas, leave the area immediately and call %@ or %@.
                """
            , phone1, phone2)
        case .peco:
            let phone1 = "1-800-841-4141"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat(
                """
                We currently do not allow reporting of gas issues online but want to hear from you right away.\n
                To issue a Gas Emergency Order, please call %@.
                """
            , phone1)
        default:
            phoneNumbers = []
            localizedString = NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.", comment: "")
        }
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .subheadline)])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .subheadline), range: $0)
            }
        }
        return attributedText
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
            return true
        case .bge, .peco:
            return false
        }
    }
}
