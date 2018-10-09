//
//  MCSApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Reachability
import RxSwift

/// MCSApi is a wrapper around the URLSession networking APIs. It provides convenience methods
/// for executing POST/PUT/GET/DELETE custom endpoints, as well as authentication related APIs.
class MCSApi {

    static let shared = MCSApi()

    static let API_VERSION = "v3"
    private let TIMEOUT = 120.0

    // Pulled from MCSConfig.plist
    private let baseUrl: String
    private let mobileBackendId: String
    private let anonymousKey: String

    final private let TOKEN_KEYCHAIN_KEY = "kExelon_Token"
    private let tokenKeychain = A0SimpleKeychain()
    private var accessToken: String?

    private let session: URLSession

    private init() {
        guard
            let configPath = Bundle.main.path(forResource: "MCSConfig", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: configPath),
            let mobileBackends = dict["mobileBackends"] as? [String: Any],
            let mobileBackend = mobileBackends[Environment.shared.mcsInstanceName] as? [String: Any],
            let baseUrl = mobileBackend["baseURL"] as? String,
            let mobileBackendId = mobileBackend["mobileBackendID"] as? String,
            let anonymousKey = mobileBackend["anonymousKey"] as? String
        else {
            fatalError("MCSConfig.plist does not exist or is configured incorrectly")
        }

        self.baseUrl = baseUrl
        self.mobileBackendId = mobileBackendId
        self.anonymousKey = anonymousKey

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = TIMEOUT
        sessionConfig.timeoutIntervalForResource = TIMEOUT
        self.session = URLSession(configuration: sessionConfig)
    }

    /// Perform a GET on the specifid resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    ///   - completion: the block to execute on completion.
    func get(path: String) -> Observable<Any> {
        return call(path: path, method: .get)
    }


    /// Perform a POST on the specified resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    ///   - params: the body parameters to post
    ///   - completion: the block to execute on completion.
    func post(path: String, params: [String:Any]?) -> Observable<Any> {
        return call(path: path, params: params, method: .post)
    }


    /// Perform a PUT on the specified resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    ///   - params: the body parameters to post
    ///   - completion: the block to execute on completion.
    func put(path: String, params: [String:Any]?) -> Observable<Any> {
        return call(path: path, params: params, method: .put)
    }


    /// Perform a DELETE on the specified resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    ///   - params: the body parameters to send
    ///   - completion: the block to execute on completion.
    func delete(path: String, params: [String:Any]?) -> Observable<Any> {
        return call(path: path, params: params, method: .delete)
    }


    /// Exchange the specified token for an OAuth/MCS token.
    ///
    /// - Parameters:
    ///   - token: the token to exchange.
    ///   - completion: the block to execute on completion.
    func exchangeToken(_ token: String, storeToken: Bool = false) -> Observable<Void> {

        let reachability = Reachability()!
        let networkStatus = reachability.connection

        switch(networkStatus) {
        case .none:
            return .error(ServiceError(serviceCode: ServiceErrorCode.noNetworkConnection.rawValue))
        case .wifi, .cellular:
            let url = URL(string: "\(baseUrl)/mobile/platform/sso/exchange-token")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(mobileBackendId, forHTTPHeaderField: "oracle-mobile-backend-id")
            request.setValue("xml", forHTTPHeaderField: "encode")

            return session.rx.dataResponse(request: request)
                .map { data -> String in
                    guard let parsedData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                        let parsedJSON = parsedData as? [String: Any],
                        let token = parsedJSON["access_token"] as? String else {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    return token
                }
                .do(onNext: { [weak self] token in
                    guard let self = self else { return }
                        self.accessToken = token
                        if storeToken {
                            self.tokenKeychain.setString(token, forKey: self.TOKEN_KEYCHAIN_KEY)
                        }
                })
                .mapTo(())
                .observeOn(MainScheduler.instance)
        }
    }

    /// Log the user out.
    func logout() {
        tokenKeychain.deleteEntry(forKey: TOKEN_KEYCHAIN_KEY)
        accessToken = nil
    }

    func isAuthenticated() -> Bool {
        if accessToken == nil {
            accessToken = tokenKeychain.string(forKey: TOKEN_KEYCHAIN_KEY)
        }
        return accessToken != nil
    }

    /// Call a method on a specific resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource.
    ///   - params: the body parameters to supply.
    ///   - method: the method to apply (POST/PUT/GET/DELETE)
    ///   - completion: the block to execute on completion.
    func call(path: String, params: [String:Any]? = nil, method: HttpMethod) -> Observable<Any> {

        let networkStatus = Reachability()!.connection

        switch(networkStatus) {
        case .none:
            return .error(ServiceError(serviceCode: ServiceErrorCode.noNetworkConnection.rawValue))
        case .wifi, .cellular:
            // Build Request
            let url = URL(string: "\(baseUrl)/mobile/custom/\(path)")!
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue(mobileBackendId, forHTTPHeaderField: "oracle-mobile-backend-id")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if (isAuthenticated()) {
                request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
            } else {
                request.setValue("Basic \(anonymousKey)", forHTTPHeaderField: "Authorization")
            }

            // Logging
            let requestId = ShortUUIDGenerator.getUUID(length: 8)
            if let params = params, let jsonData = try? JSONSerialization.data(withJSONObject: params) {
                request.httpBody = jsonData
                let bodyString = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
                APILog("[\(requestId)][\(path)] \(method) REQUEST - BODY: \(bodyString)")
            } else {
                APILog("[\(requestId)][\(path)] \(method) REQUEST")
            }

            // Response
            return session.rx.fullResponse(request: request)
                .map { [weak self] (response: HTTPURLResponse, data: Data) -> Any in
                    let resBodyString = String(data: data, encoding: String.Encoding.utf8) ?? "No Response Data"
                    APILog("[\(requestId)][\(path)] \(method) RESPONSE - BODY:\n\(resBodyString)")
                    
                    if response.statusCode == 401 {
                        self?.logout()
                        NotificationCenter.default.post(name: .didReceiveInvalidAuthToken, object: self)
                        throw ServiceError()
                    } else {
                        do {
                            let parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                            let result = MCSResponseParser.parse(data: parsedData)
                            switch result {
                            case .success(let d):
                                return d
                            case .failure(let error):
                                if error.serviceCode == "TC-SYS-MAINTENANCE" {
                                    NotificationCenter.default.post(name: .didMaintenanceModeTurnOn, object: self)
                                }
                                throw error
                            }
                        } catch {
                            throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                        }
                    }
                }
                .observeOn(MainScheduler.instance)
        }
    }
}

fileprivate func APILog(_ message: String) {
    #if DEBUG
        NSLog("[MCSApi]\(message)")
    #endif
}

fileprivate struct ShortUUIDGenerator {
    private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    private static let maxBase : UInt32 = 62

    static func getUUID(withBase base: UInt32 = maxBase, length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(min(base, maxBase)))
            code.append(base62chars[random])
        }
        return code
    }
}
