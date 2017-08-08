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
    
    enum PaymentDateType {
        case onDueDate
        case beforeDueDate
    }
    
    let disposeBag = DisposeBag()
    
    private var paymentService: PaymentService

    let isFetchingAutoPayInfo = Variable(false)
    
    var accountDetail: AccountDetail
    let initialEnrollmentStatus: Variable<EnrollmentStatus>
    let enrollSwitchValue: Variable<Bool>
    let selectedWalletItem = Variable<WalletItem?>(nil)
    let expiredReason = Variable<String?>(nil)
    
    // --- Settings --- //
    var userDidChangeSettings = Variable(false)
    var userDidChangeBankAccount = Variable(false)
    
    let amountToPay = Variable<AmountType>(.amountDue)
    let whenToPay = Variable<PaymentDateType>(.onDueDate)
    let howLongForAutoPay = Variable<EffectivePeriod>(.untilCanceled)
    
    let amountNotToExceed = Variable("")
    let numberOfPayments = Variable("")
    
    var numberOfDaysBeforeDueDate = Variable("0")
    
    var autoPayUntilDate = Variable<Date?>(nil)
    // ---------------- //

    required init(paymentService: PaymentService, accountDetail: AccountDetail) {
        self.paymentService = paymentService
        self.accountDetail = accountDetail
        initialEnrollmentStatus = Variable(accountDetail.isAutoPay ? .enrolled : .unenrolled)
        enrollSwitchValue = Variable(accountDetail.isAutoPay ? true : false)
    }
    
    private func amountNotToExceedDouble() -> String {
        return String(amountNotToExceed.value.characters.filter { "0123456789".characters.contains($0) })
    }
    
    func getAutoPayInfo(onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        isFetchingAutoPayInfo.value = true
        paymentService.fetchBGEAutoPayInfo(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (autoPayInfo: BGEAutoPayInfo) in
                self.isFetchingAutoPayInfo.value = false
                
                // Expired accounts
                var isExpired = false
                if let effectiveNumberOfPayments = autoPayInfo.effectiveNumPayments, let numberOfPaymentsScheduled = autoPayInfo.numberOfPaymentsScheduled, Int(numberOfPaymentsScheduled)! >= Int(effectiveNumberOfPayments)! {
                    isExpired = true
                    let localizedString = NSLocalizedString("Enrollment expired due to AutoPay settings - you set enrollment to expire after %d payments.", comment: "")
                    self.expiredReason.value = String(format: localizedString, Int(effectiveNumberOfPayments)!)
                } else if let effectiveEndDate = autoPayInfo.effectiveEndDate, effectiveEndDate < Date() {
                    isExpired = true
                    let localizedString = NSLocalizedString("Enrollment expired due to AutoPay settings - you set enrollment to expire on %@.", comment: "")
                    self.expiredReason.value = String(format: localizedString, effectiveEndDate.mmDdYyyyString)
                } else {
                    self.expiredReason.value = nil
                }
                
                if !isExpired { // Sync up our view model with the existing AutoPay settings
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
                    if let effectivePeriod = autoPayInfo.effectivePeriod {
                        self.howLongForAutoPay.value = effectivePeriod
                    }
                    if let effectiveEndDate = autoPayInfo.effectiveEndDate {
                        self.autoPayUntilDate.value = effectiveEndDate
                    }
                    if let effectiveNumPayments = autoPayInfo.effectiveNumPayments {
                        self.numberOfPayments.value = effectiveNumPayments
                    }
                }
            
                onSuccess?()
            }, onError: { error in
                self.isFetchingAutoPayInfo.value = false
                onError?(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func enrollOrUpdate(update: Bool = false, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let daysBefore = whenToPay.value == .onDueDate ? "0" : numberOfDaysBeforeDueDate.value
        paymentService.enrollInAutoPayBGE(accountNumber: accountDetail.accountNumber, walletItemId: selectedWalletItem.value!.walletItemID, amountType: amountToPay.value, amountThreshold: amountNotToExceedDouble(), paymentDatesBeforeDue: daysBefore, effectivePeriod: howLongForAutoPay.value, effectiveEndDate: autoPayUntilDate.value, effectiveNumPayments: numberOfPayments.value, isUpdate: update)
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
    
    lazy var submitButtonEnabled: Driver<Bool> = Driver.combineLatest(self.initialEnrollmentStatus.asDriver(),
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
    
    lazy var isUnenrolling: Driver<Bool> = Driver.combineLatest(self.initialEnrollmentStatus.asDriver(), self.enrollSwitchValue.asDriver()) {
            $0 == .enrolled && !$1
        }
    
    lazy var shouldShowSettingsButton: Driver<Bool> = Driver.combineLatest(self.initialEnrollmentStatus.asDriver(), self.selectedWalletItem.asDriver(), self.isUnenrolling) {
        $0 == .enrolled || $1 != nil && !$2
    }
    
    
    func getInvalidSettingsMessage() -> String? {
        let defaultString = NSLocalizedString("Complete all required fields before returning to the AutoPay screen. Check your selected settings and complete secondary fields.", comment: "")
        
        if amountToPay.value == .upToAmount {
            if amountNotToExceed.value.isEmpty {
                return defaultString
            } else {
                if let amountDouble = Double(amountNotToExceedDouble()) {
                    if amountDouble < 0.01 || amountDouble > 9999.99 {
                        return NSLocalizedString("Complete all required fields before returning to the AutoPay screen. \"Amount Not To Exceed\" must be between $0.01 and $9,999.99", comment: "")
                    }
                }
            }
        }
        if whenToPay.value == .beforeDueDate && numberOfDaysBeforeDueDate.value == "0" {
            return defaultString
        }
        if howLongForAutoPay.value == .maxPayments && numberOfPayments.value.isEmpty {
            return defaultString
        }
        return nil
    }
    
    lazy var shouldShowWalletItem: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        return $0 != nil
    }
    
    lazy var bankAccountButtonImage: Driver<UIImage> = self.selectedWalletItem.asDriver().map {
        if $0 != nil {
            return #imageLiteral(resourceName: "opco_bank_mini")
        } else {
            return #imageLiteral(resourceName: "bank_building_mini")
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
    
    var selectedWalletItemA11yLabel: Driver<String> {
        return selectedWalletItem.asDriver().map {
            guard let walletItem = $0 else { return "" }
            
            var a11yLabel = ""
            
            if walletItem.bankOrCard == .bank {
                a11yLabel = NSLocalizedString("Bank account", comment: "")
            } else {
                a11yLabel = NSLocalizedString("Credit card", comment: "")
            }
            
            if let nicknameText = walletItem.nickName, !nicknameText.isEmpty {
                a11yLabel += ", \(nicknameText)"
            }
            
            if let last4Digits = walletItem.maskedWalletItemAccountNumber {
                a11yLabel += String(format: NSLocalizedString(", Account number ending in, %@", comment: ""), last4Digits)
            }
            
            return a11yLabel
        }
    }
    
    lazy var shouldShowExpiredReason: Driver<Bool> = self.expiredReason.asDriver().map { $0 != nil }
    
    func formatAmountNotToExceed() {
        let textStr = String(amountNotToExceed.value.characters.filter { "0123456789".characters.contains($0) })
        if let intVal = Double(textStr) {
            if intVal == 0 {
                amountNotToExceed.value = "$0.00"
            } else {
                amountNotToExceed.value = (intVal / 100).currencyString!
            }
        }
    }

}
