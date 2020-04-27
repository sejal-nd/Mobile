//
//  ServiceLayer.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public struct ServiceLayer {

    public static func request<T: Decodable>(router: Router, completion: @escaping (Result<T, NetworkingError>) -> ()) {
        print("Test: \(T.self)...\(NewSAMLToken.self)   \(T.self == NewSAMLToken.self)...\(router.token.isEmpty)")
        
        print("Logic test: \(router.apiAccess == .auth && router.token.isEmpty && T.self != NewSAMLToken.self && T.self != NewJWTToken.self)")
        
        // todo can we extract this logic into router?
        if router.apiAccess == .auth && router.token.isEmpty && T.self == NewSAMLToken.self && T.self == NewJWTToken.self { // || T.self == NewJWTToken.self
            // THROW ERROR LOG USER OUT, NO TOKEN FOR AUTH REQUEST.
            print("REQUEST BLOCKED ")
            completion(.failure(.invalidToken))
            
            return
        }
        
        // 2.
        var components = URLComponents()
        components.scheme = router.scheme
        components.host = router.host
        components.path = router.path
        components.queryItems = router.parameters
        print("....1")
        // 3.
        guard let url = components.url else { print("FAIL URL");completion(.failure(.invalidURL));return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = router.method
        
        print("....2")
        
        // HTTP BODY
        if let httpBody = router.httpBody {
            print("body: \(httpBody)")
            urlRequest.httpBody = httpBody
        }
        
        // Add Headers
        ServiceLayer.addAdditionalHeaders(router.httpHeaders, request: &urlRequest)
        print("NEW URL: \(url)")
        
        // 4.
        let session: URLSession
        if Environment.shared.environmentName == .aut {
            print("MOCK SESSION REQ")
            
            let username = UserSession.shared.token
            let mockUser = MockDataKey(rawValue: username) ?? .default
            
            let configuration = URLProtocolMock.createMockURLConfiguration(path: url.absoluteString,
                                                           mockDataFileName: router.mockFileName,
                                                           mockUser: mockUser)
            // UAT Build
            session = URLSession(configuration: configuration)
        } else {
            // Regular
            session = URLSession.shared
        }
                
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            
            print("DATA TASK URL: \(url)")
            
            // 5.
            if let error = error {
                print(error.localizedDescription)

                completion(.failure(.networkError))
                
                return
            }
                      print("....2")
            // should only check if not AUT build
            guard response != nil || Environment.shared.environmentName == .aut else {
                completion(.failure(.invalidResponse))
                
                return
            }
            print("....3")
            guard let data = data else {
                completion(.failure(.invalidData))
                
                return
            }
            
            // todo only on debug
            if let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                print("JSON Payload: \(jsonString)")
            }
            
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            
            do {
                // 6.
                let responseObject = try jsonDecoder.decode(T.self, from: data)
                
                if let endpointError = responseObject as? EndpointErrorable,
                    let errorCode = endpointError.errorCode,
                    let errorMessage = endpointError.errorMessage {
                    // todo
                    
                    print("FN ERROR")
                    completion(.failure(.endpointError(endpointError)))
                    
                    return
                }
                
                // 7.
                DispatchQueue.main.async {
                    // 8.
                    completion(.success(responseObject))
                }
            } catch let error {
                print(error.localizedDescription)
                
                completion(.failure(.decodingError))
            }
        }
        dataTask.resume()
    }
    
    public static func cancelAllTasks() {
        URLSession.shared.getAllTasks { tasks in
            tasks
                .forEach { $0.cancel() }
        }
        print("All URL Session Tasks Cancelled.")
    }
    
    private static func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}

private extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        //    formatter.calendar = Calendar(identifier: .iso8601)
        //    formatter.timeZone = TimeZone(secondsFromGMT: 0)
        //    formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

public enum NetworkingError: Error {
    case invalidToken
    case invalidURL
    case networkError
    case invalidResponse
    case invalidData
    case decodingError
    case encodingError
    case endpointError(_: EndpointErrorable)
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
