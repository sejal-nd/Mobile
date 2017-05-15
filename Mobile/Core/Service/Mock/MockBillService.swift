//
//  MockBillService.swift
//  Mobile
//
//  Created by Marc Shilling on 5/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

class MockBillService : BillService {

    func fetchBudgetBillingInfo(account: Account, completion: @escaping (_ result: ServiceResult<BudgetBillingInfo>) -> Void) {
        let info = BudgetBillingInfo.from(["enrolled": true, "averageMonthlyBill": 120])!
        completion(ServiceResult.Success(info))
    }

    func enrollBudgetBilling(account: Account, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }
    
    func unenrollBudgetBilling(account: Account, reason: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }

    func enrollPaperlessBilling(accountNumber: String, email: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }
    
    func unenrollPaperlessBilling(accountNumber: String, completion: @escaping (_ result: ServiceResult<Void>) -> Void) {
        
    }
    
    func fetchBillPdf(account: Account, billDate: Date, completion: @escaping (_ result: ServiceResult<String>) -> Void) {
        
    }
}
