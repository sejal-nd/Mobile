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
                        oneTimeUse: Bool) -> Observable<WalletItemResult> {
        
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: oneTimeUse)
        
        params[Parameter.messageId.rawValue] = MessageId.insertCheck.rawValue
        params[Parameter.checkingDetail.rawValue] = createBankAccountDetailDictionary(accountNumber: bankAccountNumber,
                                                                     routingNumber: routingNumber,
                                                                     firstName: firstName,
                                                                     lastName: lastName)
        
        return getTokens(params: params)
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
        
        return getTokens(params: params)
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
        
        return getTokens(params: params)
    }
}


// MARK: - Helper Functions

fileprivate func getTokens(params: [String: Any]) -> Observable<WalletItemResult> {
    let guidString = UUID().uuidString
    let urlRequest = createFiservRequest(with: nil, method: "GET", guid: guidString)
    
    return URLSession.shared.rx.data(request: urlRequest)
        .map { data -> (String, String, String) in
            let responseString = String(data: data, encoding: .utf8) ?? ""
            dLog(responseString)
            
            let resultDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            
            guard let guid = resultDictionary?[ResponseKey.guid.rawValue] as? String,
                let hash = resultDictionary?[ResponseKey.hash.rawValue] as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.localError.rawValue)
            }
            return (guidString, guid, hash)
        }
        .flatMap { (unique, guid, hashResult) -> Observable<WalletItemResult> in
            let encodedBody = try encodePayload(params, action: Action.update.rawValue, unique: unique, guid: guid, hashResult: hashResult)
            let urlRequest = createFiservRequest(with: encodedBody, method: "POST")
            return execute(request: urlRequest)
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


fileprivate func execute(request: URLRequest) -> Observable<WalletItemResult> {
    return URLSession.shared.rx.data(request: request)
        .map { data -> WalletItemResult in
            let responseString = String.init(data: data, encoding: .utf8) ?? ""
            dLog(responseString)
            
            do {
                let resultDictionary = try JSONSerialization.jsonObject(with: data, options:.allowFragments) as? [String: Any]
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

fileprivate func createCardDetailDictionary(cardNumber: String?,
                                            expirationMonth: String,
                                            expirationYear: String,
                                            securityCode: String?,
                                            postalCode: String?) -> [String:Any] {
    let expiration = expirationMonth + expirationYear[expirationYear.index(expirationYear.startIndex, offsetBy: 2)...]
    var details = [Parameter.expirationDate.rawValue : expiration] as [String: Any]
    
    if(!(cardNumber ?? "").isEmpty) {
        details[Parameter.cardNumber.rawValue] = cardNumber
    }
    if(!(securityCode ?? "").isEmpty) {
        details[Parameter.securityCode.rawValue] = securityCode
    }
    if(!(postalCode ?? "").isEmpty) {
        details[Parameter.postalCode.rawValue] = postalCode
    }
    
    return details
}

fileprivate func createBankAccountDetailDictionary(accountNumber: String,
                                                   routingNumber : String,
                                                   firstName : String?,
                                                   lastName : String?) -> [String:Any] {
    var details = [Parameter.routingNumber.rawValue : routingNumber,
                   Parameter.checkAccountNumber.rawValue : accountNumber,
                   Parameter.checkType.rawValue : 0] as [String : Any]
    
    if !(firstName ?? "").isEmpty {
        details[Parameter.firstName.rawValue] = firstName
    }
    if !(lastName ?? "").isEmpty {
        details[Parameter.lastName.rawValue] = lastName
    }
    
    return details
}

fileprivate func encodePayload(_ payloadParameters : [String : Any], action: String, unique: String, guid: String, hashResult: String) throws -> Data {
    let jsonData = try JSONSerialization.data(withJSONObject: payloadParameters)
    
    let payload = String(data: jsonData, encoding: .utf8)?.replacingOccurrences(of: "\\", with: "")
    
    let content = "action=\(action)&payload=\(payload!)&unique=\(unique)&guid=\(guid)&hashResult=\(hashResult)"
    var encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    encodedContent = encodedContent.replacingOccurrences(of: "+", with: "%2B") // "+" signs were being turned into spaces on Fiserv's end
    
    return encodedContent.data(using: .utf8)!
}

fileprivate func createBaseParameters(token: String, customerNumber: String, nickname: String?, oneTimeUse: Bool) -> [String:Any] {
    
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

fileprivate func createFiservRequest(with body: Data?, method: String, guid: String? = nil) -> URLRequest {
    let endpoint = guid != nil ? "FiservJsonMessenger?v=\(guid!)" : "Process"
    var urlRequest = URLRequest(url: URL(string: "\(Environment.shared.fiservUrl)/\(endpoint)")!)
    urlRequest.httpMethod = method
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    if let body = body {
        urlRequest.httpBody = body
    }
    
    return urlRequest
}

fileprivate func parseResponse(with value: [String:Any]) -> WalletItemResult {
    let code = value[ResponseKey.responseCode.rawValue] as? Int
    let statusMessage = value[ResponseKey.statusMessage.rawValue] as? String
    
    var walletItemIdString = ""
    if let walletItemId = value[ResponseKey.walletItemId.rawValue] as? Int {
        walletItemIdString = String(walletItemId)
    }
    return WalletItemResult(responseCode: code ?? -1, statusMessage: statusMessage ?? "", walletItemId: walletItemIdString)
}
