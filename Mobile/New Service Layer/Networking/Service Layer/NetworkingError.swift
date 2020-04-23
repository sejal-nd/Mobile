//
//  NetworkingError.swift
//  Mobile
//
//  Created by Joseph Erlandson on 4/23/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public enum NetworkingError: Error {
    case invalidToken
    case invalidURL
    case networkError
    case invalidResponse
    case invalidData
    case decodingError
    case encodingError
    case endpointError
}

// todo: below will be implemented for user facing messages.

//extension NewServiceError: LocalizedError {
//    var errorDescription: String? {
//        switch self {
//        case .tooShort:
//            return NSLocalizedString(
//                "Your username needs to be at least 4 characters long",
//                comment: ""
//            )
//        case .tooLong:
//            return NSLocalizedString(
//                "Your username can't be longer than 14 characters",
//                comment: ""
//            )
//        case .invalidCharacterFound(let character):
//            let format = NSLocalizedString(
//                "Your username can't contain the character '%@'",
//                comment: ""
//            )
//
//            return String(format: format, String(character))
//        }
//    }
//}
