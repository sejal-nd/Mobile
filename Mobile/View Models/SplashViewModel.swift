//
//  SplashViewModel.swift
//  Mobile
//
//  Created by Constantin Koehler on 8/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SplashViewModel{
    
    private var authService: AuthenticationService
    let disposeBag = DisposeBag()

    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func checkAppVersion(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
    
        var isOutOfDate = false
    
        authService.getMinimumVersion()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { versionInfo in
                isOutOfDate = self.checkIfOutOfDate(minVersion: versionInfo.iosObject.minVersion)
                onSuccess(isOutOfDate)
            }, onError: { err in
                onError(err.localizedDescription)
            }).disposed(by: disposeBag)
    }
    
    func checkIfOutOfDate(minVersion:String) -> Bool {
        let dictionary = Bundle.main.infoDictionary!
        let currentVersion = dictionary["CFBundleShortVersionString"] as! String
        
        return minVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
    func checkStormMode(completion: @escaping (Bool) -> ()) {
        authService.getMaintenanceMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { maintenance in
                completion(maintenance.stormModeStatus)
            }, onError: { err in
                completion(false)
            })
            .disposed(by: disposeBag)
    }
    
    var errorTitleText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at BGE.com.", comment: "")
        case .comEd:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at ComEd.com.", comment: "")
        case .peco:
            return NSLocalizedString("We’re unable to load the app at this time. Please try again later or visit us at PECO.com.", comment: "")
        }
    }
    
    var errorLabelText: NSAttributedString? {
        var localizedString: String
        
        switch Environment.shared.opco {
        case .bge:
            localizedString = NSLocalizedString("If you smell natural gas or see downed power lines, leave the area immediately, and then call BGE at 1-800-685-0123.\n\n" +
                "If your power is out, please call 1-877-778-2222 to report your outage.", comment: "")
        case .comEd:
            localizedString = NSLocalizedString("If you see downed power lines, leave the area immediately and then call ComEd at 1-800-334-7661.\n\n" +
                "If your power is out, please call 1-800-334-7661 to report your outage.", comment: "")
        case .peco:
            localizedString = NSLocalizedString("If you smell natural gas or see downed power lines, leave the area immediately, and then call PECO at 1-800-841-4141.\n\n" +
                "If your power is out, please call 1-800-841-4141 to report your outage.", comment: "")
        }
        
        let attributedString = NSMutableAttributedString(string: localizedString)
        attributedString.addAttribute(.foregroundColor, value: UIColor.blackText, range: NSMakeRange(0, localizedString.count))
        attributedString.addAttribute(.font, value: OpenSans.regular.of(size: 12), range: NSMakeRange(0, localizedString.count))
        attributedString.addAttribute(.font, value: OpenSans.bold.of(size: 12), range: (localizedString as NSString).range(of: "leave the area immediately"))
        return attributedString
    }
    
}
