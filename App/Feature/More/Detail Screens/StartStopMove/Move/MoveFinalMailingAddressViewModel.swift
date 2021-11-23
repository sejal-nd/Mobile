//
//  MoveFinalMailingAddressViewModel.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 25/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class MoveFinalMailingAddressViewModel {

    var streetAddress: String?
    var city: String?
    var zipCode: String?
    var state: USState?
    var stateSelectedIndex = 0
    var isUnauth = false
    
    init(isUnauth: Bool = false) {
        self.isUnauth = isUnauth
    }

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
    
    var canEnableContinue: Bool {
        return isStreetAddressValid && isCityValid && isZipValid && stateSelectedIndex != 0
    }

    func setMailingData(_ flowData: MoveServiceFlowData) {

        self.streetAddress = flowData.mailingAddress?.streetAddress
        self.city = flowData.mailingAddress?.city
        self.state = flowData.mailingAddress?.state
        self.zipCode = flowData.mailingAddress?.zipCode
        self.stateSelectedIndex = flowData.mailingAddress?.stateSelectedIndex ?? 0
    }
}
