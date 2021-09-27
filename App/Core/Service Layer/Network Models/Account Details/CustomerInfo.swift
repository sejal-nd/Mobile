//
//  CustomerInfo.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/26/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct CustomerInfo: Decodable {
    public var number: String
    public var name: String?
    public var firstName: String?
    public var lastName: String?
    public var nameCompressed: String?
    public var emailAddress: String?
    public var customerType: String?


    public var cellPhoneNumber: String?
    public var primaryPhoneNumber: String?

    
    enum CodingKeys: String, CodingKey {
        case customerInfo = "CustomerInfo"
        case number
        case name
        case firstName
        case lastName
        case nameCompressed
        case emailAddress
        case customerType
        
        case phoneInfo = "PhoneInfo"
        case cellPhoneNumber
        case primaryPhoneNumber
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.number = try container.decode(String.self,
                                           forKey: .number)
        self.name = try container.decodeIfPresent(String.self,
                                         forKey: .name)
        self.firstName = try container.decodeIfPresent(String.self,
                                              forKey: .firstName)
        self.lastName = try container.decodeIfPresent(String.self,
                                             forKey: .lastName)
        self.nameCompressed = try container.decodeIfPresent(String.self,
                                                   forKey: .nameCompressed)
        self.emailAddress = try container.decodeIfPresent(String.self,
                                                 forKey: .emailAddress)
        self.customerType = try container.decodeIfPresent(String.self,
                                                 forKey: .customerType)

        
        let phoneInfoContainer = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                               forKey: .phoneInfo)
        self.cellPhoneNumber = try phoneInfoContainer.decodeIfPresent(String.self,
                                                             forKey: .cellPhoneNumber)
        self.primaryPhoneNumber = try phoneInfoContainer.decodeIfPresent(String.self,
                                                                forKey: .primaryPhoneNumber)
        
    }
}
//
//"CustomerInfo": {
//    "number": "1014280000",
//    "name": "Sisson,Rodney Todd",
//    "firstName": "Rodney Todd",
//    "lastName": "Sisson",
//    "nameCompressed": "Rodney Todd Sisson",
//    "emailAddress": "1014280000@example.com",
//    "PhoneInfo": {
//        "cellPhoneNumber": "4936290876",
//        "primaryPhoneNumber": "4936290876"
//    }
//}
