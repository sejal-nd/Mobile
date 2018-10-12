//
//  SpeedpayApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 7/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Foundation

struct SpeedpayApi {
    func fetchTokenizedCardNumber(cardNumber: String) -> Observable<String> {
        do {
            let params: [String: Any] = ["DEBIT_ACCOUNT": cardNumber]
            
            let url = URL(string: Environment.shared.speedpayUrl)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = try JSONSerialization.data(withJSONObject: params)
            request.httpBody = body
            
            // Logging
            let requestId = ShortUUIDGenerator.getUUID(length: 8)
            let bodyString = String(data: body, encoding: .utf8) ?? ""
            let logMessage = "REQUEST - BODY: \(bodyString)"
            let path = String(url.absoluteString.suffix(from: Environment.shared.speedpayUrl.endIndex))
            
            APILog(requestId: requestId, path: path, method: .post, message: logMessage)
            
            return URLSession.shared.rx.dataResponse(request: request)
                .do(onNext: { data in
                    let resBodyString = String(data: data, encoding: .utf8) ?? "No Response Data"
                    APILog(requestId: requestId, path: path, method: .post, message: "RESPONSE - BODY: \(resBodyString)")
                }, onError: { error in
                    let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                    APILog(requestId: requestId, path: path, method: .post, message: "ERROR - \(serviceError.errorDescription ?? "")")
                })
                .catchError { error in
                    let serviceError = error as? ServiceError ?? ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: error)
                    if let speedpayError = SpeedpayErrorMapper.shared.getError(message: serviceError.errorDescription ?? "", context: nil) {
                        throw ServiceError(serviceMessage: speedpayError.text)
                    } else {
                        if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                            throw error
                        } else {
                            throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)
                        }
                    }
                }
                .map { data -> String in
                    guard let responseString = String(data: data, encoding: .utf8) else {
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    return responseString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        } catch {
            return .error(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue, cause: error))
        }
    }
}

// MARK: - Logging

fileprivate func APILog(requestId: String, path: String, method: HttpMethod, message: String) {
    #if DEBUG
        NSLog("[SpeedpayApi][%@][%@] %@ %@", requestId, path, method.rawValue, message)
    #endif
}
