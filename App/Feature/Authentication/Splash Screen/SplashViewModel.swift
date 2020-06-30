//
//  SplashViewModel.swift
//  Mobile
//
//  Created by Constantin Koehler on 8/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

struct SplashViewModel{
    
    func checkAppVersion(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        var isOutOfDate = false
        AnonymousService.checkMinVersion { (result: Result<String, Error>) in
            switch result {
            case .success(let minVersion):
                isOutOfDate = self.checkIfOutOfDate(minVersion: minVersion)
                onSuccess(isOutOfDate)
            case .failure(let error):
                onError(error.localizedDescription)
            }
        }
    }
    
    func checkIfOutOfDate(minVersion:String) -> Bool {
        let dictionary = Bundle.main.infoDictionary!
        let currentVersion = dictionary["CFBundleShortVersionString"] as! String
        
        return minVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
    func checkStormMode(completion: @escaping (Bool) -> ()) {
        AnonymousService.maintenanceMode { (result: Result<NewMaintenanceMode, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let maintenanceMode):
                    completion(maintenanceMode.storm)
                case .failure(_):
                    completion(false)
                }
            }
        }
    }
    
    var errorTitleText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at BGE.com.", comment: "")
        case .comEd:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at ComEd.com.", comment: "")
        case .peco:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at PECO.com.", comment: "")
        case .pepco:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at Pepco.com.", comment: "")
        case .ace:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at AtlanticCityElectric.com.", comment: "")
        case .delmarva:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at Delmarva.com.", comment: "")
        }
    }
    
    var errorLabelText: NSAttributedString? {
        let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
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
                If you smell natural gas, %@ and call %@ or %@.\n
                If your power is out or for downed or sparking power lines, please call %@ or %@.
                """
                , leaveAreaString, phone1, phone2, phone1, phone3)
        case .comEd:
            let phone = "1-800-334-7661"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you see downed power lines, %@ and then call ComEd at %@.\n
                If your power is out, please call %@ to report your outage.
                """
                , leaveAreaString, phone, phone)
        case .peco:
            let phone = "1-800-841-4141"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas or see downed power lines, %@ and then call PECO at %@.\n
                If your power is out, please call %@ to report your outage.
                """
                , leaveAreaString, phone, phone)
        case .pepco:
            let phone = "1-877-737-2662"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                 If you see a downed power line, %@ and then call %@.\n
                 Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone, phone)
        case .ace:
            let phone = "1-800-833-7476"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you see a downed power line, %@ and then call %@.\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone, phone)
        case .delmarva:
            let phone1 = "1-800-898-8042"
            let phone2 = "302-454-0317"

            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                If you see a downed power line or smell natural gas, %@ and then call %@.\n
                For natural gas emergencies, call %@.\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone1, phone2)
        }
        
        let attrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        attrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: $0)
            }
        }
        
        return attrString
    }
    
    var enquiryFooterText: NSAttributedString? {
        var localizedString: String = ""
        var phoneNumbers = [String]()
        
        switch Environment.shared.opco {
        case .ace:
            let phone = "1-800-833-7476"
                       phoneNumbers = [phone]
                       localizedString = String.localizedStringWithFormat(
                           """
                           For all other inquiries, please call %@ M-F 7AM to 7PM.
                           """
                           ,phone)
        case .bge:
            let phone = "1-800-685-0123"
                       phoneNumbers = [phone]
                       localizedString = String.localizedStringWithFormat(
                           """
                           For all other inquiries, please call %@ M-F 7AM to 7PM.
                           """
                           ,phone)
        case .comEd:
            let phone = "1-800-334-7661"
                       phoneNumbers = [phone]
                       localizedString = String.localizedStringWithFormat(
                           """
                           For all other inquiries, please call %@ M-F 7AM to 7PM.
                           """
                           ,phone)
        case .delmarva:
            let phone = "1-800-375-7117"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                For all other inquiries, please call %@ M-F 7AM to 7PM.
                """
                ,phone)
        case .peco:
            let phone = "1-800-494-4000"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                For all other inquiries, please call %@ M-F 7AM to 7PM.
                """
                ,phone)
        case .pepco:
            let phone = "202-833-7500"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                For all other inquiries, please call %@ M-F 7AM to 8PM.
                """
                ,phone)
        }
            
        let attrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: $0)
            }
        }
        
        return attrString
    }
}
