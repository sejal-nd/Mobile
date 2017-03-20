//
//  ChangePasswordViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import UIKit
import Zxcvbn

class ChangePasswordViewModel {
    let disposeBag = DisposeBag()
    
    var currentPassword = Variable("")
    var newPassword = Variable("")
    var confirmPassword = Variable("")
    
    private var userDefaults: UserDefaults
    private var authService: AuthenticationService
    private var fingerprintService: FingerprintService
    
    required init(userDefaults: UserDefaults, authService: AuthenticationService, fingerprintService: FingerprintService) {
        self.userDefaults = userDefaults
        self.authService = authService
        self.fingerprintService = fingerprintService
    }
    
    func currentPasswordHasText() -> Observable<Bool> {
        return currentPassword.asObservable().map{ text -> Bool in
            return text.characters.count > 0
        }
    }
    
    func characterCountValid() -> Observable<Bool> {
        return newPassword.asObservable()
            .map{ text -> String in
                return text.components(separatedBy: .whitespacesAndNewlines).joined()
            }
            .map{ text -> Bool in
                return text.characters.count >= 8 && text.characters.count <= 16
            }
    }
    
    func containsUppercaseLetter() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[A-Z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
        })
    }
    
    func containsLowercaseLetter() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[a-z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
        })
    }
    
    func containsNumber() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
        })
    }
    
    func containsSpecialCharacter() -> Observable<Bool> {
        return newPassword.asObservable()
            .map{ text -> String in
                return text.components(separatedBy: .whitespacesAndNewlines).joined()
            }
            .map({ text -> Bool in
                let regex = try! NSRegularExpression(pattern: ".*[^a-zA-Z0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
                return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
            })
    }
    
    func passwordMatchesUsername() -> Observable<Bool> {
        return newPassword.asObservable().map({ text -> Bool in
            let username = self.userDefaults.string(forKey: UserDefaultKeys.LoggedInUsername)
            return text.lowercased() == username?.lowercased()
        })
    }
    
    func everythingValid() -> Observable<Bool> {
        return Observable.combineLatest(characterCountValid(), containsUppercaseLetter(), containsLowercaseLetter(), containsNumber(), containsSpecialCharacter(), passwordMatchesUsername()) {
            if $0 && !$5 { // Valid character and password != username
                let otherArray = [$1, $2, $3, $4].filter{ $0 }
                if otherArray.count >= 3 {
                    return true
                }
            }
            return false
        }
    }
    
    func getPasswordScore() -> Int32 {
        var score: Int32 = -1
        if newPassword.value.characters.count > 0 {
            score = DBZxcvbn().passwordStrength(newPassword.value).score
        }
        return score
    }
    
    func confirmPasswordMatches() -> Observable<Bool> {
        return Observable.combineLatest(newPassword.asObservable(), confirmPassword.asObservable()) {
            return $0 == $1
        }
    }
    
    func doneButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(everythingValid(), confirmPasswordMatches(), currentPasswordHasText()) {
            return $0 && $1 && $2
        }
    }
    
    func changePassword(onSuccess: @escaping () -> Void, onPasswordNoMatch: @escaping () -> Void, onError: @escaping (String) -> Void) {
        authService.changePassword(currentPassword.value, newPassword: newPassword.value)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { (success: Bool) in
                if self.fingerprintService.isTouchIDEnabled() { // Store the new password in the keychain
                    self.fingerprintService.setStoredPassword(password: self.newPassword.value)
                }
                onSuccess()
            }, onError: { (error: Error) in
                let serviceError = error as! ServiceError
                
                if(serviceError.serviceCode == ServiceErrorCode.FNPwdNoMatch.rawValue) {
                    onPasswordNoMatch()
                } else {
                    onError(error.localizedDescription)
                }
            })
            .addDisposableTo(disposeBag)
    }

    
}
