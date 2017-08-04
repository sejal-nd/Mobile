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

    init(authService: AuthenticationService){
        self.authService = authService
    }
    
    func checkAppVersion(onSuccess: @escaping (Bool) -> Void, onError: @escaping (String) -> Void) {
    
        var isOutOfDate = false
    
        authService.getMinimumVersion()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { versionInfo in
                isOutOfDate = self.checkIfOutOfDate(minVersion: versionInfo.iosObject.minVersion)
                onSuccess(isOutOfDate)
            }, onError: { error in
                _ = error as! ServiceError
            }).disposed(by: disposeBag)
    }
    
    func checkIfOutOfDate(minVersion:String) -> Bool {
        let dictionary = Bundle.main.infoDictionary!
        let currentVersion = dictionary["CFBundleShortVersionString"] as! String
        
        return minVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
}
