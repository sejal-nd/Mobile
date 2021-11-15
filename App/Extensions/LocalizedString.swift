//
//  LocalizedString.swift
//  Mobile
//
//  Created by Cody Dillon on 4/2/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func localized(comment: String? = nil) -> String {
        return Configuration.shared.opco == .bge ? localized(tableName: "BGEStrings", comment: comment) : NSLocalizedString(self, comment: comment ?? "")
    }
    
    private func localized(tableName: String? = nil, comment: String? = nil) -> String {
        return NSLocalizedString(self, tableName: tableName, comment: comment ?? "")
    }
}

extension String {
    /// This method will determine whether the entered string is a valid email or not
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z0]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func getValidISUMAddress()-> String {
        
        let capitalizedAddress = self.capitalized
        let capitalizedAddressArray : [String] = capitalizedAddress.components(separatedBy: " ")
        var address = ""
        for value in capitalizedAddressArray {
            if value.count == 2, USState.isUSState(value) {
                address += "\(value.uppercased()) "
            } else if value.count == 3, USState.isUSState(String(value.dropLast())) {
                address += "\(value.dropLast().uppercased()) "
            } else {
                address += "\(value) "
            }
        }
        return address
    }
}
