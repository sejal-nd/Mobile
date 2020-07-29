//
//  ChangePasswordViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import zxcvbn_ios

class ChangePasswordViewModel {
    let disposeBag = DisposeBag()
    
    var currentPassword = BehaviorRelay(value: "")
    var newPassword = BehaviorRelay(value: "")
    var confirmPassword = BehaviorRelay(value: "")
    
    private var userDefaults: UserDefaults
    private var biometricsService: BiometricsService
    
    // Keeps track of strong password for Analytics
    var hasStrongPassword = false
    
    required init(userDefaults: UserDefaults, biometricsService: BiometricsService) {
        self.userDefaults = userDefaults
        self.biometricsService = biometricsService
    }
    
    private(set) lazy var currentPasswordHasText: Driver<Bool> = self.currentPassword.asDriver()
        .map { $0.count > 0 }
    
    private(set) lazy var characterCountValid: Driver<Bool> = self.newPassword.asDriver()
            .map{ $0.components(separatedBy: .whitespacesAndNewlines).joined() }
            .map{ $0.count >= 8 && $0.count <= 16 }
    
    private(set) lazy var containsUppercaseLetter: Driver<Bool> = self.newPassword.asDriver()
        .map { text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[A-Z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.count)) != nil
        }
    
    private(set) lazy var containsLowercaseLetter: Driver<Bool> = self.newPassword.asDriver()
        .map { text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[a-z].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.count)) != nil
        }
    
    private(set) lazy var containsNumber: Driver<Bool> = self.newPassword.asDriver()
        .map { text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.count)) != nil
        }
    
    private(set) lazy var containsSpecialCharacter: Driver<Bool> = self.newPassword.asDriver()
            .map{ $0.components(separatedBy: .whitespacesAndNewlines).joined() }
            .map { text -> Bool in
                let regex = try! NSRegularExpression(pattern: ".*[^a-zA-Z0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
                return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.count)) != nil
            }
    
    private(set) lazy var passwordMatchesUsername: Driver<Bool> = self.newPassword.asDriver()
        .map { [weak self] text -> Bool in
            let username = self?.userDefaults.string(forKey: UserDefaultKeys.loggedInUsername)
            return text.lowercased() == username?.lowercased()
        }
    
    private(set) lazy var everythingValid: Driver<Bool> = Driver.combineLatest(self.characterCountValid,
                                                                               self.containsUppercaseLetter,
                                                                               self.containsLowercaseLetter,
                                                                               self.containsNumber,
                                                                               self.containsSpecialCharacter,
                                                                               self.passwordMatchesUsername)
    {
        if $0 && !$5 { // Valid character and password != username
            let otherArray = [$1, $2, $3, $4].filter{ $0 }
            if otherArray.count >= 3 {
                return true
            }
        }
        return false
    }
    
    var passwordScore: Int32 {
        var score: Int32 = -1
        if newPassword.value.count > 0 {
            score = DBZxcvbn().passwordStrength(newPassword.value).score
        }
        return score
    }
    
    private(set) lazy var confirmPasswordMatches: Driver<Bool> = Driver.combineLatest(self.newPassword.asDriver(),
                                                                                      self.confirmPassword.asDriver(),
                                                                                      resultSelector: ==)
    
    private(set) lazy var doneButtonEnabled: Driver<Bool> = Driver.combineLatest(self.everythingValid,
                                                                                 self.confirmPasswordMatches,
                                                                                 self.currentPasswordHasText)
    { $0 && $1 && $2 }
    
    func changePassword(tempPasswordWorkflow: Bool,
                        resetPasswordWorkflow: Bool,
                        resetPasswordUsername: String?,
                        onSuccess: @escaping () -> Void,
                        onPasswordNoMatch: @escaping () -> Void,
                        onError: @escaping (String) -> Void) {
        // If Strong Password: force save to SWC prior to changing users passwords, on failure abort.
        if hasStrongPassword && !resetPasswordWorkflow {
            if let loggedInUsername = biometricsService.getStoredUsername() {
                SharedWebCredentials.save(credential: (loggedInUsername, self.newPassword.value),
                                          domain: Environment.shared.associatedDomain) { [weak self] error in
                    DispatchQueue.main.async {
                        if error != nil {
                            // Error Saving SWC
                            onError(NSLocalizedString("Please make sure AutoFill is on in Safari Settings for Names and Passwords when using Strong Passwords.", comment: ""))
                        } else {
                            self?.changePasswordNetworkRequest(anon: tempPasswordWorkflow,
                                                               resetPasswordUsername: resetPasswordUsername,
                                                               shouldSaveToWebCredentials: false,
                                                               onSuccess: onSuccess,
                                                               onPasswordNoMatch: onPasswordNoMatch,
                                                               onError: onError)
                        }
                    }
                }
            } else {
                // Error retrieving loggedInUsername
                onError(NSLocalizedString("There was an error retrieving the logged in user.", comment: ""))
            }
        } else {
            changePasswordNetworkRequest(anon: tempPasswordWorkflow || resetPasswordWorkflow,
                                         resetPasswordUsername: resetPasswordUsername,
                                         shouldSaveToWebCredentials: true,
                                         onSuccess: onSuccess,
                                         onPasswordNoMatch: onPasswordNoMatch,
                                         onError: onError)
        }
    }
    
    private func changePasswordNetworkRequest(anon: Bool,
                                              resetPasswordUsername: String?,
                                              shouldSaveToWebCredentials: Bool,
                                              onSuccess: @escaping () -> Void,
                                              onPasswordNoMatch: @escaping () -> Void,
                                              onError: @escaping (String) -> Void) {
        if anon {
            let changePasswordReqeust = ChangePasswordRequest(username: resetPasswordUsername ?? biometricsService.getStoredUsername() ?? "",
                                                              currentPassword: currentPassword.value,
                                                              newPassword: newPassword.value)
            AnonymousService.changePassword(request: changePasswordReqeust) { [weak self] result in
                switch result {
                case .success:
                    guard let self = self else { return }
                    if self.biometricsService.isBiometricsEnabled() { // Store the new password in the keychain
                        self.biometricsService.setStoredPassword(password: self.newPassword.value)
                    }
                    
                    if #available(iOS 12.0, *) { }
                        // Save to SWC if iOS 11. iOS 12 should handle this automagically.
                    else {
                        if let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername), shouldSaveToWebCredentials {
                            SharedWebCredentials.save(credential: (loggedInUsername, self.newPassword.value), domain: Environment.shared.associatedDomain, completion: { _ in })
                        }
                    }
                    
                    FirebaseUtility.logEvent(.changePasswordNetworkComplete)
                    
                    onSuccess()
                case .failure(let error):
                    if error == .noPasswordMatch {
                        onPasswordNoMatch()
                    } else {
                        onError(error.description)
                    }
                }
            }
        } else {
            let changePasswordReqeust = ChangePasswordRequest(currentPassword: currentPassword.value,
                                                              newPassword: newPassword.value)
            AnonymousService.changePassword(request: changePasswordReqeust) { [weak self] result in
                switch result {
                case .success:
                    guard let self = self else { return }
                    if self.biometricsService.isBiometricsEnabled() { // Store the new password in the keychain
                        self.biometricsService.setStoredPassword(password: self.newPassword.value)
                    }
                    
                    if #available(iOS 12.0, *) { }
                        // Save to SWC if iOS 11. iOS 12 should handle this automagically.
                    else {
                        if let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername), shouldSaveToWebCredentials {
                            SharedWebCredentials.save(credential: (loggedInUsername, self.newPassword.value), domain: Environment.shared.associatedDomain, completion: { _ in })
                        }
                    }
                    
                    FirebaseUtility.logEvent(.changePasswordNetworkComplete)
                    
                    onSuccess()
                case .failure(let error):
                    if error == .noPasswordMatch {
                        onPasswordNoMatch()
                    } else {
                        onError(error.description)
                    }
                }
            }
        }
    }
    
    func submitForgotPassword(username: String, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let usernameRequest = UsernameRequest(username: username)
        AnonymousService.recoverPassword(request: usernameRequest) { result in
            switch result {
            case .success:
                onSuccess()
            case .failure(let error):
                onError(error.description)
            }
        }
    }

}
