//
//  MockJSONManager.swift
//  Mobile
//
//  Created by Samuel Francis on 1/29/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation
import Mapper

typealias JSONObject = [String: Any]
typealias JSONArray = [Any]

final class MockJSONManager {
    
    static let shared = MockJSONManager()
    
    let bundle = Bundle(for: MockJSONManager.self)
    var loadedFilesCache = [File: JSONObject]()
    
    private init() {}
    
    private func jsonObject(fromFile file: File) throws -> JSONObject {
        // Don't pull from the file if we already have the JSON in memory
        if let loadedJson = loadedFilesCache[file] {
            return loadedJson
        } else {
            guard let filePath = bundle.path(forResource: file.rawValue, ofType: "json") else {
                throw ServiceError.parsing
            }
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
                guard let jsonFromFile = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
                    throw ServiceError.parsing
                }
                
                loadedFilesCache[file] = jsonFromFile
                return jsonFromFile
            } catch let error as ServiceError {
                throw error
            } catch {
                throw ServiceError(cause: error)
            }
        }
    }
    
    func jsonObject(fromFile file: File, key: MockDataKey) throws -> JSONObject {
        let json = try jsonObject(fromFile: file)
        
        // Every JSON file should have a `default` object to fall back on
        guard let jsonObject = (json[key.rawValue] ?? json[MockDataKey.default.rawValue]) as? JSONObject else {
            throw ServiceError.parsing
        }
        
        return jsonObject
    }
    
    func jsonArray(fromFile file: File, key: MockDataKey) throws -> JSONArray {
        let json = try jsonObject(fromFile: file)
        
        let object = json[key.rawValue] ?? json[MockDataKey.default.rawValue]
        
        // Every JSON file should have a `default` object to fall back on
        if let jsonArray = object as? JSONArray {
            return jsonArray
        } else if let jsonObject = object as? JSONObject {
            throw ServiceError.from(jsonObject as NSDictionary) ?? ServiceError.parsing
        } else {
            throw ServiceError.parsing
        }
        
    }
    
    func mappableObject<Value: Mappable>(fromFile file: File, key: MockDataKey) throws -> Value {
        let json = try jsonObject(fromFile: file, key: key) as NSDictionary
        
        if let object = Value.from(json) {
            return object
        } else if let error = ServiceError.from(json) { // The JSON could include an error object
            throw error
        } else {
            throw ServiceError.parsing
        }
    }
    
    func mappableArray<Value: Mappable>(fromFile file: File, key: MockDataKey) throws -> [Value] {
        let json = try jsonArray(fromFile: file, key: key) as NSArray
        
        if let array = Value.from(json) {
            return array
        } else {
            throw ServiceError.parsing
        }
    }
    
    enum File: String, CaseIterable {
        case accounts = "accounts"
        case accountDetails = "account_details"
        case billComparison = "bill_comparison"
        case billForecast = "bill_forecast"
        case payments = "payments"
        case maintenance = "maintenance"
        case outageStatus = "outage_status"
        case meterPingInfo = "meter_ping_info"
        case weather = "weather"
        case opcoUpdates = "opco_updates"
    }
}

import RxSwift

extension MockJSONManager: ReactiveCompatible {}

extension Reactive where Base: MockJSONManager {
    
    func jsonObject(fromFile file: MockJSONManager.File, key: MockDataKey) -> Observable<JSONObject> {
        do {
            let json = try base.jsonObject(fromFile: file, key: key)
            return .just(json)
        } catch {
            return .error(error)
        }
    }
    
    func jsonArray(fromFile file: MockJSONManager.File, key: MockDataKey) -> Observable<JSONArray> {
        do {
            let json = try base.jsonArray(fromFile: file, key: key)
            return .just(json)
        } catch {
            return .error(error)
        }
    }
    
    func mappableObject<Value: Mappable>(fromFile file: MockJSONManager.File, key: MockDataKey) -> Observable<Value> {
        do {
            let value: Value = try base.mappableObject(fromFile: file, key: key)
            return .just(value)
        } catch {
            return .error(error)
        }
    }
    
    func mappableArray<Value: Mappable>(fromFile file: MockJSONManager.File, key: MockDataKey) -> Observable<[Value]> {
        do {
            let values: [Value] = try base.mappableArray(fromFile: file, key: key)
            return .just(values)
        } catch {
            return .error(error)
        }
    }
}
