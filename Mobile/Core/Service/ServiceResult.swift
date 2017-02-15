//
//  ServiceResult.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

/// A representation of an error case at the service level.
enum ServiceError : Error {
    case JSONParsing
    case Custom(code: String, description: String)
    case Other(error: Error)
}

/// A representation of the result of a service request.
///
/// - Success: Indicates that the request successfully completed. The
///             resulting data is supplied.
/// - Failure: Indicates that the request failed. The underlying cause
///             of the failure is supplied with a ServiceError.
enum ServiceResult<T> {
    case Success(T)
    case Failure(ServiceError)
}
