//
//  MoveServiceFlowData.swift
//  Mobile
//
//  Created by RAMAITHANI on 11/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct MoveServiceFlowData {
    let workDays: [WorkdaysResponse.WorkDay]
    var stopServiceDate: Date
    let currentPremise: PremiseInfo
    let currentAccount: Account
    let currentAccountDetail: AccountDetail
    let verificationDetail: StopServiceVerificationResponse?
    var startServiceDate: Date?
    var isOwner: Bool = true
    var appartment_List: [AppartmentResponse]?
    var selected_appartment: AppartmentResponse?
    var selected_StreetAddress: String?
    var addressLookupResponse: [AddressLookupResponse]?
    var idVerification: IdVerification?
    var hasCurrentServiceAddressForBill: Bool
    var mailingAddress: MailingAddress?
}

struct IdVerification {
    
    var ssn: String?
    var dateOfBirth: Date?
    var employmentStatus: String?
    var driverLicenseNumber: String?
    var stateOfIssueDriverLincense: String?
}
