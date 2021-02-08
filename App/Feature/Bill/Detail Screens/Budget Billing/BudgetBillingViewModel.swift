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

    let accountDetail: AccountDetail!

    var averageMonthlyBill: String?
    
    let selectedUnenrollmentReason = BehaviorRelay(value: -1)
    
    required init(accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
    }
    
    func getBudgetBillingInfo(onSuccess: @escaping (BudgetBilling) -> Void, onError: @escaping (String) -> Void) {
        BillService.fetchBudgetBillingInfo(accountNumber: accountDetail.accountNumber) { [weak self] result in
            switch result {
            case .success(let billingInfo):
                self?.averageMonthlyBill = billingInfo.averageMonthlyBill.currencyString
                onSuccess(billingInfo)
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    func enroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        BillService.enrollBudgetBilling(accountNumber: accountDetail.accountNumber) { [weak self] result in
            switch result {
            case .success:
                NotificationCenter.default.post(name: .didChangeBudgetBillingEnrollment, object: self)
                if Configuration.shared.opco != .bge {
                    let alertPreferencesRequest = AlertPreferencesRequest(alertPreferenceRequests: [AlertPreferencesRequest.AlertRequest(isActive: true, type: "push", programName: "Budget Billing")])
                    AlertService.setAlertPreferences(accountNumber: self?.accountDetail.accountNumber ?? "", request: alertPreferencesRequest) { alertResult in
                        switch alertResult {
                        case .success:
                            dLog("Enrolled in the budget billing push notification")
                        case .failure:
                            dLog("Failed to enroll in the budget billing push notification")
                        }
                        onSuccess()
                    }
                } else {
                    onSuccess()
                }
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    func unenroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        BillService.unenrollBudgetBilling(accountNumber: accountDetail.accountNumber, reason: reasonString(forIndex: selectedUnenrollmentReason.value)) { result in
            switch result {
            case .success:
                NotificationCenter.default.post(name: .didChangeBudgetBillingEnrollment, object: self)
                onSuccess()
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    private(set) lazy var reasonForStoppingUnenrollButtonEnabled: Driver<Bool> =
        self.selectedUnenrollmentReason.asDriver().map { $0 != -1 }
    
    var footerLabelText: String? {
        switch Configuration.shared.opco {
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
        case .ace, .delmarva, .pepco:
            return NSLocalizedString("The amount above is your suggested billing amount. It may be adjusted quarterly based on your actual usage. After 12 months, the difference between your budget bill amount and actual use for the previous 12 months will be applied to your bill.", comment: "")
        }
    }
    
    func reasonString(forIndex index: Int) -> String {
        if index == 0 {
            return String(format: NSLocalizedString("Closing %@ Account", comment: ""), Configuration.shared.opco.displayString)
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

