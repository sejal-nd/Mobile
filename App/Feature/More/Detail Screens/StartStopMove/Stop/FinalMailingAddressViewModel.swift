//
//  FinalMailingAddressViewModel.swift
//  EUMobile
//
//  Created by Salunke, Swapnil Uday on 22/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

public struct MailingAddress {
    let streetAddress: String
    let City: String
    let State: String
    let ZipCode: String
}

class FinalMailingAddressViewModel {
    
    var streetAddress: String?
    var city: String?
    var zipCode: String?
    var state: String?
    var stateSelectedIndex = 0
    
    var isStreetAddressValid: Bool {
        guard let address = streetAddress, !address.isEmpty else { return false}
        return true
    }
    
    var isCityValid: Bool {
        guard let city = city, !city.isEmpty else { return false}
        return true
    }
    
    var isZipValid: Bool {
        guard let zip = zipCode, !zip.isEmpty, zip.count == 5 else { return false}
        return true
    }
}
