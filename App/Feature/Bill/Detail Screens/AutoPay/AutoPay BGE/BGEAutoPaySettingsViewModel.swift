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
    
    let amountToPay: BehaviorRelay<AmountType>
    let whenToPay: BehaviorRelay<BGEAutoPayViewModel.PaymentDateType>
    
    let amountNotToExceed: BehaviorRelay<String>
    let numberOfDaysBeforeDueDate: BehaviorRelay<Int>
    
    init(accountDetail: AccountDetail,
         initialEnrollmentStatus: BGEAutoPayViewModel.EnrollmentStatus,
         amountToPay: AmountType,
         amountNotToExceed: Double,
         whenToPay: BGEAutoPayViewModel.PaymentDateType,
         numberOfDaysBeforeDueDate: Int) {
        self.accountDetail = accountDetail
        self.initialEnrollmentStatus = initialEnrollmentStatus
        self.amountToPay = BehaviorRelay(value: amountToPay)
        self.whenToPay = BehaviorRelay(value: whenToPay)
        self.amountNotToExceed = BehaviorRelay(value: amountNotToExceed.currencyString)
        self.numberOfDaysBeforeDueDate = BehaviorRelay(value: numberOfDaysBeforeDueDate)
    }
    
    private(set) lazy var amountNotToExceedDouble: Driver<Double> = amountNotToExceed.asDriver()
        .map { Double($0.filter { "0123456789.".contains($0) })! }
    
    private lazy var amountToPayIsValid: Driver<Bool> = Driver
        .combineLatest(amountToPay.asDriver(), amountNotToExceedDouble)
        { [weak self] amountToPay, amountNotToExceed in
            switch amountToPay {
            case .amountDue:
                return true
            case .upToAmount:
                guard let billingInfo = self?.accountDetail.billingInfo else { return false }
                let minPaymentAmount = billingInfo.minPaymentAmount
                let maxPaymentAmount = billingInfo.maxPaymentAmount(bankOrCard: .bank)
                //let maxPaymentAmount: Double = 500_000 // VSTS 219442: Decision to hardcode the max amount
                return amountNotToExceed >= minPaymentAmount && amountNotToExceed <= maxPaymentAmount
            }
        }
    
    private(set) lazy var amountToPayErrorMessage: Driver<String?> = amountNotToExceedDouble
        .map { [weak self] amountNotToExceed in
            guard let billingInfo = self?.accountDetail.billingInfo else { return nil }
            let minPaymentAmount = billingInfo.minPaymentAmount
            let maxPaymentAmount = billingInfo.maxPaymentAmount(bankOrCard: .bank)
            //let maxPaymentAmount: Double = 500_000 // VSTS 219442: Decision to hardcode the max amount
            if amountNotToExceed < minPaymentAmount {
                let textFormat = NSLocalizedString("Minimum payment allowed is %@", comment: "")
                return String.localizedStringWithFormat(textFormat, minPaymentAmount.currencyString)
            } else if amountNotToExceed > maxPaymentAmount {
                let textFormat = NSLocalizedString("Maximum payment allowed is %@", comment: "")
                return String.localizedStringWithFormat(textFormat, maxPaymentAmount.currencyString)
            } else {
                return nil
            }
        }
    
    private lazy var whenToPayIsValid = Driver
        .combineLatest(whenToPay.asDriver(),
                       numberOfDaysBeforeDueDate.asDriver())
        { whenToPay, numberOfDaysBeforeDueDate in
            whenToPay != .beforeDueDate || numberOfDaysBeforeDueDate != 0
        }
    
    private(set) lazy var enableDone: Driver<Bool> = Driver
        .combineLatest(amountToPayIsValid, whenToPayIsValid) { $0 && $1 }
    
    func formatAmountNotToExceed() {
        let textStr = String(amountNotToExceed.value.filter { "0123456789".contains($0) })
        if let intVal = Double(textStr) {
            amountNotToExceed.accept((intVal / 100).currencyString)
        }
    }
}
