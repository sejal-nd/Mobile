//
//  ContactUsViewModel.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class ContactUsViewModel {
    
    var target: OpCo
    var emergencyAttrString = NSMutableAttributedString()
    var label1 = ""
    var label2 = ""
    var label3 = ""
    var facebookURL = ""
    var twitterURL = ""
    var youtubeURL = ""
    var linkedinURL = ""
    var instagramURL = ""
    var pinterestURL = ""
    var flickrURL = ""
    var phoneNumber1 = ""
    var phoneNumber2 = ""
    var phoneNumber3 = ""
    var phoneNumber4 = ""
    
    init() {
        target = Environment.sharedInstance.opco
        setEmergencyAttributedString()
        setLabel()
        setLabel2()
        setLabel3()
        setSocialMediaURLs()
        setPhoneNumbers()
    }
    
    func setEmergencyAttributedString() {
        switch target {
        case .bge:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call BGE. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.ofSize(12), range: (localizedString as NSString).range(of: leaveAreaString))
        case .peco:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call PECO. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.ofSize(12), range: (localizedString as NSString).range(of: leaveAreaString))
        case .comEd:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.ofSize(12), range: (localizedString as NSString).range(of: leaveAreaString))
        }
    }
    
    func setLabel() {
        switch target {
        case .bge:
            label1 = NSLocalizedString("Residential", comment: "")
        case .peco:
            label1 = NSLocalizedString("All Customers", comment: "")
        case .comEd:
            label1 = NSLocalizedString("Residential", comment: "")
        }
    }
    
    func setLabel2() {
        switch target {
        case .bge:
            label2 = NSLocalizedString("Business", comment: "")
        case .comEd:
            label2 = NSLocalizedString("Business", comment: "")
        case .peco:
            label2 =  ""
        }
    }
    
    func setLabel3() {
        switch target {
        case .bge:
            label3 = NSLocalizedString("TTY/TTD", comment: "")
        case .comEd:
            label3 =  NSLocalizedString("Spanish", comment: "")
        case .peco:
            label2 =  ""
        }
    }
    
    func setSocialMediaURLs() {
        switch target {
        case .bge:
            facebookURL = "https://www.facebook.com/myBGE"
            twitterURL = "https://twitter.com/mybge"
            youtubeURL = "https://www.youtube.com/user/BaltimoreGasElectric"
            linkedinURL = "https://www.linkedin.com/company/5115"
            flickrURL = "https://www.flickr.com/photos/mybge"
        case .peco:
            facebookURL = "https://www.facebook.com/pecoconnect"
            twitterURL = "https://www.twitter.com/pecoconnect"
            youtubeURL = "https://www.youtube.com/pecoconnect"
            linkedinURL = "https://www.linkedin.com/" // TODO: TEMPORARY LINK
            flickrURL = "https://www.flickr.com/pecoconnect"
        case .comEd:
            facebookURL = "https://www.facebook.com/ComEd"
            twitterURL = "https://twitter.com/ComEd"
            youtubeURL = "https://www.youtube.com/user/CommonwealthEdison/ComEd"
            linkedinURL = "https://www.linkedin.com/company/comed"
            instagramURL = "https://www.instagram.com/commonwealthedison/"
            pinterestURL = "https://www.pinterest.com/comedil/"
            flickrURL = "https://www.flickr.com/photos/commonwealthedison"
        }
    }
    
    func setPhoneNumbers() {
        switch target {
        case .bge:
            phoneNumber1 = "1-800-685-0123"
            phoneNumber2 = "1-800-685-0123"
            phoneNumber3 = "1-800-265-6177"
            phoneNumber4 = "1-800-735-2258"
        case .peco:
            phoneNumber1 = "1-800-841-4141"
            phoneNumber2 = "1-800-494-4000"
        case .comEd:
            phoneNumber1 = "1-800-334-7661"
            phoneNumber2 = "1-800-334-7661"
            phoneNumber3 = "1-877-426-6331"
            phoneNumber4 = "1-800-955-8237"
        }
    }
    
}
