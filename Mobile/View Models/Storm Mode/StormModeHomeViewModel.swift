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
    
    private var currentGetOutageStatusDisposable: Disposable?
    
    var currentOutageStatus: OutageStatus?
    
    init(authService: AuthenticationService, outageService: OutageService) {
        self.authService = authService
        self.outageService = outageService
    }
    
    deinit {
        currentGetOutageStatusDisposable?.dispose()
    }
    
    private(set) lazy var stormModeEnded: Driver<Void> = Observable<Int>
        .interval(stormModePollInterval, scheduler: MainScheduler.instance)
        .toAsyncRequest { [weak self] _ in
            self?.authService.getMaintenanceMode() ?? .empty()
        }
        // Ignore errors and positive storm mode responses
        .elements()
        .filter { !$0.stormModeStatus }
        // Stop polling after storm mode ends
        .take(1)
        .map(to: ())
        .asDriver(onErrorDriveWith: .empty())
    
    func fetchData(onSuccess: @escaping () -> Void,
                   onError: @escaping (ServiceError) -> Void) {
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
//        currentGetMaintenanceModeStatusDisposable?.dispose()
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
    
    var footerTextViewText: NSMutableAttributedString {
        switch Environment.shared.opco {
        case .bge:
            let gasEmergencyText = "To report a gas emergency, please call "
            let gasEmergencyPhoneNumber = NSLocalizedString("1-800-685-0123", comment: "")
            let downedPowerLineText = "\n\nFor downed or sparking power lines or dim/flickering lights, please call "
            let downedPowerLinePhoneNumber = NSLocalizedString("1-877-778-2222", comment: "")
            
            let gasEmergencyTextMutableAttributedString = NSMutableAttributedString(string: gasEmergencyText)
            let gasEmergencyMutableAttributedString = NSMutableAttributedString(string: gasEmergencyPhoneNumber)
            gasEmergencyMutableAttributedString.addAttribute(NSAttributedStringKey.font, value: OpenSans.semibold.of(textStyle: .footnote), range: NSMakeRange(0, gasEmergencyPhoneNumber.count))
            
            let downedPowerLineTextMutableAttributedString = NSMutableAttributedString(string: downedPowerLineText)
            let downedPowerLineMutableAttributedString = NSMutableAttributedString(string: downedPowerLinePhoneNumber)
            downedPowerLineMutableAttributedString.addAttribute(NSAttributedStringKey.font, value: OpenSans.semibold.of(textStyle: .footnote), range: NSMakeRange(0, downedPowerLinePhoneNumber.count))
            
            gasEmergencyTextMutableAttributedString.append(gasEmergencyMutableAttributedString)
            gasEmergencyTextMutableAttributedString.append(downedPowerLineTextMutableAttributedString)
            gasEmergencyTextMutableAttributedString.append(downedPowerLineMutableAttributedString)
            
            return gasEmergencyTextMutableAttributedString
        case .comEd:
            let downedPowerLineText = "To report a downed or sparking power line, please call "
            let downedPowerLinePhoneNumber = NSLocalizedString("1-800-334-7661", comment: "")
            
            let downedPowerLineTextMutableAttributedString = NSMutableAttributedString(string: downedPowerLineText)
            let downedPowerLineMutableAttributedString = NSMutableAttributedString(string: downedPowerLinePhoneNumber)
            downedPowerLineMutableAttributedString.addAttribute(NSAttributedStringKey.font, value: OpenSans.semibold.of(textStyle: .footnote), range: NSMakeRange(0, downedPowerLinePhoneNumber.count))
            
            downedPowerLineTextMutableAttributedString.append(downedPowerLineMutableAttributedString)

            return downedPowerLineTextMutableAttributedString
        case .peco:
            let downedPowerLineText = "To report a gas emergency or a downed or sparking power line, please call "
            let downedPowerLinePhoneNumber = NSLocalizedString("1-800-841-4141", comment: "")
            
            let downedPowerLineTextMutableAttributedString = NSMutableAttributedString(string: downedPowerLineText)
            let downedPowerLineMutableAttributedString = NSMutableAttributedString(string: downedPowerLinePhoneNumber)
            downedPowerLineMutableAttributedString.addAttribute(NSAttributedStringKey.font, value: OpenSans.semibold.of(textStyle: .footnote), range: NSMakeRange(0, downedPowerLinePhoneNumber.count))
            
            downedPowerLineTextMutableAttributedString.append(downedPowerLineMutableAttributedString)
            
            return downedPowerLineTextMutableAttributedString
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
}
