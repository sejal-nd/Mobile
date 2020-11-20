//
//  ServiceLayer.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import Foundation

public enum NetworkingLayer {
    
    static let refreshTokenDispatchGroup = DispatchGroup()
    static var isRefreshingToken = false
    
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
            dLog("Invalid URL: Request denied.")
            completion(.failure(.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = router.method

        if ProcessInfo.processInfo.arguments.contains("-shouldLogAPI") {
            dLog("\n\n\n📬 URL: \(url.absoluteString)")
        }
        
        // Set HTTP BODY
        if let httpBody = router.httpBody {
            urlRequest.httpBody = httpBody
            
            if ProcessInfo.processInfo.arguments.contains("-shouldLogAPI") {
                dLog("Request Body:\n\(String(decoding: httpBody, as: UTF8.self))")
            }
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
        
        // Check refresh token
        if router.apiAccess == .auth && UserSession.isRefreshTokenExpired && Environment.shared.environmentName != .aut {
            // Refresh expired
            dLog("❌ Refresh Token Expired... Logging user out...")
            
            // Log Out
            AuthenticationService.logout()
            completion(.failure(.invalidToken))
        }
        else if router.apiAccess == .auth && UserSession.isTokenExpired && retryCount != 0 && Environment.shared.environmentName != .aut {
            // token expired
            // Decrease retry counter
            retryCount -= 1
            
            refreshToken(router: router, completion: completion)
        } else {
            // Perform initial request
            NetworkingLayer.dataTask(session: session,
                                     urlRequest: urlRequest,
                                     completion: completion)
        }
    }
    
    private static func refreshToken<T: Decodable>(router: Router, completion: @escaping (Result<T, NetworkingError>) -> ()) {
        DispatchQueue.global(qos: .default).async {
            if isRefreshingToken {
                refreshTokenDispatchGroup.wait()
                DispatchQueue.main.async {
                    NetworkingLayer.request(router: router, completion: completion)
                }
                return
            }
            
            dLog("📬 Token expired... Refreshing...")
            
            isRefreshingToken = true
            refreshTokenDispatchGroup.enter()
            // Refresh Token
            let refreshTokenRequest = RefreshTokenRequest(clientId: Environment.shared.clientID,
                                                          clientSecret: Environment.shared.clientSecret,
                                                          refreshToken: UserSession.refreshToken)
            
            NetworkingLayer.request(router: .refreshToken(request: refreshTokenRequest)) { (result: Result<TokenResponse, NetworkingError>) in
                switch result {
                case .success(let tokenResponse):
                    do {
                        // Create new user session
                        try UserSession.createSession(tokenResponse: tokenResponse)
                        
                        // Perform initial request
                        DispatchQueue.main.async {
                            NetworkingLayer.request(router: router, completion: completion)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            // Delete user session
                            AuthenticationService.logout()
                            completion(.failure(.invalidToken))
                        }
                    }
                    
                    isRefreshingToken = false
                    refreshTokenDispatchGroup.leave()
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        // Delete user session
                        AuthenticationService.logout()
                        completion(.failure(error))
                    }
                    
                    isRefreshingToken = false
                    refreshTokenDispatchGroup.leave()
                }
            }
        }
    }
    
    private static func dataTask<T: Decodable>(session: URLSession,
                                               urlRequest: URLRequest,
                                               completion: @escaping (Result<T, NetworkingError>) -> ()) {
        // Perform Data Task
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error as NSError? {
                dLog("❌ Data task error: \(error)\n\n\(error.localizedDescription)")
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
                dLog("❌ Data task empty response.")
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }
            
            guard let data = data else {
                dLog("❌ Data task invalid data.")
                DispatchQueue.main.async {
                    completion(.failure(.invalidData))
                }
                return
            }

            do {
                dLog("\n\n\n\(LogType.response.symbol) RAW RESPONSE: \n\n\(String(data: data, encoding: .utf8) ?? "******* ERROR CONVERTING DATA TO STRING CHECK ENCODING ********")")
                
                let responseObject: T = try decode(data: data)
                
                // Success
                DispatchQueue.main.async {
                    completion(.success(responseObject))
                }
            } catch {
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
        if ProcessInfo.processInfo.arguments.contains("-shouldLogAPI") {
            dLog("📬 Data Response:\n\(String(decoding: data, as: UTF8.self))")
        }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom() { decoder throws -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            guard let date = dateString.extractDate() else {
                throw NetworkingError.decoding
            }
            
            return date
        }
        
        let responseWrapper: AzureResponseContainer<T>
        do {
            responseWrapper = try jsonDecoder.decode(AzureResponseContainer<T>.self, from: data)
        } catch {
            if let apigeeError = try? jsonDecoder.decode(ApigeeError.self, from: data) {
                // Apigee decode
                dLog("❌ Apigee Error: \(apigeeError) \n\n\(apigeeError.errorDescription)")
                let networkError = NetworkingError(errorCode: apigeeError.errorCode)
                
                if networkError != .generic {
                    throw networkError
                } else {
                    throw NetworkingError.invalidToken
                }
            } else if let response = try? jsonDecoder.decode(T.self, from: data) {
                // Default decode
                return response
            } else {
                dLog("❌ Failed to decode network response: \(error)")
                dLog(error.localizedDescription)
                throw error
            }
        }
        
        if let endpointError = responseWrapper.error {
            dLog("❌ Endpoint Error:\n\nError Code: \(endpointError.code)\nAzure Context: \(endpointError.context ?? "")\nError Description: \(endpointError.description ?? "")")
            
            // Log user out
            if endpointError.code == "401" {
                AuthenticationService.logout()
            }
            
            throw NetworkingError(errorCode: endpointError.code)
        }
        
        guard let responseData = responseWrapper.data else {
            dLog("❌ Failed to decode network response data")
            throw NetworkingError.decoding
        }
                
        return responseData
    }
    
    public static func cancelAllTasks() {
        URLSession.default.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        dLog("🛑 Cancelled all URL Session requests.")
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
