//
//  FiservApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

private enum ResponseKey : String {
    case responseCode = "ResponseCode"
    case statusMessage = "StatusMessage"
    case walletItemId = "WalletItemID"
    case guid = "GUID"
    case hash = "Hash"
}

private enum MessageId : String {
    case insertCheck = "insertWalletCheck"
    case insertCredit = "insertWalletCard"
    case updateCredit = "updateWalletCard"
}

private enum Action : String {
    case insert = "OD_InsertWalletItem"
    case update = "OD_UpdateWalletItem"
}

private enum Parameter : String {
    case messageId = "MessageId"
    case walletItemId = "WalletItemID"
    case requestTimestamp = "RequestTimestamp"
    case appId = "AppId"
    case processingRegionCode = "ProcessingRegionCode"
    case billerId = "BillerId"
    case consumerId = "ConsumerId"
    case sessionToken = "AuthSessToken"
    case deviceProfile = "DeviceProfile"
    case userAgentString = "UserAgentString"
    case walletExternalId = "WalletExternalID"
    case oneTimeUse = "OneTimeUse"
    case isDefaultFunding = "IsDefaultFundingSource"
    case nickName = "NickName"
    
    case checkingDetail = "CheckingDetail"
    case cardDetail = "CardDetail"

    case cardNumber = "CardNumber"
    case expirationDate = "ExpirationDate"
    case securityCode = "SecurityCode"
    case postalCode = "ZipCode"
    
    case routingNumber = "RoutingNumber"
    case checkAccountNumber = "CheckAccountNumber"
    case firstName = "FirstName"
    case lastName = "LastName"
    case checkType = "CheckType"
}

struct WalletItemResult {
    let responseCode : Int
    let statusMessage : String
    let walletItemId : String
}

struct FiservApi {
    
    func addBankAccount(bankAccountNumber: String,
                        routingNumber: String,
                        firstName: String?,
                        lastName: String?,
                        nickname: String?,
                        token: String,
                        customerNumber: String,
                        checkingOrSavings: String?,
                        oneTimeUse: Bool) -> Observable<WalletItemResult> {
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: oneTimeUse)
        
        params[Parameter.messageId.rawValue] = MessageId.insertCheck.rawValue
        params[Parameter.checkingDetail.rawValue] = createBankAccountDetailDictionary(accountNumber: bankAccountNumber,
                                                                                      routingNumber: routingNumber,
                                                                                      firstName: firstName,
                                                                                      lastName: lastName,
                                                                                      checkingOrSavings: checkingOrSavings)
        
        return getTokensAndExecute(params: params, action: .insert)
    }
    
    func addCreditCard(cardNumber: String,
                       expirationMonth: String,
                       expirationYear: String,
                       securityCode: String,
                       postalCode: String,
                       nickname: String?,
                       token: String,
                       customerNumber: String,
                       oneTimeUse: Bool) -> Observable<WalletItemResult>  {
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: oneTimeUse)
        params[Parameter.messageId.rawValue] = MessageId.insertCredit.rawValue
        params[Parameter.cardDetail.rawValue] = createCardDetailDictionary(cardNumber: cardNumber,
                                                          expirationMonth: expirationMonth,
                                                          expirationYear: expirationYear,
                                                          securityCode: securityCode,
                                                          postalCode: postalCode)
        
        return getTokensAndExecute(params: params, action: .insert)
    }
    
    func updateCreditCard(walletItemID: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String,
                          token: String,
                          customerNumber: String) -> Observable<WalletItemResult> {
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nil, oneTimeUse: false)
        
        var cardDetail = [String: String]()

        let expiration = "" + expirationMonth + expirationYear[expirationYear.index(expirationYear.startIndex, offsetBy: 2)...]
        cardDetail[Parameter.expirationDate.rawValue] = expiration
        cardDetail[Parameter.securityCode.rawValue] = securityCode
        cardDetail[Parameter.postalCode.rawValue] = postalCode

        params[Parameter.messageId.rawValue] = MessageId.updateCredit.rawValue
        params[Parameter.cardDetail.rawValue] = cardDetail
        params[Parameter.walletItemId.rawValue] = walletItemID
        
        return getTokensAndExecute(params: params, action: .update)
    }
}


// MARK: - Create Params

