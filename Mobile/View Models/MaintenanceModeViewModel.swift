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
    
    var emergencyAttrString: NSAttributedString {
        let emergencyAttrString: NSMutableAttributedString
        switch opco {
        case .bge:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call BGE. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .peco:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call PECO. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .comEd:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        }
        return emergencyAttrString
    }
    
    func getHeaderLabelText() -> String {
        switch opco {
        case .bge: return NSLocalizedString("The BGE App is currently unavailable due to scheduled maintenance.", comment: "")
        case .peco: return NSLocalizedString("The PECO App is currently unavailable due to scheduled maintenance.", comment: "")
        case .comEd: return NSLocalizedString("The ComEd App is currently unavailable due to scheduled maintenance.", comment: "")
        }
    }
    
    func getLabel1Text() -> String {
        switch opco {
        case .bge: return NSLocalizedString("For a power outage, downed or sparking power lines, or dim/flickering lights, please call 1-877-778-2222", comment: "")
        case .comEd: return NSLocalizedString("To report a gas emergency, a downed or sparking power line or a power outage, please call 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.", comment: "")
        case .peco: return NSLocalizedString("To report a gas emergency, a downed or sparking power line or a power outage, please call 1-800-841-4141 Representatives are available 24 hours a day, 7 days a week.", comment: "")
        }
    }
    
    func getLabel2Text() -> String {
        switch opco {
        case .bge: return NSLocalizedString("For a power outage, downed or sparking power lines, or dim/flickering lights, please call 1-877-778-2222", comment: "")
        case .comEd: return NSLocalizedString("To report a gas emergency, a downed or sparking power line or a power outage, please call 1-800-334-7661 Representatives are available 24 hours a day, 7 days a week.", comment: "")
        case .peco: return NSLocalizedString("For all other inquiries, please call 1-800-494-4000 M-F 7AM to 7PM", comment: "")
        }
    }
    
    func getLabel3Text() -> String? {
        switch opco{
            case .bge: return NSLocalizedString("Representatives are available 24 hours a day, 7 days a week.", comment: "")
        default:
            return nil
        }
    }
    
    func getLabel4Text() -> String? {
        switch opco{
        case .bge: return NSLocalizedString("For all other inquiries, please call 1-800-685-0123 M-F 7AM to 7PM", comment: "")
        default:
            return nil
        }
    }
    
    func doReload(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
        var isMaintenanceMode = true
        
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenanceInfo in
                isMaintenanceMode = maintenanceInfo.getIsOutage
                onSuccess(isMaintenanceMode)
            }, onError: { error in
                let serviceError = error as! ServiceError
            }).addDisposableTo(disposeBag)
    }

}
