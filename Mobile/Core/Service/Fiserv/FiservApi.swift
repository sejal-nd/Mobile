//
//  FiservApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

private enum ResponseKey : String {
    case ResponseCode = "ResponseCode"
    case StatusMessage = "StatusMessage"
    case WalletItemId = "WalletItemID"
}

private enum MessageId : String {
    case InsertCheck = "insertWalletCheck"
    case InsertCredit = "insertWalletCard"
    case updateCredit = "updateWalletCard"
}

private enum Action : String {
    case Insert = "OD_InsertWalletItem"
    case Update = "OD_UpdateWalletItem"
}

private enum Parameter : String {
    case MessageId = "MessageId"
    case WalletItemId = "WalletItemID"
    case RequestTimestamp = "RequestTimestamp"
    case AppId = "AppId"
    case ProcessingRegionCode = "ProcessingRegionCode"
    case BillerId = "BillerId"
    case ConsumerId = "ConsumerId"
    case SessionToken = "AuthSessToken"
    case DeviceProfile = "DeviceProfile"
    case UserAgentString = "UserAgentString"
    case WalletExternalId = "WalletExternalID"
    case OneTimeUse = "OneTimeUse"
    case IsDefaultFunding = "IsDefaultFundingSource"
    case NickName = "NickName"
    
    case CheckingDetail = "CheckingDetail"
    case CardDetail = "CardDetail"

    case CardNumber = "CardNumber"
    case ExpirationDate = "ExpirationDate"
    case SecurityCode = "SecurityCode"
    case PostalCode = "ZipCode"
    
