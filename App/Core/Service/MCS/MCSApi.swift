//
//  MCSApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 4/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
#if os(iOS)
import Reachability
#endif
import RxSwift
#if !os(iOS)
import WatchKit
#endif

/// MCSApi is a wrapper around the URLSession networking APIs. It provides convenience methods
/// for executing POST/PUT/GET/DELETE custom endpoints, as well as authentication related APIs.
class MCSApi {

    static let shared = MCSApi()
    
    enum PathPrefix {
        case anon
        case auth
        case none
    }
    
    private let TIMEOUT = 120.0

    final private let TOKEN_KEYCHAIN_KEY = "kExelon_Token"
    #if os(iOS)
    private let tokenKeychain = A0SimpleKeychain()
    #elseif os(watchOS)
    private let tokenKeychain = KeychainManager.shared
    #endif
    public var accessToken: String?

    private let session: URLSession

    private init() {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = TIMEOUT
        sessionConfig.timeoutIntervalForResource = TIMEOUT
        
        
        #if os(iOS)
        let systemVersion = UIDevice.current.systemVersion
        #elseif os(watchOS)
        let systemVersion = WKInterfaceDevice.current().systemVersion
        #endif
        
        //[OPCO] Mobile App/[APP_VERSION].[BUILD_NUMBER] ([PLATFORM] [OS_VERSION]; [MANUFACTURER] [MODEL])
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            let userAgentString = "\(Environment.shared.opco.displayString) Mobile App/\(version).\(build) (iOS \(systemVersion); Apple \(modelIdentifier))"
            sessionConfig.httpAdditionalHeaders = [
                "User-Agent": userAgentString
            ]
        }
        
