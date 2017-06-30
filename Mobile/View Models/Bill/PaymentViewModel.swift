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
    
    init(walletService: WalletService, paymentService: PaymentService, oneTouchPayService: OneTouchPayService, accountDetail: AccountDetail) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.oneTouchPayService = oneTouchPayService
        self.accountDetail = Variable(accountDetail)
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
    
}
