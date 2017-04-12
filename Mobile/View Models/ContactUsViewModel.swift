//
//  ContactUsViewModel.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class ContactUsViewModel {
    
    var target: String
    var attrString = NSMutableAttributedString()
    
    init() {
        target = Bundle.main.infoDictionary?["CFBundleName"] as! String
    }
    
    func makeAttributedString() -> NSAttributedString {
        if (target == "BGE") {
            let text = NSLocalizedString("If you see downed power lines or smell natural gas, leave the area immediately and then call BGE. Representatives are available 24 hours a day, 7 days a week.", comment: "")
            attrString = NSMutableAttributedString(string: text)
            let range = NSMakeRange(52, 26)
            attrString.addAttribute(NSFontAttributeName, value: UIFont(name: "OpenSans-BoldItalic", size: 12)!, range: range)
        } else if (target == "PECO") {
            let text = NSLocalizedString("If you see downed power lines or smell natural gas, leave the area immediately and then call PECO. Representatives are available 24 hours a day, 7 days a week.", comment: "")
            attrString = NSMutableAttributedString(string: text)
            let range = NSMakeRange(52, 26)
            attrString.addAttribute(NSFontAttributeName, value: UIFont(name: "OpenSans-BoldItalic", size: 12)!, range: range)
        } else if (target == "ComEd") {
            let text = NSLocalizedString("If you see downed power lines, leave the area immediately and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: "")
            attrString = NSMutableAttributedString(string: text)
            let range = NSMakeRange(31, 26)
            attrString.addAttribute(NSFontAttributeName, value: UIFont(name: "OpenSans-BoldItalic", size: 12)!, range: range)
        } else {
            return NSAttributedString(string: "Could not get text")
        }
        return attrString
    }
    
    func makeLabel1() -> String {
        if (target == "BGE") {
            return NSLocalizedString("Residential", comment: "")
        }
        if (target == "PECO") {
            return NSLocalizedString("All Customers", comment: "")
        }
        if (target == "ComEd") {
            return NSLocalizedString("Residential", comment: "")
        }
        return ""
    }
    
    func makeLabel2() -> String {
        if (target == "BGE") {
            return NSLocalizedString("Business", comment: "")
        }
        if (target == "ComEd") {
            return NSLocalizedString("Business", comment: "")
        }
        return ""
    }
    
    func makeLabel3() -> String {
        if (target == "BGE") {
            return NSLocalizedString("TTY/TTD", comment: "")
        }
        if (target == "ComEd") {
            return NSLocalizedString("Spanish", comment: "")
        }
        return ""
    }
    
}
