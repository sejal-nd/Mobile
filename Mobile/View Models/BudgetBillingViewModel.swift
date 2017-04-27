//
//  BudgetBillingViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BudgetBillingViewModel {
    
    let disposeBag = DisposeBag()
    
    let currentEnrollment: Variable<Bool>!
    let enrolling = Variable(false)
    let unenrolling = Variable(false)
    let selectedUnenrollmentReason = Variable(-1)
    
    required init(initialEnrollment: Bool) {
        currentEnrollment = Variable(initialEnrollment)
        currentEnrollment.asObservable().subscribe(onNext: { enrolled in
            self.enrolling.value = !initialEnrollment && enrolled
            self.unenrolling.value = initialEnrollment && !enrolled
        }).addDisposableTo(disposeBag)
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(enrolling.asObservable(), unenrolling.asObservable(), selectedUnenrollmentReason.asObservable()) {
            if $0 { return true }
            if Environment.sharedInstance.opco == .comEd || Environment.sharedInstance.opco == .peco {
                if $1 && $2 != -1 { return true }
            } else { // BGE
                if $1 { return true }
            }
            return false
        }
    }
    
    func getAmountDescriptionText() -> String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted periodically based on your actual usage. Your actual usage will continue to be shown on your monthly bill. If your Budget Billing payment amount needs to be adjusted, you will be notified 1 month prior to the change.", comment: "")
        case .comEd:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted periodically based on your actual usage. After 12 months, any credit/debit balances will be included in the calculation for the following year’s Budget Billing payment.", comment: "")
        case .peco:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted quarterly based on your actual usage. After 12 months, the difference between your budget bill amount and actual use for the previous 12 months will be applied to your bill.", comment: "")
        }
    }
    
    func getFooterText() -> String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Budget Billing only includes BGE charges. If you have selected an alternate supplier, the charges from your supplier will be listed as a separate item on your bill.", comment: "")
        case .comEd:
//            if user uses a 3rd party supplier and is a dual bill customer {
//                return NSLocalizedString("Budget Billing is available for your ComEd Delivery charges. Electric Supply charges from your Retail Electric Supplier will not be included in your Budget Billing plan.", comment: "")
//            }
            return nil
        case .peco:
//            if user uses a 3rd party supplier and is a dual bill customer {
//                return NSLocalizedString("Budget billing option only includes PECO charges. Energy Supply charges are billed by your chosen generation provider.", comment: "")
//            } else if user has less than 12 months of usage history {
//                return NSLocalizedString("PECO bases the monthly budget billing amount on your average bill over the past 12 months. Your account has not yet been open for a year. Therefore, your monthly budget billing amount is an estimate that takes into account the usage of the previous resident at your address and/or the average usage in your area. Be aware that your usage may differ from the previous resident. This may result in future changes to your budget billing amount.", comment: "")
//            }
            return nil
        }
    }
    
}

