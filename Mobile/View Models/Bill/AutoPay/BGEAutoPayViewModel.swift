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
        case enrolled, unenrolled
    }
    
    let disposeBag = DisposeBag()
    
    private var paymentService: PaymentService

    let isFetchingAutoPayInfo = Variable(false)
    
    var accountDetail: AccountDetail
    let enrollmentStatus: Variable<EnrollmentStatus>
    let enrollSwitchValue: Variable<Bool>
    let selectedWalletItem = Variable<WalletItem?>(nil)
    
    // --- Settings --- //
    let amountToPay = Variable<AmountType>(.amountDue)
    let whenToPay = Variable<PaymentDateType>(.onDueDate)
    let howLongForAutoPay = Variable<EffectivePeriod>(.untilCanceled)
    
    let amountNotToExceed = Variable("")
    let numberOfPayments = Variable("")
    
    var numberOfDaysBeforeDueDate = Variable("")
    
    var autoPayUntilDate = Variable<Date?>(nil)
    
    var primaryProfile = Variable<Bool>(false)
    // ---------------- //

    required init(paymentService: PaymentService, accountDetail: AccountDetail) {
        self.paymentService = paymentService
        self.accountDetail = accountDetail
        enrollmentStatus = Variable(accountDetail.isAutoPay ? .enrolled : .unenrolled)
        enrollSwitchValue = Variable(accountDetail.isAutoPay ? true : false)
    }
    
    func getAutoPayInfo(onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        isFetchingAutoPayInfo.value = true
        paymentService.fetchBGEAutoPayInfo(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (autoPayInfo: BGEAutoPayInfo) in
                self.isFetchingAutoPayInfo.value = false
                
                // MMS - I'm so, so sorry about this
                if let masked4 = autoPayInfo.paymentAccountLast4, let nickname = autoPayInfo.paymentAccountNickname {
                    self.selectedWalletItem.value = WalletItem.from(["maskedWalletItemAccountNumber": masked4, "nickName": nickname])
                }
                if let amountType = autoPayInfo.amountType {
                    self.amountToPay.value = amountType
                }
                if let amountThreshold = autoPayInfo.amountThreshold {
                    self.amountNotToExceed.value = amountThreshold
                }
                if let paymentDateType = autoPayInfo.paymentDateType {
                    self.whenToPay.value = paymentDateType
                }
                if let paymentDaysBeforeDue = autoPayInfo.paymentDaysBeforeDue {
                    self.numberOfDaysBeforeDueDate.value = paymentDaysBeforeDue
                }
                if let effectivePeriod = autoPayInfo.effectivePeriod {
                    self.howLongForAutoPay.value = effectivePeriod
                }
                if let effectiveEndDate = autoPayInfo.effectiveEndDate {
                    self.autoPayUntilDate.value = effectiveEndDate
                }
                if let effectiveNumPayments = autoPayInfo.effectiveNumPayments {
                    self.numberOfPayments.value = effectiveNumPayments
                }
                onSuccess?()
            }, onError: { error in
                self.isFetchingAutoPayInfo.value = false
                onError?(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func enrollOrUpdate(update: Bool = false, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.enrollInAutoPayBGE(accountNumber: accountDetail.accountNumber, walletItemId: selectedWalletItem.value!.walletItemID, amountType: amountToPay.value, amountThreshold: amountNotToExceed.value, paymentDateType: whenToPay.value, paymentDatesBeforeDue: numberOfDaysBeforeDueDate.value, effectivePeriod: howLongForAutoPay.value, effectiveEndDate: autoPayUntilDate.value, effectiveNumPayments: numberOfPayments.value, isUpdate: update)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func unenroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.unenrollFromAutoPayBGE(accountNumber: accountDetail.accountNumber, paymentAccount: (selectedWalletItem.value?.nickName)!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(enrollmentStatus.asObservable(), selectedWalletItem.asObservable(), enrollSwitchValue.asObservable()) {
            if $0 == .unenrolled && $1 != nil { // Unenrolled with bank account selected
                return true
            }
            if $0 == .enrolled && !$2 { // Enrolled and enrollment switch toggled off
                return true
            }
            return false
        }
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
