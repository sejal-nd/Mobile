//
//  BGEAutoPaySettingsViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 2/27/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class BGEAutoPaySettingsViewModel {
    
    let accountDetail: AccountDetail
    let initialEnrollmentStatus: BGEAutoPayViewModel.EnrollmentStatus
    
    let amountToPay: Variable<AmountType>
    let whenToPay: Variable<BGEAutoPayViewModel.PaymentDateType>
    
    let amountNotToExceed: Variable<String>
    let numberOfDaysBeforeDueDate: Variable<Int>
    
    init(accountDetail: AccountDetail,
         initialEnrollmentStatus: BGEAutoPayViewModel.EnrollmentStatus,
         amountToPay: AmountType,
         amountNotToExceed: Double,
         whenToPay: BGEAutoPayViewModel.PaymentDateType,
         numberOfDaysBeforeDueDate: Int) {
        self.accountDetail = accountDetail
        self.initialEnrollmentStatus = initialEnrollmentStatus
        self.amountToPay = Variable(amountToPay)
        self.whenToPay = Variable(whenToPay)
        self.amountNotToExceed = Variable(amountNotToExceed.currencyString)
        self.numberOfDaysBeforeDueDate = Variable(numberOfDaysBeforeDueDate)
    }
    
    var invalidSettingsMessage: String? {
        let defaultString = NSLocalizedString("Complete all required fields before returning to the AutoPay screen. Check your selected settings and complete secondary fields.", comment: "")
        
        if amountToPay.value == .upToAmount {
            if amountNotToExceedDouble == 0 {
                return defaultString
            } else {
                let minPaymentAmount = accountDetail.billingInfo.minPaymentAmount()
                let maxPaymentAmount = accountDetail.billingInfo.maxPaymentAmount(bankOrCard: .bank)
                if amountNotToExceedDouble < minPaymentAmount || amountNotToExceedDouble > maxPaymentAmount {
                    return String.localizedStringWithFormat("Complete all required fields before returning to the AutoPay screen. \"Amount Not To Exceed\" must be between %@ and %@", minPaymentAmount.currencyString, maxPaymentAmount.currencyString)
                }
            }
        }
        
        if whenToPay.value == .beforeDueDate && numberOfDaysBeforeDueDate.value == 0 {
            return defaultString
        }
        
        return nil
    }
    
    var amountNotToExceedDouble: Double {
        return Double(amountNotToExceed.value.filter { "0123456789.".contains($0) })!
    }
    
    func formatAmountNotToExceed() {
        let textStr = String(amountNotToExceed.value.filter { "0123456789".contains($0) })
        if let intVal = Double(textStr) {
            amountNotToExceed.value = (intVal / 100).currencyString
        }
    }
}
