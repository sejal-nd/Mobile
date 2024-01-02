//
//  ContactViewModel.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 11/30/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import SwiftUI
import EUDesignSystem

extension ContactView {
    struct SocialMedia: Hashable {
        var id: UUID = UUID.init()
        var urlString: String
        var imageName: String
    }
    
    enum Contact {
        case phone(String)
        case socialMedia(SocialMedia)
        
        var url: URL? {
            let optionalURL: URL?
            switch self {
            case .phone(let phoneNumber):
                let cleanedPhoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
                optionalURL = URL(string: "tel:\(cleanedPhoneNumber)")
            case .socialMedia(let socialMedia):
                optionalURL = URL(string: socialMedia.urlString)
            }
            
            guard let optionalURL else { return nil }
            return optionalURL
        }
    }

    @MainActor class ViewModel: ObservableObject {
        let columns = [GridItem(.adaptive(minimum: 80))]
        var socialMediaLinks = [SocialMedia]()
        private let opco = Configuration.shared.opco
        
        init() {
            configureSocialMediaLinks()
        }
        
        
        // MARK: Public API
        
        func open(_ contact: Contact) {
            guard let url = contact.url else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        
        
        // MARK: Private API
        
        private func configureSocialMediaLinks() {
            if let facebookURL {
                socialMediaLinks.append(SocialMedia(urlString: facebookURL, imageName: "ic_facebook"))
            }
            
            if let xURL {
                socialMediaLinks.append(SocialMedia(urlString: xURL, imageName: "ic_twitter"))
            }
            
            if let youtubeURL {
                socialMediaLinks.append(SocialMedia(urlString: youtubeURL, imageName: "ic_youtube"))
            }
            
            if let linkedInURL {
                socialMediaLinks.append(SocialMedia(urlString: linkedInURL, imageName: "ic_linkedin"))
            }
            
            if let instagramURL {
                socialMediaLinks.append(SocialMedia(urlString: instagramURL, imageName: "ic_instagram"))
            }
            
            if let pinterestURL {
                socialMediaLinks.append(SocialMedia(urlString: pinterestURL, imageName: "ic_pinterest"))
            }
            
            if let flickrURL {
                socialMediaLinks.append(SocialMedia(urlString: flickrURL, imageName: "ic_flickr"))
            }
        }
        
        
        // MARK: Form URL
        
        var customerServiceAccessoryText: String {
            switch opco {
            case .ace, .bge, .comEd, .peco, .delmarva:
                return "M-F 7AM to 7PM"
            case .pepco:
                return "M-F 7AM to 8PM"
            }
        }
        
        
        // MARK: Phone Numbers
        
        var emergencyDetail: String {
            let baseString = "If you see downed power lines or smell natural gas, _**leave the area immediately**_ and then call \(opco.displayString). Representatives are available 24 hours a day, 7 days a week."
            
            let electricOnlyBaseString = "If you see downed power lines, _**leave the area immediately**_ and then call \(opco.displayString). Representatives are available 24 hours a day, 7 days a week."
            switch opco {
            case .bge, .comEd, .peco:
                return baseString
            case .ace, .delmarva, .pepco:
                return electricOnlyBaseString
            }
        }
        
        var emergencyURL: String? {
            switch opco {
            case .ace:
                return "1-800-833-7476"
            case .bge:
                return nil
            case .comEd:
                return "1-800-334-7661"
            case .delmarva:
                return "1-800-898-8042"
            case .peco:
                return nil
            case .pepco:
                return "1-877-737-2662"
            }
        }
        
        var gasEmergencyURL1: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "1-800-685-0123"
            case .comEd:
                return nil
            case .delmarva:
                return nil
            case .peco:
                return "1-800-841-4141"
            case .pepco:
                return nil
            }
        }
        
