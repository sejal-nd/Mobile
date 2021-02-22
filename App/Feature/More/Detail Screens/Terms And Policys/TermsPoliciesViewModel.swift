//
//  LoginTermsPoliciesViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TermsPoliciesViewModel {
    
    var agreeLabelText: String {
        get {
            return String(format: NSLocalizedString("I agree to %@'s Privacy Policy and Terms of Use.", comment: ""), Configuration.shared.opco.displayString)
        }
    }
    
    var termPoliciesURL: URL {
        return Bundle.main.url(forResource: "TermPolicies", withExtension: "html")!
    }
    
}
