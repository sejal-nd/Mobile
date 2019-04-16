//
//  HomePrepaidCardViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 4/8/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

final class HomePrepaidCardViewModel {
    let isActive: Bool
    
    init(isActive: Bool) {
        self.isActive = isActive
    }
    
    var headerText: NSAttributedString {
        let text: String
        let font: UIFont
        if isActive {
            text = NSLocalizedString("You are currently enrolled in BGE Prepaid Power", comment: "")
            font = OpenSans.semibold.of(textStyle: .headline)
        } else {
            text = NSLocalizedString("Take action to complete your Prepaid enrollment", comment: "")
            font = OpenSans.regular.of(textStyle: .headline)
        }
        
        return NSAttributedString(string: text,
                                  attributes: [.foregroundColor: UIColor.blackText,
                                               .font: font])
    }
    
    var detailText: String {
        if isActive {
            return NSLocalizedString("As a BGE Prepaid Power pilot participant, you will have access to a personalized dashboard on the website to manage your Prepaid experience.", comment: "")
        } else {
            return NSLocalizedString("Complete all required steps within 5 business days of starting your enrollment.", comment: "")
        }
    }
    
    var buttonText: String {
        if isActive {
            return NSLocalizedString("Launch Dashboard", comment: "")
        } else {
            return NSLocalizedString("Continue Enrollment", comment: "")
        }
    }
    
    var buttonUrl: URL {
        return URL(string: Environment.shared.myAccountUrl)!
    }
}
