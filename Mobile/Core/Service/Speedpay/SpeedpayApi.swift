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
            
            var urlRequest = URLRequest(url: URL(string: Environment.shared.speedpayUrl)!)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params)
            
            return URLSession.shared.rx.data(request: urlRequest)
                .catchError {
                    let error = ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: $0)
                    if let speedpayError = SpeedpayErrorMapper.shared.getError(message: error.errorDescription ?? "", context: nil) {
                        throw ServiceError(serviceMessage: speedpayError.text)
                    } else {
                        if error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
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
