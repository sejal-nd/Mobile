//
//  BillAnalysisViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 10/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BillAnalysisViewModel {

    let accountDetail: AccountDetail

    required init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
    }
    
    var supplyCharges: Double { return accountDetail.billingInfo.supplyCharges ?? 0 }
    var taxesAndFees: Double { return accountDetail.billingInfo.taxesAndFees ?? 0 }
    var deliveryCharges: Double { return accountDetail.billingInfo.deliveryCharges ?? 0 }
    private var totalCharges: Double { return supplyCharges + taxesAndFees + deliveryCharges }

    var supplyChargesString: String { return supplyCharges.currencyString ?? "$0.00" }
    var taxesAndFeesString: String { return taxesAndFees.currencyString ?? "$0.00" }
    var deliveryChargesString: String { return deliveryCharges.currencyString ?? "$0.00" }
    var totalChargesString: String { return totalCharges.currencyString ?? "$0.00" }
    
}
