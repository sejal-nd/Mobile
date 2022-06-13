//
//  MoveServiceConfirmationViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 22/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

class MoveServiceConfirmationViewModel {
    
    var moveServiceResponse: MoveServiceResponse!
    var isUnauth: Bool = false
    
    // Seamless Move
    var shouldShowSeamlessMove = false
    var transferEligibility: TransferEligibility = .ineligible
    var transferOption: TransferServiceOption = .transfer
    
    init(moveServiceResponse: MoveServiceResponse,
         isUnauth: Bool = false,
         shouldShowSeamlessMove: Bool = false,
         transferEligibility: TransferEligibility = .ineligible,
         transferOption: TransferServiceOption = .transfer) {
        self.moveServiceResponse = moveServiceResponse
        self.isUnauth = isUnauth
        self.transferEligibility = transferEligibility
        self.transferOption = transferOption
    }

    func getBillingDescription()-> String {
        
        return "The bill for service at your previous address will be delivered to"
    }
    
    func getBillingAddress()-> String {
        
        if let finalBillEmail = moveServiceResponse.finalBillEmail, !finalBillEmail.isEmpty, (moveServiceResponse.isEBillEnrollment ?? false) { return finalBillEmail }
        
        if let isResolved = moveServiceResponse.isResolved, isResolved {
            return "Your new service address"
        }
        
        if moveServiceResponse.useAltBillingAddress ?? false, let finalBillingAddress = moveServiceResponse.finalBillAddress {
            var address = ""
            if let streetName = finalBillingAddress.streetName {
                address += "\(streetName), "
            }
            address += "\(finalBillingAddress.city), "
            address += "\(finalBillingAddress.state) "
            address += "\(finalBillingAddress.zipCode)"
            return address
        }
        return "Your new service address"
    }
    
    func getStopServiceAddress()-> String {
        
        guard let streetName = moveServiceResponse.stopAddress?.streetName, let city = moveServiceResponse.stopAddress?.city, let state = moveServiceResponse.stopAddress?.state, let zipCode = moveServiceResponse.stopAddress?.zipCode else { return "" }
        return "\(streetName), \(city), \(state) \(zipCode)"
    }
    
    func getStartServiceAddress()-> String {
        
        var address = ""
        if let streetName = moveServiceResponse.startAddress?.streetName {
            address += "\(streetName), "
        }
        if let city = moveServiceResponse.startAddress?.city {
            address += "\(city), "
        }
        if let state = moveServiceResponse.startAddress?.state {
            address += "\(state) "
        }
        if let zipCode = moveServiceResponse.startAddress?.zipCode {
            address += "\(zipCode)"
        }
        return address
    }
}
