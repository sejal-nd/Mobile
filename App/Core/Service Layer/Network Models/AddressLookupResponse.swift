//
//  AddressLookupResponse.swift
//  Mobile
//
//  Created by Mithlesh Kumar on 04/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

struct AddressLookupResponse: Decodable {
      var address: String
      var apartmentUnitNo: String?
      var city, compressedAddress: String
      var isMeterEnergized: Bool
      var premiseID, state: String
      var streetName, streetNumber: String?
      var zipCode: String
      var meterInfo: [MeterInfo]

      enum CodingKeys: String, CodingKey {
          case address = "Address"
          case apartmentUnitNo = "ApartmentUnitNo"
          case city = "City"
          case compressedAddress = "CompressedAddress"
          case isMeterEnergized = "IsMeterEnergized"
          case premiseID = "PremiseID"
          case state = "State"
          case streetName = "StreetName"
          case streetNumber = "StreetNumber"
          case zipCode = "ZipCode"
          case meterInfo
      }
    struct MeterInfo: Codable {
        var meterID, meterType: String // "ELEC" or "GAS"
        var isResidential: Bool
    }
}
extension AddressLookupResponse.MeterInfo: Equatable {
    static func == (lhs: AddressLookupResponse.MeterInfo, rhs: AddressLookupResponse.MeterInfo) -> Bool {
        return lhs.meterType == rhs.meterType
    }
}
