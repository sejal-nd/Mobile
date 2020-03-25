//
//  ServiceLayer.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public struct ServiceLayer {
    
    public static func logJSON(router: Router, completion: @escaping (Result<String, Error>) -> ()) {
        // 2.
        var components = URLComponents()
        components.scheme = router.scheme
        components.host = router.host
        components.path = router.path
        components.queryItems = router.parameters
        
        // 3.
        guard let url = components.url else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = router.method
        
        // HTTP BODY
        if let httpBody = router.httpBody {
            urlRequest.httpBody = httpBody
        }
        
        // Add Headers
        ServiceLayer.addAdditionalHeaders(router.httpHeaders, request: &urlRequest)
        
        // 4.
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            // 5.
            guard error == nil else {
                completion(.failure(error!))
                print(error!.localizedDescription)
                return
            }
            guard response != nil else {
                return
            }
            guard let data = data else {
                return
            }
            
            guard let jsonString = String(data: data, encoding: String.Encoding.utf8) else { return } // the data will be converted to the string
            
            DispatchQueue.main.async {
                // 8.
                completion(.success(jsonString))
            }
        }
        dataTask.resume()
    }
    
    // 1.
    public static func request<T: Decodable>(router: Router, completion: @escaping (Result<T, Error>) -> ()) {
        print("Test: \(T.self)...\(NewSAMLToken.self)   \(T.self == NewSAMLToken.self)...\(router.token.isEmpty)")
        
        print("Logic test: \(router.apiAccess == .auth && router.token.isEmpty && T.self != NewSAMLToken.self && T.self != NewJWTToken.self)")
        
        // todo can we extract this logic into router?
        if router.apiAccess == .auth && router.token.isEmpty && T.self != NewSAMLToken.self && T.self != NewJWTToken.self { // || T.self == NewJWTToken.self
            // THROW ERROR LOG USER OUT, NO TOKEN FOR AUTH REQUEST.
            print("REQUEST BLOCKED ")
            return
        }
        
        // 2.
        var components = URLComponents()
        components.scheme = router.scheme
        components.host = router.host
        components.path = router.path
        components.queryItems = router.parameters
        
        // 3.
        guard let url = components.url else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = router.method
        
        // HTTP BODY
        if let httpBody = router.httpBody {
            urlRequest.httpBody = httpBody
        }
        
        // Add Headers
        ServiceLayer.addAdditionalHeaders(router.httpHeaders, request: &urlRequest)
        print("URL: \(url)")
        
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
            session = URLSession(configuration: .default)
        }
        
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            
            print("URL: \(url)")
            
            // 5.
            guard error == nil else {
                completion(.failure(error!))
                print(error!.localizedDescription)
                return
            }
                        
            // should only check if not AUT build
            guard response != nil || Environment.shared.environmentName == .aut else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            
            do {
                // 6.
                let responseObject = try jsonDecoder.decode(T.self, from: data)
                // 7.
                DispatchQueue.main.async {
                    // 8.
                    completion(.success(responseObject))
                }
            } catch let error {
                completion(.failure(error))
                print(error.localizedDescription)
            }
        }
        dataTask.resume()
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
