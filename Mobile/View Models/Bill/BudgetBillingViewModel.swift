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
    private var alertsService: AlertsService

    let accountDetail: AccountDetail!
    let currentEnrollment: Variable<Bool>!
    var averageMonthlyBill: String?
    
    let enrolling = Variable(false)
    let unenrolling = Variable(false)
    let selectedUnenrollmentReason = Variable(-1)
    
    required init(accountDetail: AccountDetail, billService: BillService, alertsService: AlertsService) {
        self.accountDetail = accountDetail
        self.billService = billService
        self.alertsService = alertsService
        
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
            .subscribe(onNext: { [weak self] billingInfo in
                self?.averageMonthlyBill = billingInfo.averageMonthlyBill
                onSuccess(billingInfo)
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func enroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        billService.enrollBudgetBilling(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                NotificationCenter.default.post(name: .DidChangeBudgetBillingEnrollment, object: self)
                if Environment.shared.opco != .bge {
                    self.alertsService.enrollBudgetBillingNotification(accountNumber: self.accountDetail.accountNumber)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { _ in
                            dLog("Enrolled in the budget billing push notification")
                            onSuccess()
                        }, onError: { error in
                            dLog("Failed to enroll in the budget billing push notification")
                            onSuccess()
                        }).disposed(by: self.disposeBag)
                } else {
                    onSuccess()
                }
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func unenroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        billService.unenrollBudgetBilling(accountNumber: accountDetail.accountNumber, reason: getReasonString(forIndex: selectedUnenrollmentReason.value))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                NotificationCenter.default.post(name: .DidChangeBudgetBillingEnrollment, object: self)
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(enrolling.asObservable(), unenrolling.asObservable(), selectedUnenrollmentReason.asObservable()) {
            if $0 { return true }
            if Environment.shared.opco == .comEd || Environment.shared.opco == .peco {
                if $1 && $2 != -1 { return true }
            } else { // BGE
                if $1 { return true }
            }
            return false
        }
    }
    
    func getAmountDescriptionText() -> String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted periodically based on your actual usage. Your actual usage will continue to be shown on your monthly bill. If your Budget Billing payment amount needs to be adjusted, you will be notified 1 month prior to the change.", comment: "")
        case .comEd:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted periodically based on your actual usage. The ComEd app will be automatically set to notify you when your billing amount is adjusted (and you can modify your alert preferences at any time). After 12 months, any credit/debit balances will be included in the calculation for the following year’s Budget Billing payment.", comment: "")
        case .peco:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted quarterly based on your actual usage. The PECO app will be automatically set to notify you when your billing amount is adjusted (and you can modify your alert preferences at any time). After 12 months, your Budget Billing amount will be recalculated based on your previous 12-month's usage.", comment: "")
        }
    }
    
    func getFooterText() -> String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("Budget Billing only includes BGE charges. If you have selected an alternate supplier, the charges from your supplier will be listed as a separate item on your bill.", comment: "")
        case .comEd:
            if accountDetail.isSupplier && accountDetail.isDualBillOption {
                return NSLocalizedString("Budget Billing is available for your ComEd Delivery charges. Electric Supply charges from your Retail Electric Supplier will not be included in your Budget Billing plan.", comment: "")
            }
        case .peco:
            if accountDetail.isSupplier && accountDetail.isDualBillOption {
                return NSLocalizedString("Budget billing option only includes PECO charges. Energy Supply charges are billed by your chosen generation provider.", comment: "")
            } else {
                return NSLocalizedString("PECO bases the monthly Budget Billing amount on your average bill over the past 12 months. If your account has not yet been open for a year, your monthly Budget Billing amount is an estimate that takes into account the usage of the previous resident at your address and/or the average usage in your area. Be aware that your usage may differ from the previous resident. This may result in future changes to your Budget Billing amount.", comment: "")
            }
        }
        return nil
    }
    
    func getReasonString(forIndex index: Int) -> String {
        if index == 0 {
            return String(format: NSLocalizedString("Closing %@ Account", comment: ""), Environment.shared.opco.displayString)
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

