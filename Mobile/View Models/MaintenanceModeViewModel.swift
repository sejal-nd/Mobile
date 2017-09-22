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
    let opco = Environment.sharedInstance.opco
    let disposeBag = DisposeBag()

    private var authService: AuthenticationService
    
    init(authService: AuthenticationService){
        self.authService = authService
    }
    
    func getHeaderLabelText() -> String {
        switch opco {
        case .bge: return NSLocalizedString("The BGE App is currently unavailable due to scheduled maintenance.", comment: "")
        case .peco: return NSLocalizedString("The PECO App is currently unavailable due to scheduled maintenance.", comment: "")
        case .comEd: return NSLocalizedString("The ComEd App is currently unavailable due to scheduled maintenance.", comment: "")
        }
    }
    
    func getLabelBody() -> NSAttributedString {
        let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
        let emergencyAttrString: NSMutableAttributedString
        var localizedString: String
        
        let phone1: String
        let phone2: String
        switch opco {
        case .bge:
            phone1 = "1-800-685-0123"
            phone2 = "1-877-778-2222"
            localizedString = String(format: NSLocalizedString("If you smell natural gas or see downed power lines, %@ and then call BGE at %@\n\nIf your power is out, call %@", comment: ""), leaveAreaString, phone1, phone2)
        case .comEd:
            phone1 = "1-800-334-7661"
            phone2 = "\n1-800-334-7661" // Included the line break in the second number so the range(of:) method could find it, and bold it. Not hacky at all 👀
            localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd at %@ Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call%@ M-F 7AM to 7PM\n\n", comment: ""), leaveAreaString, phone1, phone2)
        case .peco:
            phone1 = "1-800-841-4141"
            phone2 = "1-800-494-4000"
            localizedString = String(format: NSLocalizedString("If you smell natural gas or see downed power lines, %@ and then call PECO at %@ Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n%@ M-F 7AM to 7PM\n\n", comment: ""), leaveAreaString, phone1, phone2)
        }
        
        emergencyAttrString = NSMutableAttributedString(string: localizedString)
        emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phone1))
        emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phone2))
        
        return emergencyAttrString
    }
    
    var bgeInquiriesLabelText: NSAttributedString {
        let phoneString = "1-800-685-0123"
        let localizedString = String(format: NSLocalizedString("For all other inquiries, please call\n%@ M-F 7AM to 7PM", comment: ""), phoneString)
        let attrString = NSMutableAttributedString(string: localizedString)
        attrString.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phoneString))
        return attrString
    }
    
    func isBGE() -> Bool {
        return opco == .bge
    }
    
    func doReload(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        var isMaintenanceMode = true
        
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenanceInfo in
                isMaintenanceMode = maintenanceInfo.allStatus
                onSuccess(isMaintenanceMode)
            }, onError: { error in
                _ = error as! ServiceError
            }).disposed(by: disposeBag)
    }

}
