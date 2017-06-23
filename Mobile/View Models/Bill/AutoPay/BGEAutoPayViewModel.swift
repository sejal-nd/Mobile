//
//  BGEAutoPayViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BGEAutoPayViewModel {
    
    enum EnrollmentStatus {
        case enrolling, isEnrolled, unenrolling
    }
    
    enum AmountToPay {
        case totalAmountDue
        case amountNotToExceed
    }
    
    enum WhenToPay {
        case onDueDate
        case beforeDueDate
    }
    
    enum HowLongForAutoPay {
        case untilCanceled
        case forNumberOfPayments
        case untilDate
    }
    
    let disposeBag = DisposeBag()
    
    private var paymentService: PaymentService
    var accountDetail: AccountDetail
    let enrollmentStatus: Variable<EnrollmentStatus>
    let selectedWalletItem = Variable<WalletItem?>(nil)
    
    // --- Settings --- //
    let amountToPay = Variable<AmountType>(.amountDue)
    let whenToPay = Variable<PaymentDateType>(.onDueDate)
    let howLongForAutoPay = Variable<EffectivePeriod>(.untilCanceled)
    
    let amountNotToExceed = Variable("")
    let numberOfPayments = Variable("")
    
    var numberOfDaysBeforeDueDate = Variable("")
    
    var autoPayUntilDate = Variable("")
    
    var primaryProfile = Variable<Bool>(false)
    // ---------------- //

    required init(paymentService: PaymentService, accountDetail: AccountDetail) {
        self.paymentService = paymentService
        self.accountDetail = accountDetail
        enrollmentStatus = Variable(accountDetail.isAutoPay ? .isEnrolled : .enrolling)
    }
    
    func getAutoPayInfo(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.fetchBGEAutoPayInfo(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { billingInfo in
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    lazy var shouldShowWalletItem: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        return $0 != nil
    }
    
    lazy var bankAccountButtonImage: Driver<UIImage> = self.selectedWalletItem.asDriver().map {
        if $0 != nil {
            return #imageLiteral(resourceName: "opco_bank_mini")
        } else {
            return #imageLiteral(resourceName: "bank_building")
        }
    }
    
    lazy var walletItemAccountNumberText: Driver<String> = self.selectedWalletItem.asDriver().map {
        guard let item = $0 else { return "" }
        if let last4Digits = item.maskedWalletItemAccountNumber {
            return "**** \(last4Digits)"
        }
        return ""
    }
    
    lazy var walletItemNicknameText: Driver<String> = self.selectedWalletItem.asDriver().map {
        guard let item = $0 else { return "" }
        if let nickname = item.nickName {
            return nickname
        }
        return ""
    }
    
    
}
