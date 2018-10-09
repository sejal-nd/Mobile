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
            
            return URLSession.shared.rx.dataResponse(request: urlRequest)
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
