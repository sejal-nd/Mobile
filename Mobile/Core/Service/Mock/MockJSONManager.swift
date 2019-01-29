//
//  MockJSONManager.swift
//  Mobile
//
//  Created by Samuel Francis on 1/29/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

typealias JSON = [String: Any]

class MockJSONManager {
    
    static let shared = MockJSONManager()
    
    var loadedFilesCache = [File: JSON]()
    
    private init() {}
    
    func jsonObject(fromFile file: File, key: String) throws -> JSON {
        let json: JSON
        // Don't pull from the file if we already have the JSON in memory
        if let loadedJson = loadedFilesCache[file] {
            json = loadedJson
        } else {
            guard let url = Bundle.main.url(forResource: file.rawValue, withExtension: "json") else {
                throw ServiceError.parsing
            }
            
            do {
                let data = try Data(contentsOf: url)
                guard let jsonFromFile = try JSONSerialization.jsonObject(with: data) as? JSON else {
                    throw ServiceError.parsing
                }
                
                json = jsonFromFile
                loadedFilesCache[file] = jsonFromFile
            } catch let error as ServiceError {
                throw error
            } catch {
                throw ServiceError(cause: error)
            }
        }
        
        // Every JSON file should have a `default` object to fall back on
        guard let jsonObject = (json[key] ?? json[MockDataKey.default.rawValue]) as? JSON else {
            throw ServiceError.parsing
        }
        
        return jsonObject
    }
    
    func mappableObject<Value: Mappable>(fromFile file: File, key: String) throws -> Value {
        let json = try jsonObject(fromFile: file, key: key) as NSDictionary
        
        if let object = Value.from(json) {
            return object
        } else if let error = ServiceError.from(json) { // The JSON could include an error object
            throw error
        } else {
            throw ServiceError.parsing
        }
    }
    
    enum File: String {
        case accounts = "accounts"
        case accountDetails = "account_details"
    }
}
