//
//  FinalMailingAddressViewModel.swift
//  EUMobile
//
//  Created by Salunke, Swapnil Uday on 22/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

public struct MailingAddress {
    let streetAddress: String
    let City: String
    let State: String
    let ZipCode: String
}

class FinalMailingAddressViewModel {
    let currentMailingAddress: MailingAddress?
    let isShownFromReviewScreen: Bool
    
    var shouldPopulateMailingScreen: Bool {
        return currentMailingAddress != nil && isShownFromReviewScreen
    }
    
    init(mailingAddress: MailingAddress?, isLaunchedFromReviewScreen: Bool) {
        currentMailingAddress = mailingAddress
        isShownFromReviewScreen = isLaunchedFromReviewScreen
    }
}