    case RoutingNumber = "RoutingNumber"
    case CheckAccountNumber = "CheckAccountNumber"
    case FirstName = "FirstName"
    case LastName = "LastName"
    case CheckType = "CheckType"
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
                        completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: false)
        
        params[Parameter.MessageId.rawValue] = MessageId.InsertCheck.rawValue
        params[Parameter.CheckingDetail.rawValue] = createBankAccountDetailDictionary(accountNumber: bankAccountNumber,
                                                                     routingNumber: routingNumber,
                                                                     firstName: firstName,
                                                                     lastName: lastName)
        
        do {
            let encodedBody = try encodePayload(params, action: Action.Insert.rawValue)
            post(body: encodedBody, completion: completion)
            
        }catch let err as NSError {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, cause: err)))
        }
    }
    
    func addCreditCard(cardNumber: String,
                       expirationMonth: String,
                       expirationYear: String,
                       securityCode: String,
                       postalCode: String,
                       nickname: String?,
                       token: String,
                       customerNumber: String,
                       completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        
        
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: false)
        params[Parameter.MessageId.rawValue] = MessageId.InsertCredit.rawValue
        params[Parameter.CardDetail.rawValue] = createCardDetailDictionary(cardNumber: cardNumber,
                                                          expirationMonth: expirationMonth,
                                                          expirationYear: expirationYear,
                                                          securityCode: securityCode,
                                                          postalCode: postalCode)
        
        do {
            let encodedBody = try encodePayload(params, action: Action.Insert.rawValue)
            post(body: encodedBody, completion: completion)
            
        }catch let err as NSError {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, cause: err)))
        }
    }
    
    func updateCreditCard(walletItemID: String,
                          expirationMonth: String,
                          expirationYear: String,
                          securityCode: String,
                          postalCode: String,
                          nickname: String?,
                          token: String,
                          customerNumber: String,
                          completion: @escaping (_ result: ServiceResult<WalletItemResult>) -> Swift.Void) {
        var params = createBaseParameters(token: token, customerNumber: customerNumber, nickname: nickname, oneTimeUse: false)
        
        let expiration = "" + expirationMonth + expirationYear.substring(from: expirationYear.index(expirationYear.startIndex, offsetBy: 2))
        let cardDetail = [Parameter.ExpirationDate.rawValue : expiration,
                          Parameter.SecurityCode.rawValue : securityCode,
                          Parameter.PostalCode.rawValue : postalCode]
        
        params[Parameter.MessageId.rawValue] = MessageId.updateCredit.rawValue
        params[Parameter.CardDetail.rawValue] = cardDetail
        params[Parameter.WalletItemId.rawValue] = walletItemID
        
        do {
            let encodedBody = try encodePayload(params, action: Action.Update.rawValue)
            post(body: encodedBody, completion: completion)
            
        }catch let err as NSError {
            completion(ServiceResult.Failure(ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, cause: err)))
        }
    }
    
    private func createCardDetailDictionary(cardNumber: String?,
                                            expirationMonth: String,
                                            expirationYear: String,
                                            securityCode: String?,
                                            postalCode: String?) -> [String:Any] {
        let expiration = expirationMonth + expirationYear.substring(from: expirationYear.index(expirationYear.startIndex, offsetBy: 2))
        var details = [Parameter.ExpirationDate.rawValue : expiration] as [String: Any]
        
        if(!(cardNumber ?? "").isEmpty) {
            details[Parameter.CardNumber.rawValue] = cardNumber
        }
        if(!(securityCode ?? "").isEmpty) {
            details[Parameter.SecurityCode.rawValue] = securityCode
        }
        if(!(postalCode ?? "").isEmpty) {
            details[Parameter.PostalCode.rawValue] = postalCode
        }
        
        return details
    }
    
    private func createBankAccountDetailDictionary(accountNumber: String,
                                                   routingNumber : String,
                                                   firstName : String?,
                                                   lastName : String?) -> [String:Any] {
        var details = [Parameter.RoutingNumber.rawValue : routingNumber,
                       Parameter.CheckAccountNumber.rawValue : accountNumber,
                       Parameter.CheckType.rawValue : 1] as [String : Any]
        
        if(!(firstName ?? "").isEmpty) {
            details[Parameter.FirstName.rawValue] = firstName
        }
        if(!(lastName ?? "").isEmpty) {
            details[Parameter.LastName.rawValue] = lastName
        }
        
        return details
    }
    
    private func encodePayload(_ payloadParameters : [String : Any], action: String) throws -> Data {
        let jsonData: NSData = try JSONSerialization.data(withJSONObject: payloadParameters) as NSData
        
        let payload = String.init(data: jsonData as Data, encoding: String.Encoding.utf8)?.replacingOccurrences(of: "\\", with: "")
        
        let content = "action=" + action + "&payload=" + payload!
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        dLog(message: payload ?? "Empty Payload")
        
        return encodedContent.data(using:String.Encoding.utf8)!
    }
    
    private func createBaseParameters(token: String, customerNumber: String, nickname: String?, oneTimeUse: Bool) -> [String:Any] {
        
        let opCo = Environment.sharedInstance.opco
        let time = Int(NSDate().timeIntervalSince1970)
        let billerId = "\(opCo.rawValue)Registered"
        
        var params = [Parameter.RequestTimestamp.rawValue:"/Date(" + String(time) + ")/",
                      Parameter.AppId.rawValue:"FiservProxy",
                      Parameter.ProcessingRegionCode.rawValue:2,
                      Parameter.BillerId.rawValue:billerId,
                      Parameter.ConsumerId.rawValue:customerNumber,
                      Parameter.SessionToken.rawValue:token,
                      Parameter.DeviceProfile.rawValue:[Parameter.UserAgentString.rawValue : "MobileApp"],
                      Parameter.WalletExternalId.rawValue:customerNumber,
                      Parameter.OneTimeUse.rawValue:oneTimeUse,
                      Parameter.IsDefaultFunding.rawValue:false] as [String : Any]
        
        if(!(nickname ?? "").isEmpty) {
            params[Parameter.NickName.rawValue] = nickname
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
                let serviceError = ServiceError(serviceCode: ServiceErrorCode.LocalError.rawValue, cause: error)
                completion(ServiceResult.Failure(serviceError))
                
            } else {
                let responseString = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
                dLog(message: responseString)
                
                do {
                    let resultDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                    let responseValue = self.parseResponse(with: resultDictionary!)
                    
                    if(responseValue.responseCode == 0) {
                        completion(ServiceResult.Success(responseValue))
                    } else {
                        let serviceError = ServiceError(serviceCode: "Fiserv", serviceMessage:responseValue.statusMessage)
                        completion(ServiceResult.Failure(serviceError))
                    }
                }
                catch let error as NSError {
                    let serviceError = ServiceError(serviceCode: ServiceErrorCode.Parsing.rawValue, cause: error)
                    completion(ServiceResult.Failure(serviceError))
                }
            }
        }).resume()
    }
    
    private func createFiservRequest(with body: Data, method: String) -> URLRequest {
        var urlRequest  = URLRequest(url: URL(string: Environment.sharedInstance.fiservUrl)!)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body
        return urlRequest
    }
    
    private func parseResponse(with value: [String:Any]) -> WalletItemResult {
        let code = value[ResponseKey.ResponseCode.rawValue] as? Int
        let statusMessage = value[ResponseKey.StatusMessage.rawValue] as? String
        let sanitizedStatusMessage = FiservMessageSanitizer.sanitizeErrorMessage(message:statusMessage ?? "", transactionType: "")
        let walletItemId = ""
        return WalletItemResult(responseCode:code ?? -1, statusMessage:sanitizedStatusMessage, walletItemId:walletItemId)
    }
}
