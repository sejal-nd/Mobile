//
//  AnyEncodable.swift
//  BGE
//
//  Created by Cody Dillon on 4/15/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

// An Encodable wrapper that allows us to encode any type that conforms to Encodable
struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        // allow the encoder to intercept a particular types encoding behavior (ex. URL)
        var container = encoder.singleValueContainer()
        try value.encode(to: &container)
    }
}

extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
    
    func data() -> Data {
        let encodable = AnyEncodable(value: self)
            
        do {
            let data = try JSONEncoder().encode(encodable)
            
            if ProcessInfo.processInfo.arguments.contains("-shouldLogAPI") {
                Log.info("Request Body:\n\(String(decoding: data, as: UTF8.self))")
            }
            return data
        } catch {
            fatalError("Error encoding object: \(error)")
        }
    }
    //Methods added to generate custom httpBody for token generation and refresh. Can be optimised further.
    func dictData() -> Data {
        let encodable = AnyEncodable(value: self)
            
        do {
            let data = try JSONEncoder().encode(encodable)
            if let postDict = convertStringToDictionary(text: String(decoding: data, as: UTF8.self)){
                let postString = getPostString(params: postDict)
                return postString.data(using: .utf8)!
            }
            if ProcessInfo.processInfo.arguments.contains("-shouldLogAPI") {
                Log.info("Request Body:\n\(String(decoding: data, as: UTF8.self))")
            }
            return data
        } catch {
            fatalError("Error encoding object: \(error)")
        }
    }
    
    private func getPostString(params:[String:Any]) -> String {
        var data = [String]()
        for(key, value) in params {
            data.append(key + "=\(value)")
        }
        return data.map { String($0) }.joined(separator: "&")
    }
    
    private func convertStringToDictionary(text: String) -> [String:String]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:String]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
}

// Codable protocol with a default value used with enums
protocol DefaultCaseCodable: Codable & CaseIterable & RawRepresentable
where RawValue: Decodable, AllCases: BidirectionalCollection { }

extension DefaultCaseCodable {
    init(from decoder: Decoder) throws {
        self = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? Self.allCases.last!
    }
}
