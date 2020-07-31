//
//  BudgetBillingViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BudgetBillingViewModel {
    
    let disposeBag = DisposeBag()
    
    private var alertsService: AlertsService

    let accountDetail: AccountDetail!

    var averageMonthlyBill: String?
    
    let selectedUnenrollmentReason = BehaviorRelay(value: -1)
    
    required init(accountDetail: AccountDetail, alertsService: AlertsService) {
        self.accountDetail = accountDetail
        self.alertsService = alertsService
    }
    
    func getBudgetBillingInfo(onSuccess: @escaping (NewBudgetBilling) -> Void, onError: @escaping (String) -> Void) {
        BillServiceNew.rx.fetchBudgetBillingInfo(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] billingInfo in
                self?.averageMonthlyBill = billingInfo.averageMonthlyBill.currencyString
                onSuccess(billingInfo)
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func enroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        BillServiceNew.rx.enrollBudgetBilling(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                NotificationCenter.default.post(name: .didChangeBudgetBillingEnrollment, object: self)
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
        BillServiceNew.rx.unenrollBudgetBilling(accountNumber: accountDetail.accountNumber, reason: reasonString(forIndex: selectedUnenrollmentReason.value))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                NotificationCenter.default.post(name: .didChangeBudgetBillingEnrollment, object: self)
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private(set) lazy var reasonForStoppingUnenrollButtonEnabled: Driver<Bool> =
        self.selectedUnenrollmentReason.asDriver().map { $0 != -1 }
    
    var footerLabelText: String? {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted periodically based on your actual usage. Your actual usage will continue to be shown on your monthly bill. If your Budget Billing payment amount needs to be adjusted, you will be notified 1 month prior to the change.\n\nBudget Billing only includes BGE charges. If you have selected an alternate supplier, the charges from your supplier will be listed as a separate item on your bill.", comment: "")
        case .comEd:
            var text = NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted periodically based on your actual usage. The ComEd app will be automatically set to notify you when your billing amount is adjusted (and you can modify your alert preferences at any time). After 12 months, any credit/debit balances will be included in the calculation for the following year’s Budget Billing payment.", comment: "")
            if accountDetail.isSupplier && accountDetail.isDualBillOption {
                text += NSLocalizedString("\n\nBudget Billing is available for your ComEd Delivery charges. Electric Supply charges from your Retail Electric Supplier will not be included in your Budget Billing plan.", comment: "")
            }
            return text
        case .peco:
            var text = NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted quarterly based on your actual usage. The PECO app will be automatically set to notify you when your billing amount is adjusted (and you can modify your alert preferences at any time). After 12 months, your Budget Billing amount will be recalculated based on your previous 12-month's usage.", comment: "")
            if accountDetail.isSupplier && accountDetail.isDualBillOption {
                text += NSLocalizedString("\n\nBudget billing option only includes PECO charges. Energy Supply charges are billed by your chosen generation provider.", comment: "")
            } else {
                text += NSLocalizedString("\n\nPECO bases the monthly Budget Billing amount on your average bill over the past 12 months. If your account has not yet been open for a year, your monthly Budget Billing amount is an estimate that takes into account the usage of the previous resident at your address and/or the average usage in your area. Be aware that your usage may differ from the previous resident. This may result in future changes to your Budget Billing amount.", comment: "")
            }
            return text
        case .pepco:
            return "todo"
        case .ace:
            return "todo"
        case .delmarva:
            return "todo"
        }
    }
    
    func reasonString(forIndex index: Int) -> String {
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

