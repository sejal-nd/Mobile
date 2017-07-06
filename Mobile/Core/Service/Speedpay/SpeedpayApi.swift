//
//  SpeedpayApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 7/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct SpeedpayApi {
    func fetchTokenizedCardNumber(cardNumber: String, completion: @escaping (_ result: ServiceResult<String>) -> Swift.Void) {
        do {
            let url = "https://sptest144aa.speedpay.com/api/token/GetToken"
            let params = ["DEBIT_ACCOUNT":cardNumber] as [String : Any]
            
            var urlRequest = URLRequest(url: URL(string: url)!)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let jsonData: NSData = try JSONSerialization.data(withJSONObject: params) as NSData
            
            urlRequest.httpBody = jsonData as Data
            
            URLSession.shared.dataTask(with:urlRequest, completionHandler: { (data:Data?, resp: URLResponse?, err: Error?) in
                if err != nil {
                    completion(ServiceResult.Failure(ServiceError.init(serviceCode: ServiceErrorCode.LocalError.rawValue, serviceMessage: nil, cause: err)))
                } else {
                    let responseString = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
                    let trimmed = responseString.trimmingCharacters(in: CharacterSet.init(charactersIn: "\""))
                    
                    completion(ServiceResult.Success(trimmed))
                }
            }).resume()      }
        catch let error as NSError {
            let serviceError = ServiceError(serviceCode: ServiceErrorCode.Parsing.rawValue, cause: error)
            completion(ServiceResult.Failure(serviceError))
        }
    }
}
