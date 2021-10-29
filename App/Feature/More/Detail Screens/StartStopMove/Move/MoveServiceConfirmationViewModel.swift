//
//  MoveServiceConfirmationViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 22/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

class MoveServiceConfirmationViewModel {
    
    var isEbillUser = true
    var moveServiceResponse: MoveServiceResponse!
    
    init(moveServiceResponse: MoveServiceResponse) {
        
        self.moveServiceResponse = moveServiceResponse
    }

    func getBillingDescription()-> String {
        
        return "The bill for service at your previous address will be delivered to"
    }
    
    func getBillingAddress()-> String {
        
        if let finalBillEmail = moveServiceResponse.finalBillEmail, !finalBillEmail.isEmpty { return finalBillEmail }
        
        if let isResolved = moveServiceResponse.isResolved, isResolved || moveServiceResponse.finalBillAddress == nil {
            return "Your new service address"
        }
        
        if let finalBillingAddress = moveServiceResponse.finalBillAddress, let startServiceAddress = moveServiceResponse.startAddress {
            if (finalBillingAddress.streetName?.lowercased() == startServiceAddress.streetName?.lowercased() || finalBillingAddress.city.lowercased() == startServiceAddress.city.lowercased() || finalBillingAddress.state.lowercased() == startServiceAddress.state.lowercased() || finalBillingAddress.zipCode.lowercased() == startServiceAddress.zipCode.lowercased()) {
                return "Your new service address"
            }
        }

        var address = ""
        if let streetName = moveServiceResponse.startAddress?.streetName {
            address += "\(streetName), "
        }
        if let city = moveServiceResponse.stopAddress?.city {
            address += "\(city), "
        }
        if let state = moveServiceResponse.stopAddress?.state {
            address += "\(state) "
        }
        if let zipCode = moveServiceResponse.stopAddress?.zipCode {
            address += "\(zipCode)"
        }
        return address
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
        if let city = moveServiceResponse.stopAddress?.city {
            address += "\(city), "
        }
        if let state = moveServiceResponse.stopAddress?.state {
            address += "\(state) "
        }
        if let zipCode = moveServiceResponse.stopAddress?.zipCode {
            address += "\(zipCode)"
        }
        return address
    }
}
