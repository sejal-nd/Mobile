//
//  ServiceLayer.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public struct NetworkingLayer {
    public static func request<T: Decodable>(router: Router,
                                             completion: @escaping (Result<T, NetworkingError>) -> ()) {
        // Ensure token exists for auth requests
        if router.apiAccess == .auth && router.token.isEmpty
            && T.self == NewSAMLToken.self
            && T.self == NewJWTToken.self {
            dLog("No token found: Request denied.")
            completion(.failure(.invalidToken))
            return
        }
        
        // Configure URL Request
        var components = URLComponents()
        components.scheme = router.scheme
        components.host = router.host
        components.path = router.path
        components.queryItems = router.parameters
        
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = router.method
        print("URL: \(url)")
        // Set HTTP BODY
        if let httpBody = router.httpBody {
            urlRequest.httpBody = httpBody
        }
        
        // Add Headers
        NetworkingLayer.addAdditionalHeaders(router.httpHeaders, request: &urlRequest)
        
        // Configure URL Session (Mock or regular)
        let session: URLSession
        if Environment.shared.environmentName == .aut {
            // Mock
            let username = UserSession.shared.token
            let mockUser = MockDataKey(rawValue: username) ?? .default
            
            let configuration = URLProtocolMock.createMockURLConfiguration(path: url.absoluteString,
                                                                           mockDataFileName: router.mockFileName,
                                                                           mockUser: mockUser)
            session = URLSession(configuration: configuration)
        } else {
            // Regular
            session = URLSession.shared
        }
        
        // Perform Data Task
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                dLog(error.localizedDescription)
                completion(.failure(.networkError))
                return
            }
            
            // Validate response if not using mock
            guard response != nil || Environment.shared.environmentName == .aut else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            // Log payload
            if let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                dLog("Network Payload:\n\n\(jsonString)")
            }
            
            do {
                let responseObject: T = try decode(data: data)
                
                // Success
                DispatchQueue.main.async {
                    completion(.success(responseObject))
                }
            } catch {
                dLog("Failed to deocde network response:\n\n\(error)")
                if let networkError = error as? NetworkingError {
                    completion(.failure(networkError))
                } else {
                    completion(.failure(.decodingError))
                }
            }
        }
        dataTask.resume()
    }
    
    public static func decode<T: Decodable>(data: Data) throws -> T {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        
        let responseWrapper = try jsonDecoder.decode(NewResponseWrapper<T>.self, from: data)
        
        // check for endpoint error
        if let endpointError = responseWrapper.error {
            throw NetworkingError.endpointError(endpointError)
        }
        
        guard let data = responseWrapper.data else {
            throw NetworkingError.decodingError
        }
        
        return data
    }
    
    public static func cancelAllTasks() {
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        dLog("Cancelled all URL Session requests.")
    }
    
    private static func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?,
                                             request: inout URLRequest) {
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
        return formatter
    }()
}
