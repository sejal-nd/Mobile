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
            return String(format: NSLocalizedString("I agree to %@'s Terms and Policies", comment: ""), Environment.sharedInstance.opco.displayString)
        }
    }
    
    var termPoliciesURL: URL {
        return Bundle.main.url(forResource: "TermPolicies", withExtension: "html")!
    }
    
}
