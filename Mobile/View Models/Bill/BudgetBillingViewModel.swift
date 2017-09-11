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
    
    private var billService: BillService

    let accountDetail: AccountDetail!
    let currentEnrollment: Variable<Bool>!
    let enrolling = Variable(false)
    let unenrolling = Variable(false)
    let selectedUnenrollmentReason = Variable(-1)
    
    required init(accountDetail: AccountDetail, billService: BillService) {
        self.accountDetail = accountDetail
        self.billService = billService
        
        let initialEnrollment = accountDetail.isBudgetBillEnrollment
        currentEnrollment = Variable(initialEnrollment)
        
        currentEnrollment.asObservable()
            .map { !initialEnrollment && $0 }
            .bind(to: enrolling)
            .disposed(by: disposeBag)
        
        currentEnrollment.asObservable()
            .map { initialEnrollment && !$0 }
            .bind(to: unenrolling)
            .disposed(by: disposeBag)
    }
    
    func getBudgetBillingInfo(onSuccess: @escaping (BudgetBillingInfo) -> Void, onError: @escaping (String) -> Void) {
        billService.fetchBudgetBillingInfo(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { billingInfo in
                onSuccess(billingInfo)
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func enroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        billService.enrollBudgetBilling(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func unenroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        billService.unenrollBudgetBilling(accountNumber: accountDetail.accountNumber, reason: getReasonString(forIndex: selectedUnenrollmentReason.value))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
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
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted quarterly based on your actual usage. After 12 months, your Budget Billing amount will be recalculated based on your previous 12-month's usage.", comment: "")
        }
    }
    
    func getFooterText() -> String? {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("Budget Billing only includes BGE charges. If you have selected an alternate supplier, the charges from your supplier will be listed as a separate item on your bill.", comment: "")
        case .comEd:
            if accountDetail.hasElectricSupplier && accountDetail.isDualBillOption {
                return NSLocalizedString("Budget Billing is available for your ComEd Delivery charges. Electric Supply charges from your Retail Electric Supplier will not be included in your Budget Billing plan.", comment: "")
            }
        case .peco:
            if accountDetail.hasElectricSupplier && accountDetail.isDualBillOption {
                return NSLocalizedString("Budget billing option only includes PECO charges. Energy Supply charges are billed by your chosen generation provider.", comment: "")
            } else if let budgetBillMessage = accountDetail.budgetBillMessage {
                if budgetBillMessage.contains("Your account has not yet been open for a year") {
                    return NSLocalizedString("PECO bases the monthly budget billing amount on your average bill over the past 12 months. Your account has not yet been open for a year. Therefore, your monthly budget billing amount is an estimate that takes into account the usage of the previous resident at your address and/or the average usage in your area. Be aware that your usage may differ from the previous resident. This may result in future changes to your budget billing amount.", comment: "")

                }
            }
        }
        return nil
    }
    
    func getReasonString(forIndex index: Int) -> String {
        if index == 0 {
            return String(format: NSLocalizedString("Closing %@ Account", comment: ""), Environment.sharedInstance.opco.displayString)
        } else if index == 1 {
            return NSLocalizedString("Changing Bank Account", comment: "")
        } else if index == 2 {
            return NSLocalizedString("Dissatisfied with program", comment: "")
        } else if index == 3 {
            return NSLocalizedString("Program no longer meets my needs", comment: "")
        } else if index == 4 {
            return NSLocalizedString("Other", comment: "")
        }
        return "" // Should not happen
    }
    
}

