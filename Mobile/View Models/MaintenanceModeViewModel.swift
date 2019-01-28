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
            let phone2 = "1-877-778-2222"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat("If you smell natural gas or see downed power lines, %@ and then call BGE at %@\n\nIf your power is out, call %@\n\nRepresentatives are available 24 hours a day, 7 days a week.", leaveAreaString, phone1, phone2)
        case .comEd:
            let phone = "1-800-334-7661"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat("If you see downed power lines, %@ and then call ComEd at %@\n\nRepresentatives are available 24 hours a day, 7 days a week.", leaveAreaString, phone)
        case .peco:
            let phone = "1-800-841-4141"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat("If you smell natural gas or see downed power lines, %@ and then call PECO at %@\n\nRepresentatives are available 24 hours a day, 7 days a week.", leaveAreaString, phone)
        }
        
        let emergencyAttrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        
        for phone in phoneNumbers {
            emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phone))
        }
        
        return emergencyAttrString
    }()
    
    let footerLabelText: NSAttributedString = {
        let phoneString: String
        switch Environment.shared.opco {
        case .bge:
            phoneString = "1-800-685-0123"
        case .comEd:
            phoneString = "1-800-334-7661"
        case .peco:
            phoneString = "1-800-494-4000"
        }
        
        let localizedString = String(format: NSLocalizedString("For all other inquiries, please call %@ M-F 7AM to 7PM", comment: ""), phoneString)
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
