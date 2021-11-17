//
//  StopConfirmationScreenViewModel.swift
//  EUMobile
//
//  Created by RAMAITHANI on 07/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

class StopConfirmationScreenViewModel {
    
    var stopServiceResponse: StopServiceResponse!
    
    init(stopServiceResponse: StopServiceResponse) {
        self.stopServiceResponse = stopServiceResponse
    }
    
    func getStopServiceDate()-> String {
        
        guard let stopDate = stopServiceResponse.stopDate else { return "" }
        return "\(stopDate), 8:00 a.m."
    }
    
    func getFinalBillAddress()-> String {
        
        if let finalBillEmail = stopServiceResponse.finalBillEmail, !finalBillEmail.isEmpty { return finalBillEmail }
        
        if let isResolved = stopServiceResponse.isResolved, isResolved && stopServiceResponse.finalBillAddress == nil {
            return "The service address above"
        }
        
        if let isResolved = stopServiceResponse.isResolved, !isResolved && stopServiceResponse.finalBillAddress == nil {
            return "Same as current service address"
        }
        
        if let finalBillingAddress = stopServiceResponse.finalBillAddress, let stopServiceAddress = stopServiceResponse.stopAddress {
            if (finalBillingAddress.streetName.lowercased() == stopServiceAddress.streetName.lowercased() && finalBillingAddress.streetName.lowercased() == stopServiceAddress.streetName.lowercased() && finalBillingAddress.streetName.lowercased() == stopServiceAddress.streetName.lowercased() && finalBillingAddress.streetName.lowercased() == stopServiceAddress.streetName.lowercased()) {
                return (stopServiceResponse.isResolved ?? false) ? "The service address above" : "Same as current service address"
            }
        }

        guard let streetName = stopServiceResponse.finalBillAddress?.streetName, let city = stopServiceResponse.finalBillAddress?.city, let state = stopServiceResponse.finalBillAddress?.state, let zipCode = stopServiceResponse.finalBillAddress?.zipCode else { return "" }
        return "\(streetName), \(city), \(state) \(zipCode)"
    }
    
    func getStopServiceAddress()-> String {
        
        guard let streetName = stopServiceResponse.stopAddress?.streetName, let city = stopServiceResponse.stopAddress?.city, let state = stopServiceResponse.stopAddress?.state, let zipCode = stopServiceResponse.stopAddress?.zipCode else { return "" }
        return "\(streetName), \(city), \(state) \(zipCode)"
    }
    
    func getNextStepDescription()-> String {
        
        return (stopServiceResponse.isResolved ?? false) ? "We will disconnect your service remotely through your smart meter. You will not need to be present. Please prepare for your service to be shut off as early as 8 a.m." : "We are currently processing your request. If we need more information to complete your request, we will contact you within 24-48 business hours."

    }
}
