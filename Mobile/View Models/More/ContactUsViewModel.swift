//
//  ContactUsViewModel.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class ContactUsViewModel {
    let opco = Environment.sharedInstance.opco
    
    var emergencyAttrString: NSAttributedString {
        let emergencyAttrString: NSMutableAttributedString
        switch opco {
        case .bge:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call BGE. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .peco:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call PECO. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .comEd:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(NSFontAttributeName, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        }
        return emergencyAttrString
    }
    
    var label1: String {
        switch opco {
        case .bge: return NSLocalizedString("Residential", comment: "")
        case .peco: return NSLocalizedString("All Customers", comment: "")
        case .comEd: return NSLocalizedString("Residential", comment: "")
        }
    }
    
    var label2: String? {
        switch opco {
        case .bge: return NSLocalizedString("Business", comment: "")
        case .comEd: return NSLocalizedString("Business", comment: "")
        case .peco: return  nil
        }
    }
    
    var label3: String? {
        switch opco {
        case .bge: return NSLocalizedString("TTY/TTD", comment: "")
        case .comEd: return  NSLocalizedString("Spanish", comment: "")
        case .peco: return  nil
        }
    }
    
    var phoneNumber1: String? {
        switch opco {
        case .bge: return "1-800-685-0123"
        case .peco: return "1-800-841-4141"
        case .comEd: return "1-800-334-7661"
        }
    }
    
    var phoneNumber2: String? {
        switch opco {
        case .bge: return "1-800-685-0123"
        case .peco: return "1-800-494-4000"
        case .comEd: return "1-800-334-7661"
        }
    }
    
    var phoneNumber3: String? {
        switch opco {
        case .bge: return "1-800-265-6177"
        case .peco: return nil
        case .comEd: return "1-877-426-6331"
        }
    }
    
    var phoneNumber4: String? {
        switch opco {
        case .bge: return "1-800-735-2258"
        case .peco: return nil
        case .comEd: return "1-800-955-8237"
        }
    }
    
    var facebookURL: String? {
        switch opco {
        case .bge: return "https://www.facebook.com/myBGE"
        case .peco: return "https://www.facebook.com/pecoconnect"
        case .comEd: return "https://www.facebook.com/ComEd"
        }
    }
    
    var twitterURL: String? {
        switch opco {
        case .bge: return "https://twitter.com/mybge"
        case .peco: return "https://twitter.com/pecoconnect"
        case .comEd: return "https://twitter.com/ComEd"
        }
    }
    
    var youtubeURL: String? {
        switch opco {
        case .bge: return "https://www.youtube.com/user/BaltimoreGasElectric"
        case .peco: return "https://www.youtube.com/pecoconnect"
        case .comEd: return "https://www.youtube.com/user/CommonwealthEdison/ComEd"
        }
    }
    
    var linkedinURL: String? {
        switch opco {
        case .bge: return "https://www.linkedin.com/company/5115"
        case .peco: return "https://www.linkedin.com/company-beta/4678"
        case .comEd: return "https://www.linkedin.com/company/comed"
        }
    }
    
    var instagramURL: String? {
        switch opco {
        case .bge: return nil
        case .peco: return nil
        case .comEd: return "https://www.instagram.com/commonwealthedison/"
        }
    }
    
    var pinterestURL: String? {
        switch opco {
        case .bge: return nil
        case .peco: return nil
        case .comEd: return "https://www.pinterest.com/comedil/"
        }
    }
    
    var flickrURL: String? {
        switch opco {
        case .bge: return "https://www.flickr.com/photos/mybge"
        case .peco: return "https://www.flickr.com/pecoconnect"
        case .comEd: return "https://www.flickr.com/photos/commonwealthedison"
        }
    }
    
    var buttonInfoList: [(urlString: String?, image: UIImage, accessibilityLabel: String)] {
        switch opco {
        case .comEd:
            return [(facebookURL, #imageLiteral(resourceName: "ic_facebook"), "Facebook"),
                    (twitterURL, #imageLiteral(resourceName: "ic_twitter"), "Twitter"),
                    (youtubeURL, #imageLiteral(resourceName: "ic_youtube"), "YouTube"),
                    (linkedinURL, #imageLiteral(resourceName: "ic_linkedin"), "LinkedIn"),
                    (instagramURL, #imageLiteral(resourceName: "ic_instagram"), "Instagram"),
                    (pinterestURL, #imageLiteral(resourceName: "ic_pinterest"), "Pinterest"),
                    (flickrURL, #imageLiteral(resourceName: "ic_flickr"), "Flicker")]
        case .bge, .peco:
            return [(facebookURL, #imageLiteral(resourceName: "ic_facebook"), "Facebook"),
                    (twitterURL, #imageLiteral(resourceName: "ic_twitter"), "Twitter"),
                    (youtubeURL, #imageLiteral(resourceName: "ic_youtube"), "YouTube"),
                    (linkedinURL, #imageLiteral(resourceName: "ic_linkedin"), "LinkedIn"),
                    (flickrURL, #imageLiteral(resourceName: "ic_flickr"), "Flicker")]
        }
    }
    
}
