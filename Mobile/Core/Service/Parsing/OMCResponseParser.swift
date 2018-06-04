//
//  OMCResponseParser.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

enum OMCResponseKey : String {
    case Success = "success"
    case Meta = "meta"
    case Code = "code"
    case Description = "description"
    case Offset = "offset"
    case Count = "count"
    case Total = "total"
    case Data = "data"
}

class OMCResponseParser : NSObject {
    
    static func parse(data: Any?, error: Error?, response: HTTPURLResponse?) -> ServiceResult<Any> {
        
        var result: ServiceResult<Any>
        
        //There are 4 scenerios here.
        //1. We have no error, and data that can be parsed.
        //2. We have no error, and the data is not parsable.
        //3. We have no error, and do NOT have data to parse (unexpected type).
        //4. We have an error.
        
        if data != nil {
            if let d = data as? [String: Any] {
                result = parseData(data: d) //1.
            } else {
                result = ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)) //2.
            }
        } else if error != nil {
            result = ServiceResult.failure(ServiceError(cause: error!)) //4.
        } else {
            result = ServiceResult.failure(ServiceError())
        }
        
        return result
    }
    
    /// Function to interpret the data or response body of a response.
    ///
    /// - Parameter data: JSON containing the response body data
    /// - Returns: a ServiceResult that represents the provided data
    private static func parseData(data: [String:Any]) -> ServiceResult<Any> {
        
        if let success = data[OMCResponseKey.Success.rawValue] as? Bool {
            if success {
                if let returnData = data[OMCResponseKey.Data.rawValue] as? [String: Any] { // Dictionary
                    return ServiceResult.success(returnData)
                } else if let returnData = data[OMCResponseKey.Data.rawValue] as? [[String: Any]] { // Array of Dictionaries
                    return ServiceResult.success(returnData)
                } else if let returnData = data[OMCResponseKey.Data.rawValue] as? [String] { // Array of Strings
                    return ServiceResult.success(returnData)
                } else if let returnData = data[OMCResponseKey.Data.rawValue] as? String { //String
                    return ServiceResult.success(returnData)
                } else {
                    return ServiceResult.success([:])
                }
            } else {
                if let meta = data[OMCResponseKey.Meta.rawValue] as? [String:Any] {
                    return ServiceResult.failure(parseMetaError(meta:meta))
                } else {
                    return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue))
                }
            }
        } else {
            return ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue))
        }
    }
    
    /// Function to interpret the 'meta' value of a response as an Error.
    /// The meta should include a code, and optionally a description.
    ///
    /// - Parameter meta: the meta dictionary to parse. Must contain a code to properly
    ///
    /// - Returns: the ServiceError
    private static func parseMetaError(meta: [String:Any]) -> ServiceError {
        
        if let code = meta[OMCResponseKey.Code.rawValue] as? String {
            if let description = meta[OMCResponseKey.Description.rawValue] as? String {
                return ServiceError(serviceCode: code, serviceMessage: description)
            } else {
                return ServiceError(serviceCode: code)
            }
        } else {
            return ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
        }
    }
}
