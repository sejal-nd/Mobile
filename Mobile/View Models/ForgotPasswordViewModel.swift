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
    
    let username = Variable("")
    
    func getInstructionLabelText() -> String {
        return NSLocalizedString("Please enter your username/email address to have a temporary password sent to your primrary email address on file. The temporary password is valid only for 1 hour from the time it was requested.", comment: "")
    }
    
    func submitChangePassword(onSuccess: @escaping () -> Void, onProfileNotFound: @escaping () -> Void, onError: @escaping (String) -> Void) {
        onSuccess()
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return username.asObservable().map({ text -> Bool in
            return text.characters.count > 0
        })
    }
}
