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
    
    func getAutoPayInfo(onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        isFetchingAutoPayInfo.value = true
        paymentService.fetchBGEAutoPayInfo(accountNumber: AccountsStore.sharedInstance.currentAccount.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (autoPayInfo: BGEAutoPayInfo) in
                self.isFetchingAutoPayInfo.value = false
                
                // MMS - I'm so, so sorry about this
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
                
                // Expired accounts
                if let numberOfPayments = Int(autoPayInfo.effectiveNumPayments!),
                    let numberOfPaymentsScheduled = Int(autoPayInfo.numberOfPaymentsScheduled!),
                    numberOfPayments >= numberOfPaymentsScheduled {
                    let localizedString = NSLocalizedString("Enrollment expired due to AutoPay settings - you set enrollment to expire after %d payments.", comment: "")
                    self.expiredReason.value = String(format: localizedString, numberOfPaymentsScheduled)
                } else if let effectiveEndDate = autoPayInfo.effectiveEndDate, effectiveEndDate < Date() {
                    let localizedString = NSLocalizedString("Enrollment expired due to AutoPay settings - you set enrollment to expire on %@.", comment: "")
                    self.expiredReason.value = String(format: localizedString, effectiveEndDate.mmDdYyyyString)
                } else {
                    self.expiredReason.value = nil
                }
                
                onSuccess?()
            }, onError: { error in
                self.isFetchingAutoPayInfo.value = false
                onError?(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func enrollOrUpdate(update: Bool = false, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let daysBefore = whenToPay.value == .onDueDate ? "0" : numberOfDaysBeforeDueDate.value
        paymentService.enrollInAutoPayBGE(accountNumber: accountDetail.accountNumber, walletItemId: selectedWalletItem.value!.walletItemID, amountType: amountToPay.value, amountThreshold: amountNotToExceed.value, paymentDatesBeforeDue: daysBefore, effectivePeriod: howLongForAutoPay.value, effectiveEndDate: autoPayUntilDate.value, effectiveNumPayments: numberOfPayments.value, isUpdate: update)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func unenroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.unenrollFromAutoPayBGE(accountNumber: accountDetail.accountNumber)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
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
                if let amountDouble = Double(amountNotToExceed.value) {
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
    
    lazy var numberOfPaymentsLabelText: Driver<String> = self.numberOfPayments.asDriver().map {
        if $0.isEmpty {
            return NSLocalizedString("After your selected number of payments have been created, AutoPay will automatically stop and you will be responsible for restarting AutoPay or resuming manual payments on your accounts.", comment: "")
        } else {
            return NSLocalizedString("After \($0) payments have been created, AutoPay will automatically stop and you will be responsible for restarting AutoPay or resuming manual payments on your accounts.", comment: "")
        }
    }
    
    lazy var shouldShowExpiredReason: Driver<Bool> = self.expiredReason.asDriver().map { $0 != nil }
    
    func formatAmountNotToExceed() {
        let components = amountNotToExceed.value.components(separatedBy: ".")
        
        var newText = amountNotToExceed.value
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
    
        amountNotToExceed.value = newText
    }

}
