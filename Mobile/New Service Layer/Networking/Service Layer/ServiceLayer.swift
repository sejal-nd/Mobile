//
//  ServiceLayer.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public struct ServiceLayer {
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
                
        // Set HTTP BODY
        if let httpBody = router.httpBody {
            urlRequest.httpBody = httpBody
        }
        
        // Add Headers
        ServiceLayer.addAdditionalHeaders(router.httpHeaders, request: &urlRequest)
        
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
            
            // Setup decoder
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            
            do {
                // Decode response
                let responseObject = try jsonDecoder.decode(T.self, from: data)
                
                // Validate successful response
                if let endpointError = responseObject as? EndpointErrorable,
                    let errorCode = endpointError.errorCode,
                    let errorMessage = endpointError.errorMessage {
                    // todo
                    
                    print("FN ERROR")
                    completion(.failure(.endpointError))
                    return
                }
                
                // Success
                DispatchQueue.main.async {
                    completion(.success(responseObject))
                }
            } catch {
                dLog("Failed to deocde network response:\n\n\(error)")
                completion(.failure(.decodingError))
            }
        }
        dataTask.resume()
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
