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
    
    var makePaymentNextButtonEnabled: Driver<Bool> {
        return shouldShowContent
    }
    
    var reviewPaymentSubmitButtonEnabled: Driver<Bool> {
        return shouldShowContent
    }
    
    var shouldShowContent: Driver<Bool> {
        return Driver.combineLatest(isFetchingWalletItems.asDriver(), isError.asDriver()).map {
            return !$0 && !$1
        }
    }
    
    var shouldShowPaymentAccountView: Driver<Bool> {
        return selectedWalletItem.asDriver().map {
            return $0 != nil
        }
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
    
    lazy var amountDueValue: Driver<String?> = self.accountDetail.asDriver().map {
        guard let netDueAmount = $0.billingInfo.netDueAmount else { return nil }
        return max(netDueAmount, 0).currencyString ?? "--"
    }
    
    lazy var dueDate: Driver<String?> = self.accountDetail.asDriver().map {
        return $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
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