        var gasEmergencyURL2: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "1-877-778-7798"
            case .comEd:
                return nil
            case .delmarva:
                return nil
            case .peco:
                return "1-844-841-4151"
            case .pepco:
                return nil
            }
        }
        
        var electricalEmergencyURL1: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "1-800-685-0123"
            case .comEd:
                return nil
            case .delmarva:
                return nil
            case .peco:
                return "1-800-841-4141"
            case .pepco:
                return nil
            }
        }
        
        var electricalEmergencyURL2: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "1-877-778-2222"
            case .comEd:
                return nil
            case .delmarva:
                return nil
            case .peco:
                return nil
            case .pepco:
                return nil
            }
        }
        
        var formURL: URL {
            let urlString: String
            switch Configuration.shared.opco {
            case .bge:
                let isProd = Configuration.shared.environmentName == .release ||
                Configuration.shared.environmentName == .rc
                
                if isProd {
                    urlString = "https://bgeknowledge.custhelp.com/app/ContactUs"
                } else {
                    urlString = "https://bgeknowledge--elly-stag.custhelp.com/app/ContactUs"
                }
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
        
        var residentialTitle: String {
            switch opco {
            case .ace, .delmarva, .peco, .pepco:
                return "All Customers"
            case .bge, .comEd:
                return "Residential"
            }
        }
        
        var residentialURL: String? {
            switch opco {
            case .ace:
                return "1-800-642-3780"
            case .bge:
                return "1-800-685-0123"
            case .comEd:
                return "1-800-334-7661"
            case .delmarva:
                return "1-800-375-7117"
            case .peco:
                return "1-800-494-4000"
            case .pepco:
                return "202-833-7500"
            }
        }
        
        var businessTitle: String {
            switch opco {
            case .bge, .comEd:
                return "Business"
            case .ace, .delmarva, .peco, .pepco:
                return "" // Not shown in UI
            }
        }
        
        var businessURL: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "1-800-265-6177"
            case .comEd:
                return "1-877-426-6331"
            case .delmarva:
                return nil
            case .peco:
                return nil
            case .pepco:
                return nil
            }
        }
        
        var alternativeTitle: String {
            switch opco {
            case .bge:
                return "Business"
            case .comEd:
                return "Spanish"
            case .ace, .delmarva, .peco, .pepco:
                return "" // Not shown in UI
            }
        }
        
        var alternativeURL: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "1-800-735-2258"
            case .comEd:
                return "1-800-955-8237"
            case .delmarva:
                return nil
            case .peco:
                return nil
            case .pepco:
                return nil
            }
        }
        
        
        // MARK: Social Media
        
        private var facebookURL: String? {
            let appLink: String
            let webLink: String
            
            switch opco {
            case .ace:
                appLink = "fb://profile/161778507233599"
                webLink = "https://www.facebook.com/AtlanticCityElectric/"
            case .bge:
                appLink = "fb://profile/114351251909317"
                webLink = "https://www.facebook.com/myBGE"
            case .comEd:
                appLink = "fb://profile/114368811967421"
                webLink = "https://www.facebook.com/ComEd"
            case .delmarva:
                appLink = "fb://profile/214492525252095"
                webLink = "https://www.facebook.com/DelmarvaPower/"
            case .peco:
                appLink = "fb://profile/57553362273"
                webLink = "https://www.facebook.com/pecoconnect"
            case .pepco:
                appLink = "fb://profile/204880427309"
                webLink = "https://www.facebook.com/PepcoConnect/"
            }
            
            if let url = URL(string: appLink),
               UIApplication.shared.canOpenURL(url) {
                return appLink
            } else {
                return webLink
            }
        }
        
        private var xURL: String? {
            switch opco {
            case .ace:
                return "https://twitter.com/ACElecConnect"
            case .bge:
                return "https://twitter.com/mybge"
            case .comEd:
                return "https://twitter.com/ComEd"
            case .delmarva:
                return "https://twitter.com/DelmarvaConnect"
            case .peco:
                return "https://twitter.com/pecoconnect"
            case .pepco:
                return "https://twitter.com/PepcoConnect"
            }
        }
        
        private var youtubeURL: String? {
            switch opco {
            case .ace:
                return "https://www.youtube.com/channel/UCJTEhgLnOEBuryl6c6eR0kg"
            case .bge:
                return "https://www.youtube.com/user/BaltimoreGasElectric"
            case .comEd:
                return "https://www.youtube.com/user/CommonwealthEdison/ComEd"
            case .delmarva:
                return "https://www.youtube.com/channel/UC9Gad0-uzbXim8p1HyK4KDA"
            case .peco:
                return "https://www.youtube.com/pecoconnect"
            case .pepco:
                return "https://www.youtube.com/channel/UCniqwfISC4GJ4za-76_dsfQ"
            }
        }
        
        private var instagramURL: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return nil
            case .comEd:
                return "https://www.instagram.com/ComEd/"
            case .delmarva:
                return nil
            case .peco:
                return nil
            case .pepco:
                return "https://www.instagram.com/pepcoconnect/"
            }
        }
        
        private var linkedInURL: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "https://www.linkedin.com/company/5115"
            case .comEd:
                return "https://www.linkedin.com/company/comed"
            case .delmarva:
                return nil
            case .peco:
                return "https://www.linkedin.com/company-beta/4678"
            case .pepco:
                return nil
            }
        }
        
        private var pinterestURL: String? {
            switch opco {
            case .bge:
                return nil
            case .peco:
                return nil
            case .comEd:
                return "https://www.pinterest.com/comedil/"
            case .pepco:
                return nil
            case .ace:
                return nil
            case .delmarva:
                return nil
            }
        }
        
        private var flickrURL: String? {
            switch opco {
            case .ace:
                return nil
            case .bge:
                return "https://www.flickr.com/photos/mybge"
            case .comEd:
                return "https://www.flickr.com/photos/commonwealthedison"
            case .delmarva:
                return nil
            case .peco:
                return nil
            case .pepco:
                return nil
            }
        }
    }
}
