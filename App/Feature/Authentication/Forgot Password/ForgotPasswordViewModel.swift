//
//  ForgotPasswordViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class ForgotPasswordViewModel {
    let disposeBag = DisposeBag()
    
    let authService: AuthenticationService
    
    let username = BehaviorRelay(value: "")
    
    required init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func getInstructionLabelText() -> String {
        return NSLocalizedString("Please enter your username/email address to have a temporary password sent to your primary email address on file. The temporary password is valid only for 1 hour from the time it was requested.", comment: "")
    }
    
    func submitForgotPassword(onSuccess: @escaping () -> Void, onProfileNotFound: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        authService.recoverPassword(username: username.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { error in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.fnProfNotFound.rawValue {
                    onProfileNotFound(serviceError.localizedDescription)
                } else {
                    onError(serviceError.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }
    
    private(set) lazy var submitButtonEnabled: Driver<Bool> = self.username.asDriver().map { $0.count > 0 }
}
