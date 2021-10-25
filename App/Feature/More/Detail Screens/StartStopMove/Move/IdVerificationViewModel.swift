//
//  IdVerificationViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 26/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
class IdVerificationViewModel {
    
    var moveDataFlow: MoveServiceFlowData!
    var identityVerification: IdentityVerification!

    init(moveDataFlow: MoveServiceFlowData) {
        
        self.moveDataFlow = moveDataFlow
        self.identityVerification = IdentityVerification()
    }
    
    func isValidSSN(ssn: String)-> Bool {
        
        return (ssn.count == 0 || ssn.count == 9)
    }
    
    func validateAge(selectedDate: Date) -> Bool {
        
        let minAge = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        if (selectedDate < minAge){
            return true
        } else{
            return false
        }
    }
    
    func validation()-> Bool {
        
        if !(identityVerification.SSNNumber == nil || (identityVerification.SSNNumber?.count ?? 0) == 0 || (identityVerification.SSNNumber?.count ?? 0) == 9) || identityVerification.dateOfBirth == nil || identityVerification.employmentStatus == nil {
            return false
        }
        return true
    }
    
    func isValidSSN(ssn: String, inputString: String)-> Bool {
        
        let isValidTextCount = ssn.count < 9
        let char = inputString.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        if isBackSpace == -92 {
            return true
        }
        return isValidTextCount
    }
    
    func isValidDrivingLicense(drivingLicense: String, inputString: String)-> Bool {
        
        let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: [])
        let isValidTextCount = drivingLicense.count < 15
        let char = inputString.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        if isBackSpace == -92 {
            return true
        }
        if regex.firstMatch(in: inputString, options: [], range: NSMakeRange(0, inputString.count)) != nil {
            return false
        }
        return isValidTextCount
    }
}
