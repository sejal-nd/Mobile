//
//  FiservApi.swift
//  Mobile
//
//  Created by Kenny Roethel on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

struct FiservApi {
    func addBankAccount(bankAccountNumber: String,
                        routingNumber: String,
                        customerNumber: String,
                        firstName: String,
                        lastName: String,
                        token: String,
                        completion: @escaping (_ result: ServiceResult<Void>) -> Swift.Void) {
        
        let opCo = Environment.sharedInstance.opco
        
        
        
        let deviceProfile = ["UserAgentString" : "MobileApp"]
        let checking = ["RoutingNumber" : routingNumber,
                        "CheckAccountNumber" : bankAccountNumber,
                        "FirstName" : firstName,
                        "LastName" : lastName,
                        "CheckType" : 1] as [String : Any]
        
        let time = Int(NSDate().timeIntervalSince1970)
        
        let data = ["MessageId":"insertWalletCheck",
        "RequestTimestamp":"/Date(" + String(time) + ")/",
        "AppId":"FiservProxy",
        "ProcessingRegionCode":2,
        "BillerId":"\(opCo.rawValue)Registered",
        "ConsumerId":customerNumber,
        "AuthSessToken":token,
        "DeviceProfile":deviceProfile,
        "WalletExternalID":customerNumber,
        "OneTimeUse":false,
        "CheckingDetail":checking,
        "IsDefaultFundingSource":false] as [String : Any]
        
        do {
            let jsonData: NSData = try JSONSerialization.data(withJSONObject: data) as NSData
            
            let payload = String.init(data: jsonData as Data, encoding: String.Encoding.utf8)?.replacingOccurrences(of: "\\", with: "")
            
            let content = "action=OD_InsertWalletItem&payload=" + payload!
            let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            
            print("\n")
            print(payload ?? "p")
            print("\n")
            
            var r  = URLRequest(url: URL(string: "https://av-billerdirectui-uat.onefiserv.com/BillerDirectUI/Mobile/Process")!)
            r.httpMethod = "POST"
            r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let d = encodedContent.data(using:String.Encoding.utf8, allowLossyConversion: false)
            r.httpBody = d
            
            URLSession.shared.dataTask(with: r, completionHandler: { (dat:Data?, resp: URLResponse?, err: Error?) in
                print(String.init(data: dat!, encoding: String.Encoding.utf8) ?? "")
                
                do {
                    let parse = try JSONSerialization.jsonObject(with: dat!, options: JSONSerialization.ReadingOptions.allowFragments)  as? [String: Any]
                    if(parse?["ResponseCode"] as? Int == 0) {
                        completion(ServiceResult.Success())
                    } else {
                        let message = self.mapError(message: (parse?["StatusMessage"] as? String)!, transactionType: "")
                        completion(ServiceResult.Failure(ServiceError(serviceCode: "Fiserv", serviceMessage: message)))
                    }
                }
                catch let err as NSError {
                    print(err)
                }
                
            }).resume()
        }catch let err as NSError {
            print(err)
        }
    }
    
    func addCreditCard(cardNumber: String,
                        expirationMonth: String,
                        expirationYear: String,
                        securityCode: String,
                        firstName: String,
                        lastName: String,
                        postalCode: String,
                        token: String,
                        completion: @escaping (_ result: ServiceResult<Void>) -> Swift.Void) {
        
    }
    
    func createBaseParameters(token: String, customerNumber: String, oneTimeUse: Bool) -> [String:Any] {
        
        let opCo = Environment.sharedInstance.opco
        let time = Int(NSDate().timeIntervalSince1970)
        
        return ["MessageId":"insertWalletCheck",
                    "RequestTimestamp":"/Date(" + String(time) + ")/",
                    "AppId":"FiservProxy",
                    "ProcessingRegionCode":2,
                    "BillerId":"\(opCo.rawValue)Registered",
            "ConsumerId":customerNumber,
            "AuthSessToken":token,
            "DeviceProfile":["UserAgentString" : "MobileApp"],
            "WalletExternalID":customerNumber,
            "OneTimeUse":oneTimeUse,
            "IsDefaultFundingSource":false] as [String : Any]
    }
    
    func mapError(message: String, transactionType: String) -> String {
        //Pulled From JS - TODO cleanup
        let walletStatus = message.lowercased()
        var status: String
        
        if (walletStatus.range(of: "ach account exist already") != nil) {
            status = "The information entered was not accepted. Please verify and re-enter your new payment account information.";
        } else if (walletStatus.range(of: "card exist already") != nil) {
            status = "The information entered was not accepted. Please verify and re-enter your new payment account information.";
        } else if (walletStatus.range(of: "not valid card account") != nil) {
            status = "The information entered was not accepted. Please verify and re-enter " +
            "your new payment account information.";
        } else if (walletStatus.range(of: "inthe-0001") != nil) {
            status = "We're sorry, we are unable to process your request at this time. Please" +
            " try again later.";
        } else if (walletStatus.range(of: "inval-0019") != nil) {
            if (transactionType == "makePayment") {
                status = "We're sorry, we are unable to process your request as the wallet item already exists. Please login to make a payment."; //SIR112221 //fiservResponse.statusMessage;
            } else {
                status = "Cannot save this wallet item as it already exists!"; //SIR112221
            }
        }//Start: SIR112221
        else if (walletStatus.range(of: "inval-0001") != nil || walletStatus.range(of: "inval-0020") != nil
            || walletStatus.range(of: "inval-0021") != nil || walletStatus.range(of: "pyact-0001") != nil ||
            walletStatus.range(of: "pyact-0008") != nil) {
            status = "We're sorry, we are unable to process your request due to incorrect data being entered. Please try again.";
        } else if (walletStatus.range(of: "inval-0016") != nil || walletStatus.range(of: "inval-0025") != nil) {
            status = "We're sorry, we are unable to process your request as you have reached the maximum number of payments permitted.";
        } else if (walletStatus.range(of: "inval-0017") != nil || walletStatus.range(of: "inval-0026") != nil) {
            status = "We're sorry, we are unable to process your request.";// Please contact
            // our Customer Care Center at " + phoneNumber + " for more information. (Hours of operation: " + officeHours + ")";
        } else if (walletStatus.range(of: "inval-0018") != nil) {
            status = "We're sorry, we are unable to process your request. Please contact your financial institution for further information.";
        } else if (walletStatus.range(of: "inval-0022") != nil || walletStatus.range(of: "secur-0002") != nil) {
            status = "We're sorry, we are unable to process your request at this time as your request timed out. Please try again later.";
            //fiservResponse.refreshWallet = true;
        } else if (walletStatus.range(of: "inval-0024") != nil) {
            status = "We're sorry, we are unable to process your request as it's a duplicate payment.";
        } else if (walletStatus.range(of: "mpymt-0009") != nil) {
            status = "We're sorry, we are unable to process your request. The credit card you selected has been declined. Please select another card. If you have questions about why your credit card was declined, please contact the credit card issuer.";
        } else if (walletStatus.range(of: "mpymt-0011") != nil) {
            status = "We're sorry, we can't schedule this payment on the selected date because it exceeds the number of payments permitted.";
        }
            //End: SIR112221
            // same card number but different info (zip, cvv2, etc)
            //    else if (walletStatus.indexOf('success') > -1 && responseCode.indexOf('businessruleviolation') > -1) {
            //      response.mStatus = 'The information entered was not accepted. Please verify and re-enter your new payment account information.';
            //    }
        else {
            status = message
            //fiservResponse.message = fiservResponse.statusMessage;
        }
        
        return status
    }
}
