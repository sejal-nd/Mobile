//
//  MockModel.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 31/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

class MockModel {

    static func getModel<T: Decodable>(mockDataFileName: String, mockUser: NewMockDataKey) -> T {
        guard let path = Bundle.main.path(forResource: mockDataFileName, ofType: "json") else {
            fatalError("Mock data not found for file named: \(mockDataFileName)")
        }

        var responseObject: T! = nil
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                fatalError("JSON format is incorrect for \(mockDataFileName)")
            }

            guard let nestedJSON = json[mockUser.rawValue] ?? json[NewMockDataKey.default.rawValue] else {
                fatalError("Mock user key \(mockUser.rawValue) not found in nested json for: \(mockDataFileName)")
            }

            let response = try JSONSerialization.data(withJSONObject: nestedJSON, options: .prettyPrinted)

            responseObject = try NetworkingLayer.decode(data: response)

        } catch let error {
            fatalError("Failed to parse mock json file into data: \(error)")
        }

        return responseObject
    }

}
