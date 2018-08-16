//
//  FiservApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

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
                        oneTimeUse: Bool,
                        completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: oneTimeUse)
        
        params[Parameter.messageId.rawValue] = MessageId.insertCheck.rawValue
        params[Parameter.checkingDetail.rawValue] = createBankAccountDetailDictionary(accountNumber: bankAccountNumber,
                                                                     routingNumber: routingNumber,
                                                                     firstName: firstName,
                                                                     lastName: lastName)
        
        getTokens(onSuccess: { (unique, guid, hashResult) in
            do {
                let encodedBody = try self.encodePayload(params, action: Action.insert.rawValue, unique: unique, guid: guid, hashResult: hashResult)
                self.post(body: encodedBody, completion: completion)
            } catch let err as NSError {
                completion(ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: err)))
            }
        }, onError: {
            completion(ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue)))
        })
    
    }
    
    func addCreditCard(cardNumber: String,
                       expirationMonth: String,
                       expirationYear: String,
                       securityCode: String,
                       postalCode: String,
                       nickname: String?,
                       token: String,
                       customerNumber: String,
                       oneTimeUse: Bool,
                       completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        
        
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: oneTimeUse)
        params[Parameter.messageId.rawValue] = MessageId.insertCredit.rawValue
        params[Parameter.cardDetail.rawValue] = createCardDetailDictionary(cardNumber: cardNumber,
                                                          expirationMonth: expirationMonth,
                                                          expirationYear: expirationYear,
                                                          securityCode: securityCode,
                                                          postalCode: postalCode)
        
        getTokens(onSuccess: { (unique, guid, hashResult) in
            do {
                let encodedBody = try self.encodePayload(params, action: Action.insert.rawValue, unique: unique, guid: guid, hashResult: hashResult)
                self.post(body: encodedBody, completion: completion)
            } catch let err as NSError {
                completion(ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: err)))
            }
        }, onError: {
            completion(ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue)))
        })
    }
    
    func updateCreditCard(walletItemID: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String,
                          token: String,
                          customerNumber: String,
                          completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nil, oneTimeUse: false)
        
        var cardDetail = [String: String]()

        let expiration = "" + expirationMonth + expirationYear[expirationYear.index(expirationYear.startIndex, offsetBy: 2)...]
        cardDetail[Parameter.expirationDate.rawValue] = expiration
        cardDetail[Parameter.securityCode.rawValue] = securityCode
        cardDetail[Parameter.postalCode.rawValue] = postalCode

        params[Parameter.messageId.rawValue] = MessageId.updateCredit.rawValue
        params[Parameter.cardDetail.rawValue] = cardDetail
        params[Parameter.walletItemId.rawValue] = walletItemID
        
        getTokens(onSuccess: { (unique, guid, hashResult) in
            do {
                let encodedBody = try self.encodePayload(params, action: Action.update.rawValue, unique: unique, guid: guid, hashResult: hashResult)
                self.post(body: encodedBody, completion: completion)
            } catch let err as NSError {
                completion(ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: err)))
            }
        }, onError: {
            completion(ServiceResult.failure(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue)))
        })
    }
    
    private func getTokens(onSuccess: @escaping (_ unique: String, _ guid: String, _ hashResult: String) -> Void, onError: @escaping () -> Void) {
        let guidString = UUID().uuidString

        let urlRequest = createFiservRequest(with: nil, method: "GET", guid: guidString)
        URLSession.shared.dataTask(with:urlRequest, completionHandler: { (data:Data?, resp: URLResponse?, err: Error?) in
            if err != nil {
                onError()
            } else {
                let responseString = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
                dLog(responseString)
                
                do {
                    let resultDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                    
                    if let GUID = resultDictionary?[ResponseKey.guid.rawValue] as? String, let Hash = resultDictionary?[ResponseKey.hash.rawValue] as? String {
                        onSuccess(guidString, GUID, Hash)
                    } else {
                        onError()
                    }
                }
                catch {
                    onError()
                }
            }
        }).resume()
    }
    
    private func createCardDetailDictionary(cardNumber: String?,
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
    
    private func createBankAccountDetailDictionary(accountNumber: String,
                                                   routingNumber : String,
                                                   firstName : String?,
                                                   lastName : String?) -> [String:Any] {
        var details = [Parameter.routingNumber.rawValue : routingNumber,
                       Parameter.checkAccountNumber.rawValue : accountNumber,
                       Parameter.checkType.rawValue : 1] as [String : Any]
        
        if(!(firstName ?? "").isEmpty) {
            details[Parameter.firstName.rawValue] = firstName
        }
        if(!(lastName ?? "").isEmpty) {
            details[Parameter.lastName.rawValue] = lastName
        }
        
        return details
    }
    
    private func encodePayload(_ payloadParameters : [String : Any], action: String, unique: String, guid: String, hashResult: String) throws -> Data {
        let jsonData: NSData = try JSONSerialization.data(withJSONObject: payloadParameters) as NSData
        
        let payload = String.init(data: jsonData as Data, encoding: String.Encoding.utf8)?.replacingOccurrences(of: "\\", with: "")
        
        let content = "action=\(action)&payload=\(payload!)&unique=\(unique)&guid=\(guid)&hashResult=\(hashResult)"
        var encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        encodedContent = encodedContent.replacingOccurrences(of: "+", with: "%2B") // "+" signs were being turned into spaces on Fiserv's end
        
        return encodedContent.data(using:String.Encoding.utf8)!
    }
    
    private func createBaseParameters(token: String, customerNumber: String, nickname: String?, oneTimeUse: Bool) -> [String:Any] {
        
        let opCo = Environment.shared.opco
        let time = Int(NSDate().timeIntervalSince1970)
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
    
    private func post(body: Data, completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        let urlRequest = createFiservRequest(with: body, method: "POST")
        execute(request: urlRequest, completion: completion)
    }
    
    private func execute(request: URLRequest, completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        URLSession.shared.dataTask(with:request, completionHandler: { (data:Data?, resp: URLResponse?, err: Error?) in
            if let error = err {
                let serviceError = ServiceError(serviceCode: ServiceErrorCode.localError.rawValue, cause: error)
                completion(ServiceResult.failure(serviceError))
                
            } else {
                let responseString = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
                dLog(responseString)
                
                do {
                    let resultDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                    let responseValue = self.parseResponse(with: resultDictionary!)
                    
                    if(responseValue.responseCode == 0) {
                        completion(ServiceResult.success(responseValue))
                    } else {
                        let serviceError = ServiceError(serviceCode: "Fiserv", serviceMessage:responseValue.statusMessage)
                        completion(ServiceResult.failure(serviceError))
                    }
                }
                catch let error as NSError {
                    let serviceError = ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue, cause: error)
                    completion(ServiceResult.failure(serviceError))
                }
            }
        }).resume()
    }
    
    private func createFiservRequest(with body: Data?, method: String, guid: String? = nil) -> URLRequest {
        let endpoint = guid != nil ? "FiservJsonMessenger?v=\(guid!)" : "Process"
        var urlRequest = URLRequest(url: URL(string: "\(Environment.shared.fiservUrl)/\(endpoint)")!)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let body = body {
            urlRequest.httpBody = body
        }
        return urlRequest
    }
    
    private func parseResponse(with value: [String:Any]) -> WalletItemResult {
        let code = value[ResponseKey.responseCode.rawValue] as? Int
        let statusMessage = value[ResponseKey.statusMessage.rawValue] as? String

        var walletItemIdString = ""
        if let walletItemId = value[ResponseKey.walletItemId.rawValue] as? Int {
            walletItemIdString = String(walletItemId)
        }
        return WalletItemResult(responseCode: code ?? -1, statusMessage: statusMessage ?? "", walletItemId: walletItemIdString)
    }
}
