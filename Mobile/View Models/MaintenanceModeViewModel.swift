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
        
        let phone1: String
        let phone2: String
        switch Environment.shared.opco {
        case .bge:
            phone1 = "1-800-685-0123"
            phone2 = "1-877-778-2222"
            localizedString = String.localizedStringWithFormat("If you smell natural gas or see downed power lines, %@ and then call BGE at %@\n\nIf your power is out, call %@\n\nRepresentatives are available 24 hours a day, 7 days a week.", leaveAreaString, phone1, phone2)
        case .comEd:
            phone1 = "1-800-334-7661"
            phone2 = "\n1-800-334-7661" // Included the line break in the second number so the range(of:) method could find it, and bold it. Not hacky at all 👀
            localizedString = String.localizedStringWithFormat("If you see downed power lines, %@ and then call ComEd at %@ Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call%@ M-F 7AM to 7PM", leaveAreaString, phone1, phone2)
        case .peco:
            phone1 = "1-800-841-4141"
            phone2 = "1-800-494-4000"
            localizedString = String.localizedStringWithFormat("If you smell natural gas or see downed power lines, %@ and then call PECO at %@ Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n%@ M-F 7AM to 7PM", leaveAreaString, phone1, phone2)
        }
        
        let emergencyAttrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phone1))
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phone2))
        
        return emergencyAttrString
    }()
    
    let bgeInquiriesLabelText: NSAttributedString = {
        let phoneString = "1-800-685-0123"
        let localizedString = String(format: NSLocalizedString("For all other inquiries, please call\n%@ M-F 7AM to 7PM", comment: ""), phoneString)
        let attrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        attrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phoneString))
        return attrString
    }()
    
    let showFooterText = Environment.shared.opco == .bge
    
    func doReload(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] maintenanceInfo in
                self?.maintenance = maintenanceInfo
                onSuccess(maintenanceInfo.allStatus)
            }, onError: { error in
                _ = error as! ServiceError
            }).disposed(by: disposeBag)
    }

}
