//
//  OutageViewModel.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import UIKit

class OutageViewModel {
    let disposeBag = DisposeBag()
    
    var outageStatus = BehaviorRelay<OutageStatus?>(value: nil)
    var isOutageStatusInactive = false
    var hasJustReportedOutage = false
    var isUserAuthenticated = false
    
    // Feature Flag Values
    var streetlightOutageMapURLString = FeatureFlagUtility.shared.string(forKey: .streetlightMapURL)
    var outageMapURLString = FeatureFlagUtility.shared.string(forKey: .outageMapURL)
    
    // Passed from unauthenticated experience
    var accountNumber: String?
    
    func fetchData(onSuccess: @escaping (OutageStatus) -> Void,
                   onError: @escaping (NetworkingError) -> Void,
                   onMaintenance: @escaping () -> Void) {
        
        
        AnonymousService.maintenanceMode { [weak self] result in
            switch result {
            case .success(let maintenanceMode):
                if maintenanceMode.all {
                    onError(NetworkingError.maintenanceMode)
                } else if maintenanceMode.outage {
                    onMaintenance()
                } else {
                    self?.getOutageStatus(onSuccess: onSuccess, onError: onError)
                }
            case .failure:
                self?.getOutageStatus(onSuccess: onSuccess, onError: onError)
            }
        }
    }
    
    func getOutageStatus(onSuccess: @escaping (OutageStatus) -> Void, onError: @escaping (NetworkingError) -> Void) {
        OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumberString: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { result in
            switch result {
            case .success(let outageStatus):
                self.outageStatus.accept(outageStatus)
                
                // todo i think i can refactor this out.
                if outageStatus.isInactive {
                    self.isOutageStatusInactive = true
                }
                
                onSuccess(outageStatus)
            case .failure(let error):
                switch error {
                case .finaled:
                    onSuccess(OutageStatus(finaled: true))
                    break
                case .noPay:
                    onSuccess(OutageStatus(noPay: true))
                    break
                case .noService:
                    onSuccess(OutageStatus(noService: true))
                    break
                case .inactive:
                    onSuccess(OutageStatus(inactive: true))
                    break
                default:
                    onError(error)
                    break
                }
            }
        }
    }
    
    func trackPhoneNumberAnalytics(isAuthenticated: Bool, for URL: URL) {
        let urlString = URL.absoluteString
        
        switch Configuration.shared.opco {
        case .bge:
            switch urlString {
            case "tel:1-800-685-0123":
                FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_main]))
            case "tel:1-877-778-7798":
                FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_emergency_gas]))
            case "tel:1-877-778-2222":
                FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_emergency_electric]))
            default:
                break
            }
        case .comEd:
            FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_main]))
        case .peco:
            FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_main]))
        case .pepco:
            FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_main]))
        case .ace:
            FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_main]))
        case .delmarva:
            FirebaseUtility.logEvent(isAuthenticated ? .authOutage(parameters: [.phone_number_main]) : .unauthOutage(parameters: [.phone_number_main]))
        }
    }
    
    func clearETR() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "etaDateTime")
        defaults.removeObject(forKey: "etaCause")
        defaults.removeObject(forKey: "etaDetail")
    }
    
    var reportedOutage: ReportedOutageResult? {
        if let accountNumber = accountNumber {
            return OutageService.getReportedOutageResult(accountNumber: accountNumber)
        } else {
            return OutageService.getReportedOutageResult(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
        }
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage, let reportedTime = reportedOutage.reportedTime {
            let timeString = DateFormatter.outageOpcoDateFormatter.string(from: reportedTime)
            if let accountNum = !isUserAuthenticated ? accountNumber : AccountsStore.shared.currentAccount.accountNumber {
                UserDefaults.standard.set(timeString, forKey: accountNum)
                UserDefaults.standard.set(reportedTime, forKey: UserDefaultKeys.reportedOutageTime + "-" + accountNum)
                UserDefaults.standard.synchronize()
            }
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }

        return NSLocalizedString("Reported", comment: "")
    }

    var footerTextViewText: NSAttributedString {
        var localizedString: String
        let phoneNumbers: [String]
        switch Configuration.shared.opco {
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
            let phone2 = "1-844-841-4151"
            phoneNumbers = [phone1, phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                To report a downed or sparking power line, please call %@.\n
                If you smell natural gas, leave the area immediately and call %@ or %@.
                """
                , phone1, phone1, phone2)
        case .pepco:
            let phone1 = "1-877-737-2662"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a downed or sparking power line, please call %@", phone1)
        case .ace:
            let phone1 = "1-800-833-7476"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("If you see downed power lines, leave the area immediately and call Atlantic City Electric at %@.", phone1)
        case .delmarva:
            let phone1 = "302-454-0317"
            let phone2 = "1-800-898-8042"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat("""
                If you smell natural gas, leave the area immediately and then call %@\n
                To report a downed or sparking power line, please call %@
                """, phone1, phone2)
        }
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: UIFont.caption1])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: UIFont.caption1Semibold, range: $0)
            }
        }
        return attributedText
    }
}