fileprivate func createCardDetailDictionary(cardNumber: String?,
                                            expirationMonth: String,
                                            expirationYear: String,
                                            securityCode: String?,
                                            postalCode: String?) -> [String:Any] {
    let expiration = expirationMonth + expirationYear[expirationYear.index(expirationYear.startIndex, offsetBy: 2)...]
    var details = [Parameter.expirationDate.rawValue : expiration] as [String: Any]
    
    if !(cardNumber ?? "").isEmpty {
        details[Parameter.cardNumber.rawValue] = cardNumber
    }
    if !(securityCode ?? "").isEmpty {
        details[Parameter.securityCode.rawValue] = securityCode
    }
    if !(postalCode ?? "").isEmpty {
        details[Parameter.postalCode.rawValue] = postalCode
    }
    
    return details
}

fileprivate func createBankAccountDetailDictionary(accountNumber: String,
                                                   routingNumber: String,
                                                   firstName: String?,
                                                   lastName: String?,
                                                   checkingOrSavings: String?) -> [String:Any] {
    var details = [Parameter.routingNumber.rawValue : routingNumber,
                   Parameter.checkAccountNumber.rawValue : accountNumber] as [String : Any]
    
    if !(firstName ?? "").isEmpty {
        details[Parameter.firstName.rawValue] = firstName
    }
    if !(lastName ?? "").isEmpty {
        details[Parameter.lastName.rawValue] = lastName
    }
    
    var checkType = 0 // default to "checking"
    if checkingOrSavings == "saving" {
        checkType = 1
    }
    details[Parameter.checkType.rawValue] = checkType
    
    return details
}

fileprivate func createBaseParameters(token: String, customerNumber: String, nickname: String?, oneTimeUse: Bool) -> [String: Any] {
    let opCo = Environment.shared.opco
    let time = Int(Date().timeIntervalSince1970)
    let billerId = "\(opCo.rawValue)Registered"
    
    var params = [Parameter.requestTimestamp.rawValue: "/Date(" + String(time) + ")/",
                  Parameter.appId.rawValue: "FiservProxy",
                  Parameter.processingRegionCode.rawValue: Environment.shared.environmentName == .prod ? 5 : 2,
                  Parameter.billerId.rawValue: billerId,
                  Parameter.consumerId.rawValue: customerNumber,
                  Parameter.sessionToken.rawValue: token,
                  Parameter.deviceProfile.rawValue:[Parameter.userAgentString.rawValue: "MobileApp"],
                  Parameter.walletExternalId.rawValue: customerNumber,
                  Parameter.oneTimeUse.rawValue: oneTimeUse,
                  Parameter.isDefaultFunding.rawValue: false] as [String : Any]
    
    if let nick = nickname, !nick.isEmpty {
        params[Parameter.nickName.rawValue] = nick
    }
    
    return params
}

// MARK: - Make Request

fileprivate func getTokensAndExecute(params: [String: Any], action: Action) -> Observable<WalletItemResult> {
    let guidString = UUID().uuidString
    let urlRequest = createFiservRequest(with: nil, method: .get, guid: guidString)
    let requestId = ShortUUIDGenerator.getUUID(length: 8)
    
    let totalPathLength = urlRequest.url!.absoluteString.count
    let path = String(urlRequest.url!.absoluteString.suffix(totalPathLength - Environment.shared.mcsConfig.fiservUrl.count))

    var requestBodyString = ""
    if let body = urlRequest.httpBody {
        requestBodyString = " - BODY: " + (String(data: body, encoding: .utf8) ?? "")
    }
    
    APILog(requestId: requestId, path: path, method: .get, message: "REQUEST\(requestBodyString)")
    
    return URLSession.shared.rx.dataResponse(request: urlRequest)
        .do(onNext: { data in
            let responseString = String(data: data, encoding: .utf8) ?? ""
            APILog(requestId: requestId, path: path, method: .get, message: "RESPONSE - BODY: \(responseString)")
        }, onError: { error in
            let serviceError = error as? ServiceError ?? ServiceError(cause: error)
            APILog(requestId: requestId, path: path, method: .get, message: "ERROR - \(serviceError.errorDescription ?? "")")
        })
        .flatMap { data -> Observable<WalletItemResult> in
            let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            guard let resultDictionary = result as? [String: Any],
                let guid = resultDictionary[ResponseKey.guid.rawValue] as? String,
                let hash = resultDictionary[ResponseKey.hash.rawValue] as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.localError.rawValue)
            }
            
            let encodedBody = try encodePayload(params, action: action, unique: guidString, guid: guid, hashResult: hash)
            let request = createFiservRequest(with: encodedBody, method: .post)
            
            return executePost(request: request)
        }
        .catchError { err in
            let error = err as? ServiceError ?? ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: err)
            if let fiservError = FiservErrorMapper.shared.getError(message: error.errorDescription ?? "", context: nil) {
                if fiservError.id == "INVAL-0019" { // Duplicate
                    throw ServiceError(serviceCode: ServiceErrorCode.dupPaymentAccount.rawValue)
                } else {
                    throw ServiceError(serviceMessage: fiservError.text)
                }
            } else {
                if error.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    throw error
                } else {
                    throw ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue)
                }
            }
    }
}

