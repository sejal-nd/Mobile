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
        
    let username = BehaviorRelay(value: "")
    
    func getInstructionLabelText() -> String {
        return (Environment.shared.opco == .bge || Environment.shared.opco == .peco || Environment.shared.opco == .comEd) ? NSLocalizedString("Please enter your username/email address to have a temporary password sent to your primary email address on file. The temporary password is valid only for 1 hour from the time it was requested.", comment: "") : NSLocalizedString("Please enter your username and we will send a temporary password to the email address on file. Your temporary password will only be valid for 1 hour from the time it is requested.", comment: "")
    }
    
    func submitForgotPassword(onSuccess: @escaping () -> Void, onProfileNotFound: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
        let usernameRequest = UsernameRequest(username: username.value)
        AnonymousService.recoverPassword(request: usernameRequest) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                if error == .profileNotFound {
                    onProfileNotFound(error.description)
                } else {
                    onError(error.description)
                }
            }
        }
    }
    
    private(set) lazy var submitButtonEnabled: Driver<Bool> = self.username.asDriver().map { $0.count > 0 }
}
