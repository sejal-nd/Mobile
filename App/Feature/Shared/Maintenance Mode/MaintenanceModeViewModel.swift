//
//  MaintenanceModeViewModel.swift
//  Mobile
//
//  Created by Constantin Koehler on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class MaintenanceModeViewModel{
    let disposeBag = DisposeBag()

    private var maintenance: Maintenance?
    private var authService: AuthenticationService
    
    init(authService: AuthenticationService, maintenance: Maintenance?){
        self.authService = authService
        self.maintenance = maintenance
    }
    
    var headerLabelText: String {
        let fallbackText = String.localizedStringWithFormat("The %@ App is currently unavailable due to maintenance.", Environment.shared.opco.displayString)
        return maintenance?.allMessage ?? fallbackText
    }
    
    let labelBody: NSAttributedString = {
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
                If you smell natural gas, %@ and call BGE at %@ or %@\n
                If your power is out or for downed or sparking power lines, please call %@ or %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
            , leaveAreaString, phone1, phone2, phone1, phone3)
        case .comEd:
            let phone = "1-800-334-7661"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you see downed power lines, %@ and then call ComEd at %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
            , leaveAreaString, phone)
        case .peco:
            let phone = "1-800-841-4141"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas or see downed power lines, %@ and then call PECO at %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
            , leaveAreaString, phone)
        case .pepco:
            let phone = "1-877-737-2662"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas or see downed power lines, %@ and then call PECO at %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone)
        case .ace:
            let phone = "1-800-833-7476"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you see a downed power line, %@ and then call %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone)
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
        
        let emergencyAttrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: $0)
                }
        }
        
        return emergencyAttrString
    }()
    
    let footerLabelText: NSAttributedString = {
        let phoneString: String
        var timings = "7AM to 7PM"
        switch Environment.shared.opco {
        case .bge:
            phoneString = "1-800-685-0123"
        case .comEd:
            phoneString = "1-800-334-7661"
        case .peco:
            phoneString = "1-800-494-4000"
        case .pepco:
            phoneString = "202-833-7500"
            timings = "7AM to 8PM"
        case .ace:
            phoneString = "1-800-642-3780"
        case .delmarva:
            phoneString = "1-800-375-7117"
        }
        
        let localizedString = String.localizedStringWithFormat("For all other inquiries, please call %@ M-F %@", phoneString, timings)
        let attrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        attrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phoneString))
        return attrString
    }()
    
    func doReload(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        authService.getMaintenanceMode(postNotification: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] maintenanceInfo in
                self?.maintenance = maintenanceInfo
                onSuccess(maintenanceInfo.allStatus)
            }, onError: { error in
                _ = error as! ServiceError
            }).disposed(by: disposeBag)
    }

}
