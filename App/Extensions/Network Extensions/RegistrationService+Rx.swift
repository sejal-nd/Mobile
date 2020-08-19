//
//  RegistrationService+Rx.swift
//  Mobile
//
//  Created by Cody Dillon on 8/19/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift
import RxSwiftExt

extension RegistrationService: ReactiveCompatible {}

extension Reactive where Base == RegistrationService {
    static func createAccount(request: AccountRequest) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            RegistrationService.createAccount(request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
    
    static func checkDuplicateRegistration(request: UsernameRequest) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            RegistrationService.checkDuplicateRegistration(request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
    
    static func getRegistrationQuestions() -> Observable<[String]> {
        return Observable.create { observer -> Disposable in
            RegistrationService.getRegistrationQuestions() { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func validateRegistration(request: ValidateAccountRequest) -> Observable<ValidatedAccountResponse> {
        return Observable.create { observer -> Disposable in
            RegistrationService.validateRegistration(request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }
    }
    
    static func sendConfirmationEmail(request: UsernameRequest) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            RegistrationService.sendConfirmationEmail(request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
    
    static func validateConfirmationEmail(request: GuidRequest) -> Observable<Void> {
        return Observable<VoidDecodable>.create { observer -> Disposable in
            RegistrationService.validateConfirmationEmail(request: request) { observer.handle(result: $0) }
            return Disposables.create()
        }.mapTo(())
    }
}
