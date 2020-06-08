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
        case .pepco, .ace:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let opcoTitle = opco.displayString
            let localizedString = String(format: NSLocalizedString("If you see a downed power line, %@ and then call %@. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString, opcoTitle)
            emergencyAttrString = NSMutableAttributedString(string: localizedString)
            emergencyAttrString.addAttribute(.font, value: OpenSans.boldItalic.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        case .delmarva:
            let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
            let localizedString = String(format: NSLocalizedString("If you see a downed power line or smell natural gas, %@ and then call Delmarva. Representatives are available 24 hours a day, 7 days a week.", comment: ""), leaveAreaString)
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
    var delmarvaGasNumber: String {
        return "302-454-0317"
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
            urlString = "https://secure.pepco.com/MyAccount/CustomerSupport/Pages/ContactUsForms.aspx"
        case .ace:
            urlString = "https://secure.atlanticcityelectric.com/MyAccount/CustomerSupport/Pages/ContactUsForms.aspx"
        case .delmarva:
            urlString = "https://secure.delmarva.com/MyAccount/CustomerSupport/Pages/ContactUsForms.aspx"
        }
        
        return URL(string: urlString)!
    }
    
    var contactServiceTimings: String {
        switch opco {
        case .ace, .bge, .comEd, .peco, .delmarva:
            return "M-F 7AM to 7PM"
        case .pepco:
            return "M-F 7AM to 8PM"
        }
    }
    
    var label1: String {
        switch opco {
        case .bge: return NSLocalizedString("Residential", comment: "")
        case .peco: return NSLocalizedString("All Customers", comment: "")
        case .comEd: return NSLocalizedString("Residential", comment: "")
        case .ace, .delmarva ,.pepco: return NSLocalizedString("All Customers", comment: "")
        }
    }
    
    var label2: String? {
        switch opco {
        case .bge: return NSLocalizedString("Business", comment: "")
        case .comEd: return NSLocalizedString("Business", comment: "")
        case .peco: return  nil
        case .pepco: return nil
        case .ace: return nil
        case .delmarva: return nil
        }
    }
    
    var label3: String? {
        switch opco {
        case .bge: return NSLocalizedString("TTY/TTD", comment: "")
        case .comEd: return NSLocalizedString("Spanish", comment: "")
        case .peco: return nil
        case .pepco: return nil
        case .ace: return nil
        case .delmarva: return nil
        }
    }
    
    var phoneNumber1: String? {
        switch opco {
        case .bge: return nil
        case .peco: return "1-800-841-4141"
        case .comEd: return "1-800-334-7661"
        case .pepco: return "1-877-737-2662"
        case .ace: return "1-800-833-7476"
        case .delmarva: return "1-800-898-8042"
        }
    }
    
    var phoneNumber2: String? {
        switch opco {
        case .bge: return "1-800-685-0123"
        case .peco: return "1-800-494-4000"
        case .comEd: return "1-800-334-7661"
        case .pepco: return "202-833-7500"
        case .ace: return "1-800-642-3780"
        case .delmarva: return "1-800-375-7117"
        }
    }
    
    var phoneNumber3: String? {
        switch opco {
        case .bge: return "1-800-265-6177"
        case .peco: return nil
        case .comEd: return "1-877-426-6331"
        case .pepco: return nil
        case .ace: return nil
        case .delmarva: return nil
        }
    }
    
    var phoneNumber4: String? {
        switch opco {
        case .bge: return "1-800-735-2258"
        case .peco: return nil
        case .comEd: return "1-800-955-8237"
        case .pepco: return nil
        case .ace: return nil
        case .delmarva: return nil
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
            appLink = "fb://profile/204880427309"
            webLink = "https://www.facebook.com/PepcoConnect/"
        case .ace:
            appLink = "fb://profile/161778507233599"
            webLink = "https://www.facebook.com/AtlanticCityElectric/"
        case .delmarva:
            appLink = "fb://profile/214492525252095"
            webLink = "https://www.facebook.com/DelmarvaPower/"
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
        case .pepco: return "https://twitter.com/PepcoConnect"
        case .ace: return "https://twitter.com/ACElecConnect"
        case .delmarva: return "https://twitter.com/DelmarvaConnect"
        }
    }
    
    var youtubeURL: String {
        switch opco {
        case .bge: return "https://www.youtube.com/user/BaltimoreGasElectric"
        case .peco: return "https://www.youtube.com/pecoconnect"
        case .comEd: return "https://www.youtube.com/user/CommonwealthEdison/ComEd"
        case .pepco: return "https://www.youtube.com/channel/UCniqwfISC4GJ4za-76_dsfQ"
        case .ace: return "https://www.youtube.com/channel/UCJTEhgLnOEBuryl6c6eR0kg"
        case .delmarva: return "https://www.youtube.com/channel/UC9Gad0-uzbXim8p1HyK4KDA"
        }
    }
    
    var linkedinURL: String {
        switch opco {
        case .bge: return "https://www.linkedin.com/company/5115"
        case .peco: return "https://www.linkedin.com/company-beta/4678"
        case .comEd: return "https://www.linkedin.com/company/comed"
        case .pepco: return ""
        case .ace: return ""
        case .delmarva: return ""
        }
    }
    
    var instagramURL: String? {
        switch opco {
        case .bge: return nil
        case .peco: return nil
        case .comEd: return "https://www.instagram.com/ComEd/"
        case .pepco: return "https://www.instagram.com/pepcoconnect/"
        case .ace: return nil
        case .delmarva: return nil
        }
    }
    
    var pinterestURL: String? {
        switch opco {
        case .bge: return nil
        case .peco: return nil
        case .comEd: return "https://www.pinterest.com/comedil/"
        case .pepco: return nil
        case .ace: return nil
        case .delmarva: return nil
        }
    }
    
    var flickrURL: String {
        switch opco {
        case .bge: return "https://www.flickr.com/photos/mybge"
        case .peco: return "https://www.flickr.com/pecoconnect"
        case .comEd: return "https://www.flickr.com/photos/commonwealthedison"
        case .pepco: return ""
        case .ace: return ""
        case .delmarva: return ""
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
            return [(facebookURL, #imageLiteral(resourceName: "ic_facebook"), "Facebook", .facebook),
                    (twitterURL, #imageLiteral(resourceName: "ic_twitter"), "Twitter", .twitter),
                    (youtubeURL, #imageLiteral(resourceName: "ic_youtube"), "YouTube", .youtube),
                    (instagramURL, #imageLiteral(resourceName: "ic_instagram"), "Instagram", .instagram)]
        case .ace, .delmarva:
            return [(facebookURL, #imageLiteral(resourceName: "ic_facebook"), "Facebook", .facebook),
                    (twitterURL, #imageLiteral(resourceName: "ic_twitter"), "Twitter", .twitter),
                    (youtubeURL, #imageLiteral(resourceName: "ic_youtube"), "YouTube", .youtube)]
        }
    }
    
}
