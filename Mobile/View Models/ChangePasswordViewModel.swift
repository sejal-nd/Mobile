//
//  ChangePasswordViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import UIKit

class ChangePasswordViewModel {
    let disposeBag = DisposeBag()
    
    var currentPassword = Variable("")
    var newPassword = Variable("")
    var confirmPassword = Variable("")
    
    required init() {
        
    }
    
    func characterCountValid() -> Observable<Bool> {
        return newPassword.asObservable()
            .map{ text -> String in
                text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
        return newPassword.asObservable().map({ text -> Bool in
            let regex = try! NSRegularExpression(pattern: ".*[^a-zA-Z0-9].*", options: NSRegularExpression.Options.useUnixLineSeparators)
            return regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions.init(rawValue: 0) , range: NSMakeRange(0, text.characters.count)) != nil
        })
    }
    
    func everythingValid() -> Observable<Bool> {
        return Observable.combineLatest(characterCountValid(), containsUppercaseLetter(), containsLowercaseLetter(), containsNumber(), containsSpecialCharacter()) {
            if $0 {
                let otherArray = [$1, $2, $3, $4].filter{ $0 }
                if otherArray.count >= 3 {
                    return true
                }
            }
            return false
        }
    }
    
}
