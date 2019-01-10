//
//  SpeedpayApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 7/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Foundation

struct WalletItemResult {
    let responseCode : Int
    let statusMessage : String
    let walletItemId : String
}

struct SpeedpayApi {
    func fetchTokenizedCardNumber(cardNumber: String) -> Observable<String> {
        do {
            let params: [String: Any] = ["DEBIT_ACCOUNT": cardNumber]
            
            let url = URL(string: Environment.shared.mcsConfig.speedpayUrl)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = try JSONSerialization.data(withJSONObject: params)
            request.httpBody = body
            
            let requestId = ShortUUIDGenerator.getUUID(length: 8)
            let bodyString = String(data: body, encoding: .utf8)
            APILog(SpeedpayApi.self, requestId: requestId, path: request.url?.absoluteString, method: .post, logType: .request, message: bodyString)
            
            return URLSession.shared.rx.dataResponse(request: request, onCanceled: {
                APILog(SpeedpayApi.self, requestId: requestId, path: request.url?.absoluteString, method: .post, logType: .canceled, message: nil)
            })
                .do(onError: { error in
                    let serviceError = error as? ServiceError ?? ServiceError(cause: error)
                    APILog(SpeedpayApi.self, requestId: requestId, path: request.url?.absoluteString, method: .post, logType: .error, message: serviceError.errorDescription)
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
                        APILog(SpeedpayApi.self, requestId: requestId, path: request.url?.absoluteString, method: .post, logType: .error, message: String(data: data, encoding: .utf8))
                        throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                    }
                    
                    APILog(SpeedpayApi.self, requestId: requestId, path: request.url?.absoluteString, method: .post, logType: .response, message: String(data: data, encoding: .utf8))
                    return responseString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        } catch {
            return .error(ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue, cause: error))
        }
    }
}
