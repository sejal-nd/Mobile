//
//  ServiceResult.swift
//  Mobile
//
//  Created by Kenny Roethel on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

/// A representation of an error case at the service level.
/// ServiceErrors consist of a code and a message.
struct ServiceError {
    let code: Int
    let message: String
    
    
    /// Initialize a ServiceError
    ///
    /// - Parameters:
    ///   - errorCode: the error code.
    ///   - errorMessage: a message suitable to show the user.
    init(errorCode: Int, errorMessage: String) {
        code = errorCode;
        message = errorMessage;
    }
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
