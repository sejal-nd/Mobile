//
//  ForgotPasswordViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ForgotPasswordViewModel {
    let disposeBag = DisposeBag()
    
    let authService: AuthenticationService
    
    let username = Variable("")
    
    required init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func getInstructionLabelText() -> String {
        return NSLocalizedString("Please enter your username/email address to have a temporary password sent to your primrary email address on file. The temporary password is valid only for 1 hour from the time it was requested.", comment: "")
    }
    
    func submitChangePassword(onSuccess: @escaping () -> Void, onProfileNotFound: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        authService.recoverPassword(username: username.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.FnProfNotFound.rawValue {
                    onProfileNotFound(serviceError.errorDescription!)
                } else {
                    onError(serviceError.localizedDescription)
                }
            }).addDisposableTo(disposeBag)
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return username.asObservable().map({ text -> Bool in
            return text.characters.count > 0
        })
    }
}
