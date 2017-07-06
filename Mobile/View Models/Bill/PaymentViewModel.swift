//
//  PaymentViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/30/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class PaymentViewModel {
    let disposeBag = DisposeBag()
    
    private var walletService: WalletService
    private var paymentService: PaymentService
    private var oneTouchPayService: OneTouchPayService
    
    let accountDetail: Variable<AccountDetail>
    
    let isFetchingWalletItems = Variable(false)
    let isError = Variable(false)
    
    let walletItems = Variable<[WalletItem]?>(nil)
    let selectedWalletItem = Variable<WalletItem?>(nil)
    
    let amountDue = Variable<Double>(0)
    let paymentAmount = Variable("")
    let paymentDate: Variable<Date>
    
    let reviewPaymentSwitchValue = Variable(false)
    
    init(walletService: WalletService, paymentService: PaymentService, oneTouchPayService: OneTouchPayService, accountDetail: AccountDetail) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.oneTouchPayService = oneTouchPayService
        self.accountDetail = Variable(accountDetail)
        self.paymentDate = Variable((accountDetail.billingInfo.dueByDate ?? nil)!)
    }
    
    func fetchWalletItems(onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        isFetchingWalletItems.value = true
        isError.value = false
        walletService.fetchWalletItems()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItems in
                // Default to One Touch Pay item
                if self.selectedWalletItem.value == nil {
                    if let otpItem = self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: self.accountDetail.value.customerInfo.number) {
                        for item in walletItems {
                            if item == otpItem {
                                self.selectedWalletItem.value = item
                                break
                            }
                        }
                    }
                }
                
                // If no OTP item, default to first wallet item
                if self.selectedWalletItem.value == nil && walletItems.count > 0 {
                    self.selectedWalletItem.value = walletItems[0]
                }
                
                self.isFetchingWalletItems.value = false
                self.walletItems.value = walletItems
                onSuccess?()
            }, onError: { err in
                self.isFetchingWalletItems.value = false
                self.isError.value = true
                onError?(err.localizedDescription)
            }).addDisposableTo(disposeBag)
    }
    
    // MARK: - Make Payment Drivers
    
    var makePaymentNextButtonEnabled: Driver<Bool> {
        return shouldShowContent
    }
    
    lazy var isCashOnlyUser: Driver<Bool> = self.accountDetail.asDriver().map {
        return $0.isCashOnly
    }
    
    var shouldShowContent: Driver<Bool> {
        return Driver.combineLatest(isFetchingWalletItems.asDriver(), isError.asDriver()).map {
            return !$0 && !$1
        }
    }
    
    lazy var shouldShowPaymentAccountView: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        return $0 != nil
    }
    
    lazy var hasWalletItems: Driver<Bool> = self.walletItems.asDriver().map {
        guard let walletItems: [WalletItem] = $0 else { return false }
        return walletItems.count > 0
    }
    
    var shouldShowPaymentAmountTextField: Driver<Bool> {
        return hasWalletItems
    }
    
    var shouldShowPaymentDateView: Driver<Bool> {
        return hasWalletItems
    }
    
    var shouldShowStickyFooterView: Driver<Bool> {
        return hasWalletItems
    }
    
    lazy var selectedWalletItemImage: Driver<UIImage?> = self.selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return nil }
        if walletItem.paymentCategoryType == .check {
            return #imageLiteral(resourceName: "opco_bank_mini")
        } else {
            return #imageLiteral(resourceName: "opco_credit_card_mini")
        }
    }
    
    lazy var selectedWalletItemMaskedAccountString: Driver<String> = self.selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return "" }
        return "**** \(walletItem.maskedWalletItemAccountNumber ?? "")"
    }
    
    lazy var selectedWalletItemNickname: Driver<String> = self.selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return "" }
        return walletItem.nickName ?? ""
    }
    
    var convenienceFee: Driver<Double?> {
        return Driver.combineLatest(accountDetail.asDriver(), selectedWalletItem.asDriver()).map {
            if let walletItem = $1 {
                if walletItem.paymentCategoryType == .credit || walletItem.paymentCategoryType == .debit {
                    return $0.billingInfo.convenienceFee
                }
            }
            return nil
        }
    }
    
    lazy var amountDueValue: Driver<String?> = self.accountDetail.asDriver().map {
        guard let netDueAmount = $0.billingInfo.netDueAmount else { return nil }
        return max(netDueAmount, 0).currencyString ?? "--"
    }
    
    lazy var dueDate: Driver<String?> = self.accountDetail.asDriver().map {
        return $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
    }
    
    var shouldShowAddBankAccount: Driver<Bool> {
        return Driver.combineLatest(isCashOnlyUser, hasWalletItems).map {
            return !$0 && !$1
        }
    }
    
    var shouldShowAddCreditCard: Driver<Bool> {
        return hasWalletItems.map(!)
    }
    
    var isFixedPaymentDate: Driver<Bool> {
        return Driver.combineLatest(accountDetail.asDriver(), selectedWalletItem.asDriver()).map {
            if let walletItem = $1 {
                if walletItem.paymentCategoryType == .credit || walletItem.paymentCategoryType == .debit {
                    return true
                }
            }
            if $0.billingInfo.pastDueAmount ?? 0 > 0 { // Past due, avoid shutoff
                return true
            }
            if ($0.billingInfo.restorationAmount ?? 0 > 0 || $0.billingInfo.amtDpaReinst ?? 0 > 0) || $0.isCutOutNonPay { // Cut for non-pay
                return true
            }
            return false
        }
    }
    
    lazy var isFixedPaymentDatePastDue: Driver<Bool> = self.accountDetail.asDriver().map {
        return $0.billingInfo.pastDueAmount ?? 0 > 0
    }
    
    lazy var fixedPaymentDateString: Driver<String?> = self.paymentDate.asDriver().map {
        return $0.mmDdYyyyString
    }
    
    var walletFooterLabelText: String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.", comment: "")
        case .comEd, .peco:
            return NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
    }
    
    // MARK: - Review Payment Drivers
    
    var reviewPaymentSubmitButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(isOverpaying.asDriver(), reviewPaymentSwitchValue.asDriver()).map {
            if Environment.sharedInstance.opco == .bge {
                if $0 { // If overpaying, enable submit button only when switch is toggled
                    return $1
                } else {
                    return true
                }
            } else { // ComEd/PECO only enabled after toggling switch
                return $1
            }
        }
    }
    
    lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return false }
        return walletItem.paymentCategoryType == .credit || walletItem.paymentCategoryType == .debit
    }
    
    var isOverpaying: Driver<Bool> {
        return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver().map { return Double($0) ?? 0 }).map {
            return $1 > $0
        }
    }
    
    lazy var shouldShowOverpaymentLabel: Driver<Bool> = self.isOverpaying.map {
        return Environment.sharedInstance.opco == .bge && $0
    }
    
    var shouldShowSwitchView: Driver<Bool> {
        return isOverpaying.map {
            if Environment.sharedInstance.opco == .bge { // On BGE, the switch view is just for confirming overpayment
                return $0
            } else { // On ComEd/PECO, it's always shown for the terms and conditions agreement
                return true
            }
        }
    }
    
    var switchViewLabelText: String {
        if Environment.sharedInstance.opco == .bge {
            return "Yes, I acknowledge I am scheduling a payment for more than is currently due on my account."
        } else {
            return "Yes, I have read, understand, and agree to the terms and conditions provided below:"
        }
    }
    
    var shouldShowTermsConditionsButton: Driver<Bool> {
        return Driver.just(Environment.sharedInstance.opco != .bge)
    }
    
    var shouldShowBillMatrixView: Driver<Bool> {
        return Driver.just(Environment.sharedInstance.opco != .bge)
    }
    
    lazy var paymentAmountDisplayString: Driver<String> = self.paymentAmount.asDriver().map {
        return "$\($0)"
    }
    
    lazy var convenienceFeeDisplayString: Driver<String> = self.convenienceFee.map {
        guard let fee = $0 else { return "" }
        return fee.currencyString ?? ""
    }
    
    var totalPaymentDisplayString: Driver<String> {
        return Driver.combineLatest(paymentAmount.asDriver().map { return Double($0) ?? 0 }, convenienceFee.asDriver().map { return $0 ?? 0 }).map {
            return ($0 + $1).currencyString ?? ""
        }
    }
    
    
    // MARK: - Random functions
    
    
    func formatPaymentAmount() {
        let components = paymentAmount.value.components(separatedBy: ".")
        
        var newText = paymentAmount.value
        if components.count == 2 {
            let decimal = components[1]
            if decimal.characters.count == 0 {
                newText += "00"
            } else if decimal.characters.count == 1 {
                newText += "0"
            }
        } else if components.count == 1 && components[0].characters.count > 0 {
            newText += ".00"
        } else {
            newText = "0.00"
        }
        
        paymentAmount.value = newText
    }
    
}