        self.session = URLSession(configuration: sessionConfig)
    }

    /// Perform a GET on the specifid resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    func get(pathPrefix: PathPrefix, path: String, logResponseBody: Bool = true) -> Observable<Any> {
        return call(pathPrefix: pathPrefix, path: path, method: .get, logResponseBody: logResponseBody)
    }


    /// Perform a POST on the specified resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    ///   - params: the body parameters to post
    func post(pathPrefix: PathPrefix, path: String, params: [String:Any]?, logResponseBody: Bool = true) -> Observable<Any> {
        return call(pathPrefix: pathPrefix, path: path, params: params, method: .post, logResponseBody: logResponseBody)
    }


    /// Perform a PUT on the specified resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    ///   - params: the body parameters to post
    func put(pathPrefix: PathPrefix, path: String, params: [String:Any]?, logResponseBody: Bool = true) -> Observable<Any> {
        return call(pathPrefix: pathPrefix, path: path, params: params, method: .put, logResponseBody: logResponseBody)
    }


    /// Perform a DELETE on the specified resource.
    ///
    /// - Parameters:
    ///   - path: the relative path of the resource
    ///   - params: the body parameters to send
    func delete(pathPrefix: PathPrefix, path: String, params: [String:Any]?, logResponseBody: Bool = true) -> Observable<Any> {
        return call(pathPrefix: pathPrefix, path: path, params: params, method: .delete, logResponseBody: logResponseBody)
    }

    /// Log the user out.
    func logout() {
        #if os(iOS)
        tokenKeychain.deleteEntry(forKey: TOKEN_KEYCHAIN_KEY)
        #elseif os(watchOS)
        tokenKeychain[TOKEN_KEYCHAIN_KEY] = nil
        #endif
        accessToken = nil
        UserDefaults.standard.set(nil, forKey: UserDefaultKeys.gameAccountNumber)
    }

    func isAuthenticated() -> Bool {
        if accessToken == nil {
            #if os(iOS)
            accessToken = tokenKeychain.string(forKey: TOKEN_KEYCHAIN_KEY)
            #elseif watchOS
            accessToken = tokenKeychain["authToken"]
            #endif
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
    func call(pathPrefix: PathPrefix, path: String, params: [String: Any]? = nil, method: HttpMethod, logResponseBody: Bool) -> Observable<Any> {
        
        let requestId = ShortUUIDGenerator.getUUID(length: 8)
        
        var fullPath: String
        switch pathPrefix {
        case .anon:
            let opCoString = Environment.shared.opco.rawValue.uppercased()
            fullPath = String(format: "anon/%@/%@", opCoString, path)
        case .auth:
            fullPath = String(format: "auth/%@", path)
        case .none:
            fullPath = path
        }
                
        #if os(iOS)
        let reachability = Reachability()!
        let networkStatus = reachability.connection
        
        switch(networkStatus) {
        case .none:
            let serviceError = ServiceError(serviceCode: ServiceErrorCode.noNetworkConnection.rawValue)
            APILog(MCSApi.self, requestId: requestId, path: fullPath, method: method, logType: .error, message: serviceError.errorDescription)
            return .error(serviceError)
        case .wifi, .cellular:
            return performCall(requestId: requestId, path: fullPath, params: params, method: method, logResponseBody: logResponseBody)
        }
        #elseif os(watchOS)
        accessToken = tokenKeychain["authToken"]
        
        return performCall(requestId: requestId, path: fullPath, params: params, method: method, logResponseBody: logResponseBody)
        #endif
    }
    
    private func performCall(requestId: String, path: String, params: [String: Any]? = nil, method: HttpMethod, logResponseBody: Bool) -> Observable<Any> {
        var requestBody: Data?
        var bodyString: String?
        if let params = params, let jsonData = try? JSONSerialization.data(withJSONObject: params) {
            requestBody = jsonData
            bodyString = String(data: jsonData, encoding: .utf8) ?? ""
        }
        
        APILog(MCSApi.self, requestId: requestId, path: path, method: method, logType: .request, message: bodyString)
        
        // Build Request
        let url = URL(string: "\(Environment.shared.mcsConfig.baseUrl)\(Environment.shared.mcsConfig.projectEnvironmentPath)/mobile/custom/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if isAuthenticated() {
            request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Basic \(Environment.shared.mcsConfig.anonymousKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Response
        return session.rx.fullResponse(request: request, onCanceled: {
            APILog(MCSApi.self, requestId: requestId, path: path, method: method, logType: .canceled, message: nil)
        })
            .do(onError: { error in
                let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                APILog(MCSApi.self, requestId: requestId, path: path, method: method, logType: .error, message: serviceError.errorDescription)
            })
            .map { [weak self] (response: HTTPURLResponse, data: Data) -> Any in
                if response.statusCode == 401 && !path.contains("auth/game") {
                    APILog(MCSApi.self, requestId: requestId, path: path, method: method, logType: .error, message: logResponseBody ? String(data: data, encoding: .utf8) : nil)

                    self?.logout()
                    NotificationCenter.default.post(name: .didReceiveInvalidAuthToken, object: self)
                    throw ServiceError()
                }

                do {
                    let parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    let result = MCSResponseParser.parse(data: parsedData)
                    switch result {
                    case .success(let d):
                        APILog(MCSApi.self, requestId: requestId, path: path, method: method, logType: .response, message: logResponseBody ? String(data: data, encoding: .utf8) : nil)
                        return d
                    case .failure(let error):
                        if error.serviceCode == ServiceErrorCode.maintenanceMode.rawValue {
                            NotificationCenter.default.post(name: .didMaintenanceModeTurnOn, object: self)
                        }
                        
                        throw error
                    }
                } catch let error {
                    APILog(MCSApi.self, requestId: requestId, path: path, method: method, logType: .error, message: String(data: data, encoding: .utf8))
                    throw error as? ServiceError ?? ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
            }
            .observeOn(MainScheduler.instance)
    }
    
    func storeToken(_ token: String, storeToken: Bool = false) -> Observable<Void> {
        self.accessToken = token
        
        #if os(iOS)
        if let token = self.accessToken {
            try? WatchSessionManager.shared.updateApplicationContext(applicationContext: ["authToken" : token])
        }
        
        if storeToken {
            tokenKeychain.setString(token, forKey: TOKEN_KEYCHAIN_KEY)
        }
        #endif
        
        return Observable<Void>.just(Void())
    }

}

// Machine Identifier Reference: https://www.theiphonewiki.com/wiki/Models
fileprivate var modelIdentifier: String {
    if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
        return "\(simulatorModelIdentifier) [Simulator]"
    }
    var sysinfo = utsname()
    uname(&sysinfo)
    return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
}