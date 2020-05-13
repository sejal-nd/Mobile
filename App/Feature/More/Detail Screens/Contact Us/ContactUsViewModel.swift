//
//  ContactUsViewModel.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class ContactUsViewModel {
    let opco = Environment.shared.opco
    
    var emergencyAttrString: NSAttributedString {
        let emergencyAttrString: NSMutableAttributedString
        switch opco {
        case .bge:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call BGE. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(.font, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .peco:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines or smell natural gas, %@ and then call PECO. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(.font, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .comEd:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(.font, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .pepco:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(.font, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .ace:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(.font, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .delmarva:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(.font, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        }
        return emergencyAttrString
    }
    
    var bgeGasNumber1: String {
        return "1-800-685-0123"
    }
    var bgeGasNumber2: String {
        return "1-877-778-7798"
    }
    var bgePowerLineNumber1: String {
        return "1-800-685-0123"
    }
    var bgePowerLineNumber2: String {
        return "1-877-778-2222"
    }
    
    var onlineFormUrl: URL {
        let urlString: String
        switch Environment.shared.opco {
        case .bge:
            urlString = "https://bge.custhelp.com/app/ContactUs"
        case .comEd:
            urlString = "https://secure.comed.com/MyAccount/CustomerSupport/Pages/ContactUsForms.aspx"
        case .peco:
            urlString = "https://secure.peco.com/MyAccount/CustomerSupport/Pages/ContactUsForms.aspx"
        case .pepco:
            urlString = "todo"
        case .ace:
            urlString = "todo"
        case .delmarva:
            urlString = "todo"
        }
        
        return URL(string: urlString)!
    }
    
    var label1: String {
        switch opco {
        case .bge: return NSLocalizedString("Residential", comment: "")
        case .peco: return NSLocalizedString("All Customers", comment: "")
        case .comEd: return NSLocalizedString("Residential", comment: "")
        case .pepco:
            return NSLocalizedString("todo", comment: "")
        case .ace:
            return NSLocalizedString("todo", comment: "")
        case .delmarva:
            return NSLocalizedString("todo", comment: "")
        }
    }
    
    var label2: String? {
        switch opco {
        case .bge: return NSLocalizedString("Business", comment: "")
        case .comEd: return NSLocalizedString("Business", comment: "")
        case .peco: return  nil
        case .pepco:
            return NSLocalizedString("todo", comment: "")
        case .ace:
            return NSLocalizedString("todo", comment: "")
        case .delmarva:
            return NSLocalizedString("todo", comment: "")
        }
    }
    
    var label3: String? {
        switch opco {
        case .bge: return NSLocalizedString("TTY/TTD", comment: "")
        case .comEd: return NSLocalizedString("Spanish", comment: "")
        case .peco: return nil
        case .pepco:
            return NSLocalizedString("todo", comment: "")
        case .ace:
            return NSLocalizedString("todo", comment: "")
        case .delmarva:
            return NSLocalizedString("todo", comment: "")
        }
    }
    
    var phoneNumber1: String? {
        switch opco {
        case .bge: return nil
        case .peco: return "1-800-841-4141"
        case .comEd: return "1-800-334-7661"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var phoneNumber2: String? {
        switch opco {
        case .bge: return "1-800-685-0123"
        case .peco: return "1-800-494-4000"
        case .comEd: return "1-800-334-7661"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var phoneNumber3: String? {
        switch opco {
        case .bge: return "1-800-265-6177"
        case .peco: return nil
        case .comEd: return "1-877-426-6331"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var phoneNumber4: String? {
        switch opco {
        case .bge: return "1-800-735-2258"
        case .peco: return nil
        case .comEd: return "1-800-955-8237"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var facebookURL: String {
        let appLink: String
        let webLink: String
        
        switch opco {
        case .bge:
            appLink = "fb://profile/114351251909317"
            webLink = "https://www.facebook.com/myBGE"
        case .peco:
            appLink = "fb://profile/57553362273"
            webLink = "https://www.facebook.com/pecoconnect"
        case .comEd:
            appLink = "fb://profile/114368811967421"
            webLink = "https://www.facebook.com/ComEd"
        case .pepco:
            appLink = "todo"
            webLink = "todo"
        case .ace:
            appLink = "todo"
            webLink = "todo"
        case .delmarva:
            appLink = "todo"
            webLink = "todo"
        }
        
        if let url = URL(string: appLink), UIApplication.shared.canOpenURL(url) {
            return appLink
        } else {
            return webLink
        }
    }
    
    var twitterURL: String {
        switch opco {
        case .bge: return "https://twitter.com/mybge"
        case .peco: return "https://twitter.com/pecoconnect"
        case .comEd: return "https://twitter.com/ComEd"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var youtubeURL: String {
        switch opco {
        case .bge: return "https://www.youtube.com/user/BaltimoreGasElectric"
        case .peco: return "https://www.youtube.com/pecoconnect"
        case .comEd: return "https://www.youtube.com/user/CommonwealthEdison/ComEd"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var linkedinURL: String {
        switch opco {
        case .bge: return "https://www.linkedin.com/company/5115"
        case .peco: return "https://www.linkedin.com/company-beta/4678"
        case .comEd: return "https://www.linkedin.com/company/comed"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var instagramURL: String? {
        switch opco {
        case .bge: return nil
        case .peco: return nil
        case .comEd: return "https://www.instagram.com/ComEd/"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var pinterestURL: String? {
        switch opco {
        case .bge: return nil
        case .peco: return nil
        case .comEd: return "https://www.pinterest.com/comedil/"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var flickrURL: String {
        switch opco {
        case .bge: return "https://www.flickr.com/photos/mybge"
        case .peco: return "https://www.flickr.com/pecoconnect"
        case .comEd: return "https://www.flickr.com/photos/commonwealthedison"
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    var buttonInfoList: [(urlString: String?, image: UIImage, accessibilityLabel: String, analyticParam: EventParameter.Value)] {
        switch opco {
        case .comEd:
            return [(facebookURL, #imageLiteral(resourceName: "ic_facebook"), "Facebook", .facebook),
                    (twitterURL, #imageLiteral(resourceName: "ic_twitter"), "Twitter", .twitter),
                    (youtubeURL, #imageLiteral(resourceName: "ic_youtube"), "YouTube", .youtube),
                    (linkedinURL, #imageLiteral(resourceName: "ic_linkedin"), "LinkedIn", .linkedin),
                    (instagramURL, #imageLiteral(resourceName: "ic_instagram"), "Instagram", .instagram),
                    (pinterestURL, #imageLiteral(resourceName: "ic_pinterest"), "Pinterest", .pinterest),
                    (flickrURL, #imageLiteral(resourceName: "ic_flickr"), "Flicker", .flickr)]
        case .bge, .peco:
            return [(facebookURL, #imageLiteral(resourceName: "ic_facebook"), "Facebook", .facebook),
                    (twitterURL, #imageLiteral(resourceName: "ic_twitter"), "Twitter", .twitter),
                    (youtubeURL, #imageLiteral(resourceName: "ic_youtube"), "YouTube", .youtube),
                    (linkedinURL, #imageLiteral(resourceName: "ic_linkedin"), "LinkedIn", .linkedin),
                    (flickrURL, #imageLiteral(resourceName: "ic_flickr"), "Flicker", .flickr)]
        case .pepco:
            return []
        case .ace:
            return []
        case .delmarva:
            return []
        }
    }
    
}
