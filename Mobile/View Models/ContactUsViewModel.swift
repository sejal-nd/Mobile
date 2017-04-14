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
        case "BGE":
            let text = NSLocalizedString("If you see downed power lines or smell natural gas, leave the area immediately and then call BGE. Representatives are available 24 hours a day, 7 days a week.", comment: "")
            emergencyAttrString = NSMutableAttributedString(string: text)
            let range = NSMakeRange(52, 26)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: UIFont(name: "OpenSans-BoldItalic", size: 12)!, range: range)
            break
        case "PECO":
            let text = NSLocalizedString("If you see downed power lines or smell natural gas, leave the area immediately and then call PECO. Representatives are available 24 hours a day, 7 days a week.", comment: "")
            emergencyAttrString = NSMutableAttributedString(string: text)
            let range = NSMakeRange(52, 26)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: UIFont(name: "OpenSans-BoldItalic", size: 12)!, range: range)
            break
        case "ComEd":
            let text = NSLocalizedString("If you see downed power lines, leave the area immediately and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: "")
            emergencyAttrString = NSMutableAttributedString(string: text)
            let range = NSMakeRange(31, 26)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: UIFont(name: "OpenSans-BoldItalic", size: 12)!, range: range)
            break
        default:
            emergencyAttrString = NSMutableAttributedString(string: "Could not get text")
            break
        }
    }
    
    func setLabel() {
        switch target {
        case "BGE":
            label1 = NSLocalizedString("Residential", comment: "")
            break
        case "PECO":
            label1 =  NSLocalizedString("All Customers", comment: "")
            break
        case "ComEd":
            label1 =  NSLocalizedString("Residential", comment: "")
            break
        default:
            label1 =  ""
            break
        }
    }
    
    func setLabel2() {
        switch target {
        case "BGE":
            label2 = NSLocalizedString("Business", comment: "")
            break
        case "ComEd":
            label2 =  NSLocalizedString("Business", comment: "")
            break
        default:
            label2 =  ""
            break
        }
    }
    
    func setLabel3() {
        switch target {
        case "BGE":
            label3 = NSLocalizedString("TTY/TTD", comment: "")
            break
        case "ComEd":
            label3 =  NSLocalizedString("Spanish", comment: "")
            break
        default:
            label2 =  ""
            break
        }
    }
    
    func setSocialMediaURLs() {
        switch target {
        case "BGE":
            facebookURL = "https://www.facebook.com/myBGE"
            twitterURL = "https://twitter.com/mybge"
            youtubeURL = "https://www.youtube.com/user/BaltimoreGasElectric"
            linkedinURL = "https://www.linkedin.com/company/5115"
            flickrURL = "https://www.flickr.com/photos/mybge"
            break
        case "PECO":
            facebookURL = "https://www.facebook.com/pecoconnect"
            twitterURL = "https://www.twitter.com/pecoconnect"
            youtubeURL = "https://www.youtube.com/pecoconnect"
            flickrURL = "https://www.flickr.com/pecoconnect"
            break
        case "ComEd":
            facebookURL = "https://www.facebook.com/ComEd"
            twitterURL = "https://twitter.com/ComEd"
            youtubeURL = "https://www.youtube.com/user/CommonwealthEdison/ComEd"
            linkedinURL = "https://www.linkedin.com/company/comed"
            instagramURL = "https://www.instagram.com/commonwealthedison/"
            pinterestURL = "https://www.pinterest.com/comedil/"
            flickrURL = "https://www.flickr.com/photos/commonwealthedison"
            break
        default:
            break
        }
    }
    
    func setPhoneNumbers() {
        switch target {
        case "BGE":
            phoneNumber1 = "1-800-685-0123"
            phoneNumber2 = "1-800-685-0123"
            phoneNumber3 = "1-800-265-6177"
            phoneNumber4 = "1-800-735-2258"
            break
        case "PECO":
            phoneNumber1 = "1-800-841-4141"
            phoneNumber2 = "1-800-494-4000"
            break
        case "ComEd":
            phoneNumber1 = "1-800-334-7661"
            phoneNumber2 = "1-800-334-7661"
            phoneNumber3 = "1-877-426-6331"
            break
        default:
            break
        }
    }
    
}
