//
//  PaymentArrangement.swift
//  Mobile
//
//  Created by Adarsh Maurya on 21/07/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct PaymentArrangement: Decodable {
    let customerInfo: CustomerInfoModel?
    let pAData: [PaDataModel]?
    
    enum CodingKeys: String, CodingKey {
        case customerInfo = "customerInfo"
        case pAData = "PAData"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        customerInfo = (try container.decodeIfPresent(CustomerInfoModel.self, forKey: .customerInfo))
        pAData = (try container.decodeIfPresent([PaDataModel].self, forKey: .pAData))
    }
}

struct CustomerInfoModel: Decodable {
    let paEligibility: String?
    let hasPABilled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case paEligibility = "PAEligibility"
        case hasPABilled = "hasPABilled"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paEligibility = (try container.decodeIfPresent(String.self, forKey: .paEligibility))
        hasPABilled = (try container.decodeIfPresent(Bool.self, forKey: .hasPABilled))
    }
}

struct PaDataModel: Decodable {
    let monthlyInstallment: String?
    let remainingPaymentAmount: String?
    let numberOfInstallments: String?
    let finalInstallmentAmount: String?
    let noOfInstallmentsLeft: String?
    
    enum CodingKeys: String, CodingKey {
        case monthlyInstallment = "monthlyInstallment"
        case remainingPaymentAmount = "remainingPaymentAmount"
        case numberOfInstallments = "numberOfInstallments"
        case finalInstallmentAmount = "finalInstallmentAmount"
        case noOfInstallmentsLeft = "noOfInstallmentsLeft"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyInstallment = (try container.decodeIfPresent(String.self, forKey: .monthlyInstallment))
        remainingPaymentAmount = (try container.decodeIfPresent(String.self, forKey: .remainingPaymentAmount))
        numberOfInstallments = (try container.decodeIfPresent(String.self, forKey: .numberOfInstallments))
        finalInstallmentAmount = (try container.decodeIfPresent(String.self, forKey: .finalInstallmentAmount))
        noOfInstallmentsLeft = (try container.decodeIfPresent(String.self, forKey: .noOfInstallmentsLeft))
    }
}
