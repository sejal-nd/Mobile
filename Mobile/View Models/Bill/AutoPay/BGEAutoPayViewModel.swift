//
//  BGEAutoPayViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class BGEAutoPayViewModel {
    
    enum EnrollmentStatus {
        case enrolled, unenrolled
    }
    
    enum PaymentDateType {
        case onDueDate
        case beforeDueDate
    }
    
    let disposeBag = DisposeBag()
    
    private var paymentService: PaymentService

    let isFetchingAutoPayInfo = Variable(false)
    let isError = Variable(false)
    
    var accountDetail: AccountDetail
    let initialEnrollmentStatus: Variable<EnrollmentStatus>
    let enrollSwitchValue: Variable<Bool>
    let selectedWalletItem = Variable<WalletItem?>(nil)
    
    // --- Settings --- //
    var userDidChangeSettings = Variable(false)
    var userDidChangeBankAccount = Variable(false)
    
    let amountToPay = Variable<AmountType>(.amountDue)
    let whenToPay = Variable<PaymentDateType>(.onDueDate)
    
    let amountNotToExceed = Variable("")
    let numberOfPayments = Variable("")
    
    var numberOfDaysBeforeDueDate = Variable("0")
    // ---------------- //

    required init(paymentService: PaymentService, accountDetail: AccountDetail) {
        self.paymentService = paymentService
        self.accountDetail = accountDetail
        initialEnrollmentStatus = Variable(accountDetail.isAutoPay ? .enrolled : .unenrolled)
        enrollSwitchValue = Variable(accountDetail.isAutoPay ? true : false)
    }
    
    private func amountNotToExceedDouble() -> String {
        return String(amountNotToExceed.value.filter { "0123456789.".contains($0) })
    }
    
    func getAutoPayInfo(onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        isFetchingAutoPayInfo.value = true
        self.isError.value = false
        paymentService.fetchBGEAutoPayInfo(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (autoPayInfo: BGEAutoPayInfo) in
                guard let self = self else { return }
                self.isFetchingAutoPayInfo.value = false
                self.isError.value = false
                
                // Sync up our view model with the existing AutoPay settings
                if let walletItemId = autoPayInfo.walletItemId, let masked4 = autoPayInfo.paymentAccountLast4, let nickname = autoPayInfo.paymentAccountNickname {
                    self.selectedWalletItem.value = WalletItem.from(["walletItemID": walletItemId, "maskedWalletItemAccountNumber": masked4, "nickName": nickname])
                }
                
                if let amountType = autoPayInfo.amountType {
                    self.amountToPay.value = amountType
                }
                
                if let amountThreshold = autoPayInfo.amountThreshold {
                    self.amountNotToExceed.value = amountThreshold
                    self.formatAmountNotToExceed()
                }
                
                if let paymentDaysBeforeDue = autoPayInfo.paymentDaysBeforeDue {
                    self.numberOfDaysBeforeDueDate.value = paymentDaysBeforeDue
                    self.whenToPay.value = paymentDaysBeforeDue == "0" ? .onDueDate : .beforeDueDate
                }
                
                onSuccess?()
            }, onError: { [weak self] error in
                    guard let self = self else { return }
                    self.isFetchingAutoPayInfo.value = false
                    self.isError.value = true
                    onError?(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func enrollOrUpdate(update: Bool = false, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let daysBefore = whenToPay.value == .onDueDate ? "0" : numberOfDaysBeforeDueDate.value
        paymentService.enrollInAutoPayBGE(accountNumber: accountDetail.accountNumber,
                                          walletItemId: selectedWalletItem.value!.walletItemID,
                                          amountType: amountToPay.value,
                                          amountThreshold: amountNotToExceedDouble(),
                                          paymentDaysBeforeDue: daysBefore,
                                          isUpdate: update)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func unenroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.unenrollFromAutoPayBGE(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private(set) lazy var showBottomLabel: Driver<Bool> =
        Driver.combineLatest(self.isFetchingAutoPayInfo.asDriver(), self.initialEnrollmentStatus.asDriver()) {
            return !$0 && $1 != .enrolled
        }
    
    private(set) lazy var submitButtonEnabled: Driver<Bool> =
        Driver.combineLatest(self.initialEnrollmentStatus.asDriver(),
                             self.selectedWalletItem.asDriver(),
                             self.enrollSwitchValue.asDriver(),
                             self.userDidChangeSettings.asDriver(),
                             self.userDidChangeBankAccount.asDriver()) {
            if $0 == .unenrolled && $1 != nil { // Unenrolled with bank account selected
                return true
            }
            if $0 == .enrolled && !$2 { // Enrolled and enrollment switch toggled off
                return true
            }
            if $0 == .enrolled && $1?.walletItemID != nil && ($3 || $4) { // Enrolled with a selected wallet item and changed settings or bank
                return true
            }
            return false
        }
    
    private(set) lazy var isUnenrolling: Driver<Bool> =
        Driver.combineLatest(self.initialEnrollmentStatus.asDriver(), self.enrollSwitchValue.asDriver()) {
            $0 == .enrolled && !$1
        }
    
    private(set) lazy var shouldShowSettingsButton: Driver<Bool> =
        Driver.combineLatest(self.initialEnrollmentStatus.asDriver(),
                             self.selectedWalletItem.asDriver(),
                             self.isUnenrolling) {
            $0 == .enrolled || $1 != nil && !$2
        }
    
    private(set) lazy var shouldShowContent: Driver<Bool> = Driver.combineLatest(self.isFetchingAutoPayInfo.asDriver(), self.isError.asDriver()) {
        return !$0 && !$1
    }
    
    func getInvalidSettingsMessage() -> String? {
        let defaultString = NSLocalizedString("Complete all required fields before returning to the AutoPay screen. Check your selected settings and complete secondary fields.", comment: "")
        
        if amountToPay.value == .upToAmount {
            if amountNotToExceed.value.isEmpty {
                return defaultString
            } else {
                let minPaymentAmount = accountDetail.billingInfo.minPaymentAmount()
                let maxPaymentAmount = accountDetail.billingInfo.maxPaymentAmount(bankOrCard: .bank)
                if let amountDouble = Double(amountNotToExceedDouble()) {
                    if amountDouble < minPaymentAmount || amountDouble > maxPaymentAmount {
                        return String.localizedStringWithFormat("Complete all required fields before returning to the AutoPay screen. \"Amount Not To Exceed\" must be between %@ and %@", minPaymentAmount.currencyString, maxPaymentAmount.currencyString)
                    }
                }
            }
        }
        
        if whenToPay.value == .beforeDueDate && numberOfDaysBeforeDueDate.value == "0" {
            return defaultString
        }
        
        return nil
    }
    
    private(set) lazy var shouldShowWalletItem: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        return $0 != nil
    }
    
    private(set) lazy var bankAccountButtonImage: Driver<UIImage> = self.selectedWalletItem.asDriver().map {
        if $0 != nil {
            return #imageLiteral(resourceName: "opco_bank_mini")
        } else {
            return #imageLiteral(resourceName: "bank_building_mini")
        }
    }
    
    private(set) lazy var walletItemAccountNumberText: Driver<String> = self.selectedWalletItem.asDriver().map {
        guard let item = $0 else { return "" }
        if let last4Digits = item.maskedWalletItemAccountNumber {
            return "**** \(last4Digits)"
        }
        return ""
    }
    
    private(set) lazy var walletItemNicknameText: Driver<String> = self.selectedWalletItem.asDriver().map {
        guard let item = $0 else { return "" }
        if let nickname = item.nickName {
            return nickname
        }
        return ""
    }
    
    private(set) lazy var selectedWalletItemA11yLabel: Driver<String> = self.selectedWalletItem.asDriver().map {
        guard let walletItem = $0 else { return "" }
        
        var a11yLabel = NSLocalizedString("Bank account", comment: "")
        
        if let nicknameText = walletItem.nickName, !nicknameText.isEmpty {
            a11yLabel += ", \(nicknameText)"
        }
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            a11yLabel += String(format: NSLocalizedString(", Account number ending in, %@", comment: ""), last4Digits)
        }
        
        return a11yLabel
    }
    
    func formatAmountNotToExceed() {
        let textStr = String(amountNotToExceed.value.filter { "0123456789".contains($0) })
        if let intVal = Double(textStr) {
            if intVal == 0 {
                amountNotToExceed.value = "$0.00"
            } else {
                amountNotToExceed.value = (intVal / 100).currencyString
            }
        }
    }

}