fileprivate func executePost(request: URLRequest) -> Observable<WalletItemResult> {
    let requestId = ShortUUIDGenerator.getUUID(length: 8)
    var path = ""
    if let urlString = request.url?.absoluteString {
        path = String(urlString.suffix(from: Environment.shared.mcsConfig.fiservUrl.endIndex))
    }
    
    var requestBodyString = ""
    if let body = request.httpBody {
        requestBodyString = " - BODY: " + (String(data: body, encoding: .utf8) ?? "")
    }
    
    APILog(requestId: requestId, path: path, method: .post, message: "REQUEST\(requestBodyString)")
    
    return URLSession.shared.rx.dataResponse(request: request)
        .do(onNext: { data in
            let responseString = String(data: data, encoding: .utf8) ?? ""
            APILog(requestId: requestId, path: path, method: .post, message: "RESPONSE - BODY:  \(responseString)")
        }, onError: { error in
            let serviceError = error as? ServiceError ?? ServiceError(cause: error)
            APILog(requestId: requestId, path: path, method: .post, message: "ERROR - \(serviceError.errorDescription ?? "")")
        })
        .map { data -> WalletItemResult in
            do {
                let resultDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                let responseValue = parseResponse(with: resultDictionary!)
                
                guard responseValue.responseCode == 0 else {
                    throw ServiceError(serviceCode: "Fiserv", serviceMessage: responseValue.statusMessage)
                }
                
                return responseValue
            } catch let error as NSError {
                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue, cause: error)
            }
    }
}

fileprivate func encodePayload(_ payloadParameters : [String : Any], action: Action, unique: String, guid: String, hashResult: String) throws -> Data {
    let jsonData = try JSONSerialization.data(withJSONObject: payloadParameters)
    
    let payload = String(data: jsonData, encoding: .utf8)?.replacingOccurrences(of: "\\", with: "")
    
    let content = "action=\(action.rawValue)&payload=\(payload!)&unique=\(unique)&guid=\(guid)&hashResult=\(hashResult)"
    var encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    encodedContent = encodedContent.replacingOccurrences(of: "+", with: "%2B") // "+" signs were being turned into spaces on Fiserv's end
    
    return encodedContent.data(using: .utf8)!
}

fileprivate func createFiservRequest(with body: Data?, method: HttpMethod, guid: String? = nil) -> URLRequest {
    let endpoint = guid != nil ? "FiservJsonMessenger?v=\(guid!)" : "Process"
    var urlRequest = URLRequest(url: URL(string: "\(Environment.shared.mcsConfig.fiservUrl)/\(endpoint)")!)
    urlRequest.httpMethod = method.rawValue
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    if let body = body {
        urlRequest.httpBody = body
    }
    
    return urlRequest
}

// MARK: - Parse Response

fileprivate func parseResponse(with value: [String:Any]) -> WalletItemResult {
    let code = value[ResponseKey.responseCode.rawValue] as? Int
    let statusMessage = value[ResponseKey.statusMessage.rawValue] as? String
    
    var walletItemIdString = ""
    if let walletItemId = value[ResponseKey.walletItemId.rawValue] as? Int {
        walletItemIdString = String(walletItemId)
    }
    return WalletItemResult(responseCode: code ?? -1, statusMessage: statusMessage ?? "", walletItemId: walletItemIdString)
}

// MARK: - Logging

fileprivate func APILog(requestId: String, path: String, method: HttpMethod, message: String) {
    #if DEBUG
        NSLog("[FiservApi][%@][%@] %@ %@", requestId, path, method.rawValue, message)
    #endif
}
