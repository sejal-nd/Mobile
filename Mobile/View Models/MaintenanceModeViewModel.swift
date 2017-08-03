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
        switch opco {
        case .bge:
            localizedString = String(format: NSLocalizedString("If you smell natural gas or see downed power lines, %@ and then call BGE at 1-800-685-0123\n\nIf your power is out, call 1-877-778-2222", comment: ""),leaveAreaString)
        case .comEd:
            localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd at 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.\nFor all other inquiries, please call 1-800-334-7661 M-F 7AM to 7PM\n\n", comment: ""),leaveAreaString)
        case .peco:
            localizedString = String(format: NSLocalizedString("If you smell natural gas or see downed power lines, %@ and then call PECO at 1-800-841-4141 Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call 1-800-494-4000 M-F 7AM to 7PM\n\n", comment: ""),leaveAreaString)
        }
        
        emergencyAttrString = NSMutableAttributedString(string: localizedString)
        emergencyAttrString.addAttribute(NSFontAttributeName, value: SystemFont.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        
        return emergencyAttrString
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
