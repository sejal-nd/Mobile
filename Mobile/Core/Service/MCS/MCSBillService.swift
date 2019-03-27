//
//  MCSBillService.swift
//  Mobile
//
//  Created by Marc Shilling on 4/28/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class MCSBillService: BillService {
    func fetchBudgetBillingInfo(accountNumber: String) -> Observable<BudgetBillingInfo> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/billing/budget")
        .map { response in
            guard let dict = response as? NSDictionary, let budgetBillingInfo = BudgetBillingInfo.from(dict) else {
                throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
            }
            
            return budgetBillingInfo
        }
    }
    
    func enrollBudgetBilling(accountNumber: String) -> Observable<Void> {
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/billing/budget", params: nil)
            .mapTo(())
            .do(onNext: { RxNotifications.shared.accountDetailUpdated.onNext(()) })
    }
    
    func unenrollBudgetBilling(accountNumber: String, reason: String) -> Observable<Void> {
        let params = ["reason": reason, "comment": ""] // I don't know why we need comment, but it's in their docs
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/billing/budget/delete", params: params)
            .mapTo(())
            .do(onNext: { RxNotifications.shared.accountDetailUpdated.onNext(()) })
    }
    
    func enrollPaperlessBilling(accountNumber: String, email: String?) -> Observable<Void> {
        let params = ["email": email ?? ""]
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/billing/paperless", params: params)
            .mapTo(())
            .do(onNext: { RxNotifications.shared.accountDetailUpdated.onNext(()) })
    }
    
    func unenrollPaperlessBilling(accountNumber: String) -> Observable<Void> {
        return MCSApi.shared.delete(pathPrefix: .auth, path: "accounts/\(accountNumber)/billing/paperless", params: nil)
            .mapTo(())
            .do(onNext: { RxNotifications.shared.accountDetailUpdated.onNext(()) })
    }
    
    func fetchBillPdf(accountNumber: String, billDate: Date) -> Observable<String> {
        let dateString = DateFormatter.yyyyMMddFormatter.string(from: billDate)
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/billing/\(dateString)/pdf", logResponseBody: false)
            .map { response in
                guard let dict = response as? NSDictionary, let dataString = dict.object(forKey: "billImageData") as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return dataString
            }
    }
    
    func fetchBillingHistory(accountNumber: String, startDate: Date, endDate: Date) -> Observable<BillingHistory> {
        let startDateString = DateFormatter.yyyyMMddFormatter.string(from: startDate)
        let endDateString = DateFormatter.yyyyMMddFormatter.string(from: endDate)
        
        var params = [
            "start_date": startDateString,
            "end_date": endDateString,
            "statement_type": "03"
        ]
        
        let opCo = Environment.shared.opco
        if opCo == .comEd || opCo == .peco {
            params["biller_id"] = "\(opCo.rawValue)Registered"
        }
        
        return MCSApi.shared.post(pathPrefix: .auth, path: "accounts/\(accountNumber)/billing/history", params: params)
            .map { response in
                guard let dict = response as? NSDictionary, let billingHistory = BillingHistory.from(dict) else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                return billingHistory
            }
    }
    
}
