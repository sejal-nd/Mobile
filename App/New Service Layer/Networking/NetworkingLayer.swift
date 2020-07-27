//
//  ServiceLayer.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public enum NetworkingLayer {
    public static func request<T: Decodable>(router: Router,
                                             completion: @escaping (Result<T, NetworkingError>) -> ()) {
        // Ensure token exists for auth requests
        if router.apiAccess == .auth && router.token.isEmpty {
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
        print("URL: \(url.absoluteString)")
        // Set HTTP BODY
        if let httpBody = router.httpBody {
            urlRequest.httpBody = httpBody
        }
        
        // Add Headers
        NetworkingLayer.addHTTPHeaders(router.httpHeaders, request: &urlRequest)
        
        // Configure URL Session (Mock or regular)
        let session: URLSession
        if Environment.shared.environmentName == .aut {
            // Mock
            let username = UserSession.token
            let mockUser = NewMockDataKey(rawValue: username) ?? .default
            
            let configuration = URLProtocolMock.createMockURLConfiguration(path: url.absoluteString,
                                                                           mockDataFileName: router.mockFileName,
                                                                           mockUser: mockUser)
            session = URLSession(configuration: configuration)
        } else {
            // Regular
            session = URLSession.default
        }
        
        var retryCount = 3
        
        // todo this may create an infinite loop
        
        // Check refresh token
        if router.apiAccess == .auth && UserSession.isTokenExpired && retryCount != 0 && Environment.shared.environmentName != .aut {
            // token expired
            print("token expired")

            // Decrease retry counter
            retryCount -= 1
            
            // Refresh Token
            let refreshTokenRequest = RefreshTokenRequest(clientId: Environment.shared.mcsConfig.clientID,
                                                          clientSecret: Environment.shared.mcsConfig.clientSecret,
                                                          refreshToken: UserSession.refreshToken)
            
            NetworkingLayer.request(router: .refreshToken(request: refreshTokenRequest)) { (result: Result<TokenResponse, NetworkingError>) in
                switch result {
                case .success(let tokenResponse):
                    do {
                        // Create new user session
                        try UserSession.createSession(tokenResponse: tokenResponse)
                        
                        // Perform initial request
                        NetworkingLayer.dataTask(session: session,
                                                 urlRequest: urlRequest,
                                                 completion: completion)
                    } catch {
                        // Delete user session
                        UserSession.deleteSession()
                        completion(.failure(.invalidToken))
                    }
                case .failure(let error):
                    // Delete user session
                    UserSession.deleteSession()
                    completion(.failure(error))
                }
            }
        } else if router.apiAccess == .auth && UserSession.isRefreshTokenExpired && Environment.shared.environmentName != .aut {
            // refresh expired
            print("refresh token expired ")
            
            // Delete user session
            UserSession.deleteSession()
            completion(.failure(.invalidToken))
        } else {
            print("TOKEN ELSE")
            
            // Perform initial request
            NetworkingLayer.dataTask(session: session,
                                     urlRequest: urlRequest,
                                     completion: completion)
        }
    }
    
    private static func dataTask<T: Decodable>(session: URLSession,
                                               urlRequest: URLRequest,
                                               completion: @escaping (Result<T, NetworkingError>) -> ()) {
        // Perform Data Task
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error as NSError? {
                print("ERRROR: \(error)")
                print("Error2: \(error.localizedDescription)")
                if error.domain == NSURLErrorDomain,
                    error.code == NSURLErrorNotConnectedToInternet {
                    DispatchQueue.main.async {
                        completion(.failure(.noNetwork))
                    }
                }
                
                dLog(error.localizedDescription)
                DispatchQueue.main.async {
                    completion(.failure(.generic))
                }
                return
            }
            
            // Validate response if not using mock
            guard response != nil || Environment.shared.environmentName == .aut else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidData))
                }
                return
            }
            
            // Log payload
            if let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                if let methodStr = urlRequest.httpMethod,
                    let method = HttpMethod(rawValue: methodStr) {
                    APILog(String.self, requestId: "Test", path: "Test", method: method, logType: .request, message: jsonString)
                }
                else {
                    dLog("Network Payload:\n\n\(jsonString)")
                }
            }
            
            do {
                let responseObject: T = try decode(data: data)
                
                // Success
                DispatchQueue.main.async {
                    completion(.success(responseObject))
                }
            } catch {
                dLog("Failed to deocde network response for \(urlRequest):\n\n\(error)")
                DispatchQueue.main.async {
                    if let networkError = error as? NetworkingError {
                        completion(.failure(networkError))
                    } else {
                        completion(.failure(.decoding))
                    }
                }
            }
        }
        dataTask.resume()
    }

    private static func decode<T: Decodable>(data: Data) throws -> T {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom() { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            print("Test 199")
            return try DateParser().extractDate(object: dateStr)
        }

         if let responseWrapper = try? jsonDecoder.decode(ApigeeResponseContainer.self, from: data) {
            // Azure decode
            
            if let endpointError = responseWrapper.error {
                throw NetworkingError(errorCode: endpointError.code)
            }
            
            guard let responseData = responseWrapper.data else {
                throw NetworkingError.decoding
            }
            
            if let response = try? jsonDecoder.decode(T.self, from: responseData) {
                // Default decode
                print("response decoded")
                return response
            }
            
            print("throw container response")
            throw NetworkingError.decoding
        } else if (try? jsonDecoder.decode(ApigeeError.self, from: data)) != nil {
            // Apigee decode
            print("throw apigee response")
            throw NetworkingError.invalidToken
        } else if let response = try? jsonDecoder.decode(T.self, from: data) {
            // Default decode
            
            print("return default response")
            return response
        } else {
            print("throw decoding response")
            throw NetworkingError.decoding
        }
    }
    
    public static func cancelAllTasks() {
        URLSession.default.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        dLog("Cancelled all URL Session requests.")
    }
    
    private static func addHTTPHeaders(_ httpHeaders: HTTPHeaders,
                                             request: inout URLRequest) {
        guard !httpHeaders.isEmpty else { return }
        for (key, value) in httpHeaders {
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
