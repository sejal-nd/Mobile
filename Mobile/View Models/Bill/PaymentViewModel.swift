//
//  PaymentViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 6/30/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import UIKit

class PaymentViewModel {
    let disposeBag = DisposeBag()
    
    private var walletService: WalletService
    private var paymentService: PaymentService
    
    let accountDetail: Variable<AccountDetail>
    
    let isFetching = Variable(false)
    let isError = Variable(false)
    
    let walletItems = Variable<[WalletItem]?>(nil)
    let selectedWalletItem = Variable<WalletItem?>(nil)
    let wouldBeSelectedWalletItemIsExpired = Variable(false)
    let cvv = Variable("")
    
    let amountDue: Variable<Double>
    let paymentAmount: Variable<String>
    let paymentDate: Variable<Date>
    
    let termsConditionsSwitchValue = Variable(false)
    let overpayingSwitchValue = Variable(false)
    let activeSeveranceSwitchValue = Variable(false)
    
    let addBankFormViewModel: AddBankFormViewModel!
    let addCardFormViewModel: AddCardFormViewModel!
    let inlineCard = Variable(false)
    let inlineBank = Variable(false)
    
    var oneTouchPayItem: WalletItem?
    
    let paymentDetail = Variable<PaymentDetail?>(nil)
    let paymentId = Variable<String?>(nil)
    let allowEdits = Variable(true)
    let allowDeletes = Variable(false)
    
    init(walletService: WalletService, paymentService: PaymentService, accountDetail: AccountDetail, addBankFormViewModel: AddBankFormViewModel, addCardFormViewModel: AddCardFormViewModel, paymentDetail: PaymentDetail?, billingHistoryItem: BillingHistoryItem?) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.accountDetail = Variable(accountDetail)
        self.addBankFormViewModel = addBankFormViewModel
        self.addCardFormViewModel = addCardFormViewModel
        self.paymentDetail.value = paymentDetail
        if let billingHistoryItem = billingHistoryItem {
            self.paymentId.value = billingHistoryItem.paymentId
            self.allowEdits.value = billingHistoryItem.flagAllowEdits
            self.allowDeletes.value = billingHistoryItem.flagAllowDeletes
        }
        
        self.paymentDate = Variable(Date()) // May be updated later...see computeDefaultPaymentDate()

        amountDue = Variable(accountDetail.billingInfo.netDueAmount ?? 0)
        
        paymentAmount = Variable("")
        if let netDueAmount = accountDetail.billingInfo.netDueAmount, netDueAmount > 0 && !showSelectPaymentAmount {
            paymentAmount.value = String(format: "%.02f", netDueAmount)
        }
        formatPaymentAmount()
    }
    
    // MARK: - Service Calls
    
    func fetchWalletItems() -> Observable<Void> {
        return walletService.fetchWalletItems()
            .map { walletItems in
                self.walletItems.value = walletItems
                self.oneTouchPayItem = walletItems.first(where: { $0.isDefault == true })
                
                let nicknamesInWallet = walletItems.map { $0.nickName ?? "" }.filter { !$0.isEmpty }
                self.addBankFormViewModel.nicknamesInWallet = nicknamesInWallet
                self.addCardFormViewModel.nicknamesInWallet = nicknamesInWallet
            }
    }
    
    func fetchPaymentDetails(paymentId: String) -> Observable<Void> {
        return paymentService.fetchPaymentDetails(accountNumber: accountDetail.value.accountNumber, paymentId: paymentId).map { paymentDetail in
            self.paymentDetail.value = paymentDetail
        }
    }
    
    func computeDefaultPaymentDate() {
        let now = Date()
        
        switch Environment.shared.opco {
        case .comEd, .peco:
            paymentDate.value = now
        case .bge:
            let startOfTodayDate = Calendar.opCo.startOfDay(for: now)
            let tomorrow =  Calendar.opCo.date(byAdding: .day, value: 1, to: startOfTodayDate)!
            
            if Calendar.opCo.component(.hour, from: Date()) >= 20 &&
                !accountDetail.value.isActiveSeverance {
                self.paymentDate.value = tomorrow
            }
            
            let isFixedPaymentDate = fixedPaymentDateLogic(accountDetail: accountDetail.value, cardWorkflow: false, inlineCard: false, saveBank: true, saveCard: true, allowEdits: allowEdits.value)
            if !accountDetail.value.isActiveSeverance && !isFixedPaymentDate {
                self.paymentDate.value = Calendar.opCo.component(.hour, from: Date()) < 20 ? now: tomorrow
            } else if let dueDate = accountDetail.value.billingInfo.dueByDate {
                if dueDate >= now && !isFixedPaymentDate {
                    self.paymentDate.value = dueDate
                }
            }
        }
    }
    
    func fetchData(onSuccess: (() -> ())?, onError: (() -> ())?) {
        var observables = [fetchWalletItems()]
        
        if let paymentId = paymentId.value, paymentDetail.value == nil {
            observables.append(fetchPaymentDetails(paymentId: paymentId))
        }
        
        isFetching.value = true
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.isFetching.value = false
                
                self.computeDefaultPaymentDate()
                
                if let walletItems = self.walletItems.value, self.selectedWalletItem.value == nil {
                    if let paymentDetail = self.paymentDetail.value, self.paymentId.value != nil { // Modifiying Payment
                        self.paymentAmount.value = String(format: "%.02f", paymentDetail.paymentAmount)
                        self.formatPaymentAmount()
                        self.paymentDate.value = paymentDetail.paymentDate!
                        for item in walletItems {
                            if item.walletItemID == paymentDetail.walletItemId {
                                self.selectedWalletItem.value = item
                                break
                            }
                        }
                    } else {
                        if Environment.shared.opco == .bge && !self.accountDetail.value.isResidential {
                            // Default to One Touch Pay item IF it's not a VISA credit card
                            if let otpItem = self.oneTouchPayItem {
                                if otpItem.bankOrCard == .bank {
                                    self.selectedWalletItem.value = otpItem
                                } else if let cardIssuer = otpItem.cardIssuer, cardIssuer != "Visa" {
                                    self.selectedWalletItem.value = otpItem
                                }
                            } else if walletItems.count > 0 { // If no OTP item, default to first non-VISA wallet item
                                for item in walletItems {
                                    if item.bankOrCard == .bank {
                                        self.selectedWalletItem.value = item
                                    } else if let cardIssuer = item.cardIssuer, cardIssuer != "Visa" {
                                        self.selectedWalletItem.value = item
                                        break
                                    }
                                }
                            }
                        } else if self.accountDetail.value.isCashOnly {
                            // Default to One Touch Pay item IF it's a credit card
                            if let otpItem = self.oneTouchPayItem {
                                if otpItem.bankOrCard == .card {
                                    self.selectedWalletItem.value = otpItem
                                }
                            } else if walletItems.count > 0 { // If no OTP item, default to first card wallet item
                                for item in walletItems {
                                    if item.bankOrCard == .card {
                                        self.selectedWalletItem.value = item
                                        break
                                    }
                                }
                            }
                        } else {
                            // Default to One Touch Pay item
                            if let otpItem = self.oneTouchPayItem {
                                self.selectedWalletItem.value = otpItem
                            } else if walletItems.count > 0 { // If no OTP item, default to first wallet item
                                self.selectedWalletItem.value = walletItems[0]
                            }
                        }
                    }
                    if let walletItem = self.selectedWalletItem.value, walletItem.isExpired {
                        self.selectedWalletItem.value = nil
                        self.wouldBeSelectedWalletItemIsExpired.value = true
                    }
                }
                onSuccess?()
            }, onError: { [weak self] _ in
                self?.isFetching.value = false
                self?.isError.value = true
                onError?()
            }).disposed(by: disposeBag)
    }
    
    func schedulePayment(onDuplicate: @escaping (String, String) -> Void, onSuccess: @escaping () -> Void, onError: @escaping (ServiceError) -> Void) {
        if inlineBank.value {
            scheduleInlineBankPayment(onDuplicate: onDuplicate, onSuccess: onSuccess, onError: onError)
        } else if inlineCard.value {
            scheduleInlineCardPayment(onDuplicate: onDuplicate, onSuccess: onSuccess, onError: onError)
        } else { // Existing wallet item
            self.isFixedPaymentDate.asObservable().single().subscribe(onNext: { [weak self] isFixed in
                guard let self = self else { return }
                let paymentType: PaymentType = self.selectedWalletItem.value!.bankOrCard == .bank ? .check : .credit
                var paymentDate = self.paymentDate.value
                if isFixed {
                    paymentDate = Date()
                }
                
                let payment = Payment(accountNumber: self.accountDetail.value.accountNumber,
                                      existingAccount: true,
                                      saveAccount: false,
                                      maskedWalletAccountNumber: self.selectedWalletItem.value!.maskedWalletItemAccountNumber!,
                                      paymentAmount: self.paymentAmountDouble(),
                                      paymentType: paymentType,
                                      paymentDate: paymentDate,
                                      walletId: AccountsStore.shared.customerIdentifier,
                                      walletItemId: self.selectedWalletItem.value!.walletItemID!,
                                      cvv: self.cvv.value)
                
                self.paymentService.schedulePayment(payment: payment)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        onSuccess()
                    }, onError: { err in
                        onError(err as! ServiceError)
                    }).disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
        }
    }
    
    private func paymentAmountDouble() -> Double {
        return Double(String(paymentAmount.value.filter { "0123456789.".contains($0) })) ?? 0
    }
    
    private func scheduleInlineBankPayment(onDuplicate: @escaping (String, String) -> Void, onSuccess: @escaping () -> Void, onError: @escaping (ServiceError) -> Void) {
        var accountType: String?
        if Environment.shared.opco == .bge {
            accountType = addBankFormViewModel.selectedSegmentIndex.value == 0 ? "checking" : "saving"
        }
        let accountName: String? = addBankFormViewModel.accountHolderName.value.isEmpty ? nil : addBankFormViewModel.accountHolderName.value
        let nickname: String? = addBankFormViewModel.nickname.value.isEmpty ? nil : addBankFormViewModel.nickname.value
        
        let bankAccount = BankAccount(bankAccountNumber: addBankFormViewModel.accountNumber.value,
                                      routingNumber: addBankFormViewModel.routingNumber.value,
                                      accountNickname: nickname,
                                      accountType: accountType,
                                      accountName: accountName,
                                      oneTimeUse: !addBankFormViewModel.saveToWallet.value)
        
        walletService
            .addBankAccount(bankAccount, forCustomerNumber: AccountsStore.shared.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] walletItemResult in
                guard let self = self else { return }
                
                let otp = self.addBankFormViewModel.oneTouchPay.value
                
                if self.addBankFormViewModel.saveToWallet.value {
                    Analytics.log(event: .eCheckAddNewWallet, dimensions: [.otpEnabled: otp ? "enabled" : "disabled"])
                }
                
                if otp {
                    self.enableOneTouchPay(walletItemID: walletItemResult.walletItemId, onSuccess: nil, onError: nil)
                }
                
                self.isFixedPaymentDate.asObservable().single().subscribe(onNext: { [weak self] isFixed in
                    guard let self = self else { return }
                    
                    let paymentType: PaymentType = .check
                    var paymentDate = self.paymentDate.value
                    if isFixed {
                        paymentDate = Date()
                    }
                    
                    let accountNum = self.addBankFormViewModel.accountNumber.value
                    let maskedAccountNumber = accountNum[accountNum.index(accountNum.endIndex, offsetBy: -4)...]
                    
                    let payment = Payment(accountNumber: self.accountDetail.value.accountNumber, existingAccount: false, saveAccount: self.addBankFormViewModel.saveToWallet.value, maskedWalletAccountNumber: String(maskedAccountNumber), paymentAmount: self.paymentAmountDouble(), paymentType: paymentType, paymentDate: paymentDate, walletId: AccountsStore.shared.customerIdentifier, walletItemId: walletItemResult.walletItemId, cvv: nil)
                    self.paymentService.schedulePayment(payment: payment)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { _ in
                            onSuccess()
                        }, onError: { [weak self] err in
                            guard let self = self else { return }
                            if !self.addBankFormViewModel.saveToWallet.value {
                                // Rollback the wallet add
                                self.walletService.deletePaymentMethod(walletItem: WalletItem.from(["walletItemID": walletItemResult.walletItemId])!)
                                    .subscribe()
                                    .disposed(by: self.disposeBag)
                            }
                            onError(err as! ServiceError)
                        }).disposed(by: self.disposeBag)
                }).disposed(by: self.disposeBag)
            }, onError: { (error: Error) in
                let serviceError = error as! ServiceError
                if serviceError.serviceCode == ServiceErrorCode.dupPaymentAccount.rawValue {
                    onDuplicate(NSLocalizedString("Duplicate Bank Account", comment: ""), error.localizedDescription)
                } else {
                    onError(error as! ServiceError)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func scheduleInlineCardPayment(onDuplicate: @escaping (String, String) -> Void, onSuccess: @escaping () -> Void, onError: @escaping (ServiceError) -> Void) {
        let card = CreditCard(cardNumber: addCardFormViewModel.cardNumber.value, securityCode: addCardFormViewModel.cvv.value, cardHolderName: addCardFormViewModel.nameOnCard.value, expirationMonth: addCardFormViewModel.expMonth.value, expirationYear: addCardFormViewModel.expYear.value, postalCode: addCardFormViewModel.zipCode.value, nickname: addCardFormViewModel.nickname.value)
        
        if Environment.shared.opco == .bge && !addCardFormViewModel.saveToWallet.value {
            self.isFixedPaymentDate.asObservable().single().subscribe(onNext: { [weak self] isFixed in
                guard let self = self else { return }
                var paymentDate = self.paymentDate.value
                if isFixed {
                    paymentDate = Date()
                }
                self.paymentService.scheduleBGEOneTimeCardPayment(accountNumber: self.accountDetail.value.accountNumber, paymentAmount: self.paymentAmountDouble(), paymentDate: paymentDate, creditCard: card)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        onSuccess()
                    }, onError: { err in
                        onError(err as! ServiceError)
                    }).disposed(by: self.disposeBag)
            }).disposed(by: self.disposeBag)
            
        } else {
            walletService
                .addCreditCard(card, forCustomerNumber: AccountsStore.shared.customerIdentifier)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] walletItemResult in
                    guard let self = self else { return }
                    
                    let otp = self.addCardFormViewModel.oneTouchPay.value
                    Analytics.log(event: .cardAddNewWallet, dimensions: [.otpEnabled: otp ? "enabled" : "disabled"])
                    
                    if otp {
                        self.enableOneTouchPay(walletItemID: walletItemResult.walletItemId, onSuccess: nil, onError: nil)
                    }
                    
                    self.isFixedPaymentDate.asObservable().single().subscribe(onNext: { [weak self] isFixed in
                        guard let self = self else { return }
                        
                        let paymentType: PaymentType = .credit
                        var paymentDate = self.paymentDate.value
                        if isFixed {
                            paymentDate = Date()
                        }
                        
                        let cardNum = self.addCardFormViewModel.cardNumber.value
                        let maskedAccountNumber = cardNum[cardNum.index(cardNum.endIndex, offsetBy: -4)...]
                        
                        let payment = Payment(accountNumber: self.accountDetail.value.accountNumber,
                                              existingAccount: false,
                                              saveAccount: self.addCardFormViewModel.saveToWallet.value,
                                              maskedWalletAccountNumber: String(maskedAccountNumber),
                                              paymentAmount: self.paymentAmountDouble(),
                                              paymentType: paymentType,
                                              paymentDate: paymentDate,
                                              walletId: AccountsStore.shared.customerIdentifier,
                                              walletItemId: walletItemResult.walletItemId,
                                              cvv: self.addCardFormViewModel.cvv.value)
                        
                        self.paymentService.schedulePayment(payment: payment)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { _ in
                                onSuccess()
                            }, onError: { [weak self] err in
                                guard let self = self else { return }
                                if !self.addCardFormViewModel.saveToWallet.value {
                                    // Rollback the wallet add
                                    self.walletService.deletePaymentMethod(walletItem: WalletItem.from(["walletItemID": walletItemResult.walletItemId])!)
                                        .subscribe()
                                        .disposed(by: self.disposeBag)
                                }
                                onError(err as! ServiceError)
                            }).disposed(by: self.disposeBag)
                    }).disposed(by: self.disposeBag)
                    
                }, onError: { error in
                    let serviceError = error as! ServiceError
                    if serviceError.serviceCode == ServiceErrorCode.dupPaymentAccount.rawValue {
                        onDuplicate(NSLocalizedString("Duplicate Card", comment: ""), error.localizedDescription)
                    } else {
                        onError(error as! ServiceError)
                    }
                })
                .disposed(by: disposeBag)
        }
    }
    
    func enableOneTouchPay(walletItemID: String, onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        walletService.setOneTouchPayItem(walletItemId: walletItemID,
                                         walletId: nil,
                                         customerId: AccountsStore.shared.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess?()
            }, onError: { err in
                onError?(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func cancelPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var bankOrCard: BankOrCard?
        if let selectedWalletItem = selectedWalletItem.value {
            bankOrCard = selectedWalletItem.bankOrCard
        }
        
        paymentService.cancelPayment(accountNumber: accountDetail.value.accountNumber, paymentId: paymentId.value!, bankOrCard: bankOrCard, paymentDetail: paymentDetail.value!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func modifyPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        self.isFixedPaymentDate.asObservable().single().subscribe(onNext: { [weak self] isFixed in
            guard let self = self else { return }
            let paymentType: PaymentType = self.selectedWalletItem.value!.bankOrCard == .bank ? .check : .credit
            var paymentDate = self.paymentDate.value
            if isFixed {
                paymentDate = Date()
            }
            let payment = Payment(accountNumber: self.accountDetail.value.accountNumber, existingAccount: true, saveAccount: false, maskedWalletAccountNumber: self.selectedWalletItem.value!.maskedWalletItemAccountNumber!, paymentAmount: self.paymentAmountDouble(), paymentType: paymentType, paymentDate: paymentDate, walletId: AccountsStore.shared.customerIdentifier, walletItemId: self.selectedWalletItem.value!.walletItemID!, cvv: self.cvv.value)
            self.paymentService.updatePayment(paymentId: self.paymentId.value!, payment: payment)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    onSuccess()
                }, onError: { err in
                    onError(err.localizedDescription)
                }).disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Shared Drivers
    
    private(set) lazy var bankWorkflow: Driver<Bool> = Driver.combineLatest(self.selectedWalletItem.asDriver(), self.inlineBank.asDriver(), self.inlineCard.asDriver())
    {
        if $2 {
            return false
        }
        if $1 {
            return true
        }
        guard let walletItem = $0 else { return false }
        return walletItem.bankOrCard == .bank
    }
    
    private(set) lazy var cardWorkflow: Driver<Bool> = Driver.combineLatest(self.selectedWalletItem.asDriver(), self.inlineCard.asDriver(), self.inlineBank.asDriver())
    {
        if $2 {
            return false
        }
        if $1 {
            return true
        }
        guard let walletItem = $0 else { return false }
        return walletItem.bankOrCard == .card
    }
    
    // MARK: - Inline Bank Validation
    
    private(set) lazy var saveToWalletBankFormValidBGE: Driver<Bool> = Driver.combineLatest([self.addBankFormViewModel.accountHolderNameHasText,
                                                                                             self.addBankFormViewModel.accountHolderNameIsValid,
                                                                                             self.addBankFormViewModel.routingNumberIsValid,
                                                                                             self.addBankFormViewModel.accountNumberHasText,
                                                                                             self.addBankFormViewModel.accountNumberIsValid,
                                                                                             self.addBankFormViewModel.confirmAccountNumberMatches,
                                                                                             self.addBankFormViewModel.nicknameHasText,
                                                                                             self.addBankFormViewModel.nicknameErrorString.map{ $0 == nil }])
    { !$0.contains(false) }
    
    private(set) lazy var saveToWalletBankFormValidComEdPECO: Driver<Bool> = Driver.combineLatest([self.addBankFormViewModel.routingNumberIsValid,
                                                                                                   self.addBankFormViewModel.accountNumberHasText,
                                                                                                   self.addBankFormViewModel.accountNumberIsValid,
                                                                                                   self.addBankFormViewModel.confirmAccountNumberMatches,
                                                                                                   self.addBankFormViewModel.nicknameErrorString.map{ $0 == nil }])
    { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletBankFormValidBGE: Driver<Bool> = Driver.combineLatest([self.addBankFormViewModel.accountHolderNameHasText,
                                                                                               self.addBankFormViewModel.accountHolderNameIsValid,
                                                                                               self.addBankFormViewModel.routingNumberIsValid,
                                                                                               self.addBankFormViewModel.accountNumberHasText,
                                                                                               self.addBankFormViewModel.accountNumberIsValid,
                                                                                               self.addBankFormViewModel.confirmAccountNumberMatches])
    { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletBankFormValidComEdPECO: Driver<Bool> = Driver.combineLatest([self.addBankFormViewModel.routingNumberIsValid,
                                                                                                     self.addBankFormViewModel.accountNumberHasText,
                                                                                                     self.addBankFormViewModel.accountNumberIsValid,
                                                                                                     self.addBankFormViewModel.confirmAccountNumberMatches])
    { !$0.contains(false) }
    
    // MARK: - Inline Card Validation
    
    private(set) lazy var bgeCommercialUserEnteringVisa: Driver<Bool> = Driver.combineLatest(self.addCardFormViewModel.cardNumber.asDriver(),
                                                                                             self.accountDetail.asDriver())
    {
        if Environment.shared.opco == .bge && !$1.isResidential {
            let characters = Array($0)
            if characters.count >= 1 {
                return characters[0] == "4"
            }
        }
        return false
    }
    
    private(set) lazy var saveToWalletCardFormValidBGE: Driver<Bool> = Driver
        .combineLatest([self.addCardFormViewModel.nameOnCardHasText,
                        self.addCardFormViewModel.cardNumberHasText,
                        self.addCardFormViewModel.cardNumberIsValid,
                        self.bgeCommercialUserEnteringVisa.map(!),
                        self.addCardFormViewModel.expMonthIs2Digits,
                        self.addCardFormViewModel.expMonthIsValidMonth,
                        self.addCardFormViewModel.expYearIs4Digits,
                        self.addCardFormViewModel.expYearIsNotInPast,
                        self.addCardFormViewModel.cvvIsCorrectLength,
                        self.addCardFormViewModel.zipCodeIs5Digits,
                        self.addCardFormViewModel.nicknameHasText,
                        self.addCardFormViewModel.nicknameErrorString.map{ $0 == nil }])
        .map { !$0.contains(false) }
        .asDriver(onErrorJustReturn: false)
    
    private(set) lazy var saveToWalletCardFormValidComEdPECO: Driver<Bool> = Driver.combineLatest([self.addCardFormViewModel.cardNumberHasText,
                                                                                                   self.addCardFormViewModel.cardNumberIsValid,
                                                                                                   self.addCardFormViewModel.expMonthIs2Digits,
                                                                                                   self.addCardFormViewModel.expMonthIsValidMonth,
                                                                                                   self.addCardFormViewModel.expYearIs4Digits,
                                                                                                   self.addCardFormViewModel.expYearIsNotInPast,
                                                                                                   self.addCardFormViewModel.cvvIsCorrectLength,
                                                                                                   self.addCardFormViewModel.zipCodeIs5Digits,
                                                                                                   self.addCardFormViewModel.nicknameErrorString.map{ $0 == nil }])
    { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletCardFormValidBGE: Driver<Bool> = Driver.combineLatest([self.addCardFormViewModel.nameOnCardHasText,
                                                                                               self.addCardFormViewModel.cardNumberHasText,
                                                                                               self.addCardFormViewModel.cardNumberIsValid,
                                                                                               self.bgeCommercialUserEnteringVisa.map(!),
                                                                                               self.addCardFormViewModel.expMonthIs2Digits,
                                                                                               self.addCardFormViewModel.expMonthIsValidMonth,
                                                                                               self.addCardFormViewModel.expYearIs4Digits,
                                                                                               self.addCardFormViewModel.expYearIsNotInPast,
                                                                                               self.addCardFormViewModel.cvvIsCorrectLength,
                                                                                               self.addCardFormViewModel.zipCodeIs5Digits])
    { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletCardFormValidComEdPECO: Driver<Bool> = Driver.combineLatest([self.addCardFormViewModel.cardNumberHasText,
                                                                                                     self.addCardFormViewModel.cardNumberIsValid,
                                                                                                     self.addCardFormViewModel.expMonthIs2Digits,
                                                                                                     self.addCardFormViewModel.expMonthIsValidMonth,
                                                                                                     self.addCardFormViewModel.expYearIs4Digits,
                                                                                                     self.addCardFormViewModel.expYearIsNotInPast,
                                                                                                     self.addCardFormViewModel.cvvIsCorrectLength,
                                                                                                     self.addCardFormViewModel.zipCodeIs5Digits])
    { !$0.contains(false) }
    
    private(set) lazy var inlineBankValid: Driver<Bool> = Driver.combineLatest(self.addBankFormViewModel.saveToWallet.asDriver(),
                                                                               self.saveToWalletBankFormValidBGE,
                                                                               self.saveToWalletBankFormValidComEdPECO,
                                                                               self.noSaveToWalletBankFormValidBGE,
                                                                               self.noSaveToWalletBankFormValidComEdPECO)
    {
        if $0 { // Save to wallet
            return Environment.shared.opco == .bge ? $1 : $2
        } else { // No save
            return Environment.shared.opco == .bge ? $3 : $4
        }
    }
    
    private(set) lazy var inlineCardValid: Driver<Bool> = Driver.combineLatest(self.addCardFormViewModel.saveToWallet.asDriver(),
                                                                               self.saveToWalletCardFormValidBGE,
                                                                               self.saveToWalletCardFormValidComEdPECO,
                                                                               self.noSaveToWalletCardFormValidBGE,
                                                                               self.noSaveToWalletCardFormValidComEdPECO)
    {
        if $0 { // Save to wallet
            return Environment.shared.opco == .bge ? $1 : $2
        } else { // No save
            return Environment.shared.opco == .bge ? $3 : $4
        }
    }
    
    private(set) lazy var paymentFieldsValid: Driver<Bool> = Driver.combineLatest(self.shouldShowContent,
                                                                                  self.paymentAmount.asDriver(),
                                                                                  self.paymentAmountErrorMessage)
    { $0 && !$1.isEmpty && $2 == nil }
    
    // MARK: - Make Payment Drivers
    
    private(set) lazy var makePaymentNextButtonEnabled: Driver<Bool> = Driver.combineLatest(self.inlineBank.asDriver(),
                                                                                            self.inlineBankValid,
                                                                                            self.inlineCard.asDriver(),
                                                                                            self.inlineCardValid,
                                                                                            self.selectedWalletItem.asDriver(),
                                                                                            self.paymentFieldsValid,
                                                                                            self.cvvIsCorrectLength)
    { (inlineBank, inlineBankValid, inlineCard, inlineCardValid, selectedWalletItem, paymentFieldsValid, cvvIsCorrectLength) in
        if inlineBank {
            return inlineBankValid && paymentFieldsValid
        } else if inlineCard {
            return inlineCardValid && paymentFieldsValid
        } else {
            if Environment.shared.opco == .bge {
                if let walletItem = selectedWalletItem {
                    if walletItem.bankOrCard == .card {
                        return paymentFieldsValid && cvvIsCorrectLength
                    } else {
                        return paymentFieldsValid
                    }
                } else {
                    return false
                }
            } else {
                return selectedWalletItem != nil && paymentFieldsValid
            }
        }
    }
    
    private(set) lazy var oneTouchPayDescriptionLabelText: Driver<String> = self.walletItems.asDriver().map { [weak self] _ in
        if let item = self?.oneTouchPayItem {
            switch item.bankOrCard {
            case .bank:
                    return String(format: NSLocalizedString("You are currently using bank account %@ as your default payment account.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
            case .card:
                    return String(format: NSLocalizedString("You are currently using card %@ as your default payment account.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
            }
        }
        return NSLocalizedString("Set this payment account as default to easily pay from the Home and Bill screens.", comment: "")
    }

    private(set) lazy var shouldShowInlinePaymentDivider: Driver<Bool> = Driver.combineLatest(self.inlineBank.asDriver(), self.inlineCard.asDriver())
    { $0 || $1 }
    
    private(set) lazy var isCashOnlyUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isCashOnly }
    
    private(set) lazy var isActiveSeveranceUser: Driver<Bool> = self.accountDetail.asDriver().map { $0.isActiveSeverance }
    
    private(set) lazy var isBGECommercialUser: Driver<Bool> = self.accountDetail.asDriver().map {
        Environment.shared.opco == .bge && !$0.isResidential
    }
    
    private(set) lazy var shouldShowNextButton: Driver<Bool> = Driver.combineLatest(self.paymentId.asDriver(), self.allowEdits.asDriver()).map {
        if $0 != nil {
            return $1
        }
        return true
    }
    
    private(set) lazy var shouldShowContent: Driver<Bool> = Driver.combineLatest(self.isFetching.asDriver(), self.isError.asDriver())
        .map { !$0 && !$1 }
    
    private(set) lazy var shouldShowPaymentAccountView: Driver<Bool> = Driver.combineLatest(self.selectedWalletItem.asDriver(),
                                                                                            self.inlineBank.asDriver(),
                                                                                            self.inlineCard.asDriver(),
                                                                                            self.wouldBeSelectedWalletItemIsExpired.asDriver())
    {
        if $1 || $2 {
            return false
        }
        if $3 {
            return true
        }
        return $0 != nil
    }
    
    private(set) lazy var hasWalletItems: Driver<Bool> = Driver.combineLatest(self.walletItems.asDriver(), self.isCashOnlyUser, self.isBGECommercialUser)
    {
        guard let walletItems: [WalletItem] = $0 else { return false }
        if $1 { // If only bank accounts, treat cash only user as if they have no wallet items
            for item in walletItems {
                if item.bankOrCard == .card {
                    return true
                }
            }
            return false
        } else if $2 { // If BGE Commercial user, ignore VISA credit cards
            for item in walletItems {
                if item.bankOrCard == .bank {
                    return true
                } else if let cardIssuer = item.cardIssuer, cardIssuer != "Visa" {
                    return true
                }
            }
            return false
        } else {
            return walletItems.count > 0
        }
    }
    
    private(set) lazy var shouldShowCvvTextField: Driver<Bool> = Driver.combineLatest(self.cardWorkflow, self.inlineCard.asDriver(), self.allowEdits.asDriver())
    {
        if !$2 {
            return false
        }
        if Environment.shared.opco == .bge && $0 && !$1 {
            return true
        }
        return false
    }
    
    private(set) lazy var cvvIsCorrectLength: Driver<Bool> = self.cvv.asDriver().map { $0.count == 3 || $0.count == 4 }
    
    private(set) lazy var shouldShowPaymentAmountTextField: Driver<Bool> = Driver.combineLatest(self.hasWalletItems,
                                                                                                self.inlineBank.asDriver(),
                                                                                                self.inlineCard.asDriver(),
                                                                                                self.allowEdits.asDriver())
    { ($0 || $1 || $2) && $3 }
    
    private(set) lazy var paymentAmountErrorMessage: Driver<String?> = {
        let amount = self.paymentAmount.asDriver().map {
            Double(String($0.filter { "0123456789.".contains($0) }))
        }
        
        return Driver.combineLatest(self.bankWorkflow, self.cardWorkflow, self.accountDetail.asDriver(), amount, self.amountDue.asDriver())
        { (bankWorkflow, cardWorkflow, accountDetail, paymentAmount, amountDue) -> String? in
            guard let paymentAmount: Double = paymentAmount else { return nil }
            
            if bankWorkflow {
                let minPayment = accountDetail.minPaymentAmount(bankOrCard: .bank)
                let maxPayment = accountDetail.maxPaymentAmount(bankOrCard: .bank)
                if Environment.shared.opco == .bge {
                    // BGE BANK
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString!)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum Payment allowed is \(maxPayment.currencyString!)", comment: "")
                    }
                } else {
                    // COMED/PECO BANK
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString!)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum Payment allowed is \(maxPayment.currencyString!)", comment: "")
                    }
                }
            } else if cardWorkflow {
                let minPayment = accountDetail.minPaymentAmount(bankOrCard: .card)
                let maxPayment = accountDetail.maxPaymentAmount(bankOrCard: .card)
                if Environment.shared.opco == .bge {
                    // BGE CREDIT CARD
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString!)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum Payment allowed is \(maxPayment.currencyString!)", comment: "")
                    }
                } else {
                    // COMED/PECO CREDIT CARD
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString!)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum Payment allowed is \(maxPayment.currencyString!)", comment: "")
                    }
                }
            }
            return nil
        }
    }()
    
    var showSelectPaymentAmount: Bool {
        //TODO: Remove when BGE gets paymentus
        guard Environment.shared.opco != .bge else { return false }
        
        let billingInfo = accountDetail.value.billingInfo
        
        if billingInfo.pastDueAmount ?? 0 > 0 && billingInfo.pastDueAmount != billingInfo.netDueAmount {
            return true
        }
        
        return false
    }
    
    lazy var paymentAmounts: [(String, String)] = {
        let opco = Environment.shared.opco
        
        //TODO: Remove when BGE gets paymentus
        guard opco != .bge else { return [] }
        
        let billingInfo = accountDetail.value.billingInfo
        
        guard let netDueAmount = billingInfo.netDueAmount?.currencyString,
            let pastDueAmount = billingInfo.pastDueAmount, pastDueAmount > 0 else {
            return []
        }
        
        let totalAmount = (netDueAmount, NSLocalizedString("Total Amount Due", comment: ""))
        
        let pastDue = (pastDueAmount.currencyString!, NSLocalizedString("Total Amount Past Due", comment: ""))
        
        let other = (NSLocalizedString("Other", comment: ""),
                     NSLocalizedString("Enter Custom Amount", comment: ""))
        
        var amounts = [totalAmount, other]
        
        var precariousAmounts = [(String, String)]()
        if let restorationAmount = billingInfo.restorationAmount,
            restorationAmount > 0 &&
                opco != .bge &&
                accountDetail.value.isCutOutNonPay {
            if pastDueAmount != restorationAmount {
                precariousAmounts.append(pastDue)
            }
            
            precariousAmounts.append((restorationAmount.currencyString!, NSLocalizedString("Amount Due to Restore Service", comment: "")))
        } else if let arrears = billingInfo.disconnectNoticeArrears, arrears > 0 && billingInfo.isDisconnectNotice {
            if pastDueAmount != arrears {
                precariousAmounts.append(pastDue)
            }
            
            precariousAmounts.append((arrears.currencyString!, NSLocalizedString("Amount Due to Avoid Shutoff", comment: "")))
        } else if let amtDpaReinst = billingInfo.amtDpaReinst, amtDpaReinst > 0 && opco != .bge {
            if pastDueAmount != amtDpaReinst {
                precariousAmounts.append(pastDue)
            }
            
            precariousAmounts.append((amtDpaReinst.currencyString!, NSLocalizedString("Amount Due to ", comment: "")))
        }
        
        if precariousAmounts.isEmpty {
            return []
        } else {
            amounts.insert(contentsOf: precariousAmounts, at: 1)
            return amounts
        }
    }()
    
    private(set) lazy var paymentAmountFeeLabelText: Driver<String?> = Driver.combineLatest(self.bankWorkflow, self.cardWorkflow, self.convenienceFee)
    { [weak self] (bankWorkflow, cardWorkflow, fee) -> String? in
        guard let self = self else { return nil }
        if bankWorkflow {
            return NSLocalizedString("No convenience fee will be applied.", comment: "")
        } else if cardWorkflow {
            if Environment.shared.opco == .bge {
                return NSLocalizedString(self.accountDetail.value.billingInfo.convenienceFeeString(isComplete: true), comment: "")
            } else {
                return String(format: NSLocalizedString("A %@ convenience fee will be applied by Bill Matrix, our payment partner.", comment: ""), fee.currencyString!)
            }
        }
        return ""
    }
    
    private(set) lazy var paymentAmountFeeFooterLabelText: Driver<String> = Driver.combineLatest(self.bankWorkflow,
                                                                                                 self.cardWorkflow,
                                                                                                 self.convenienceFee,
                                                                                                 self.accountDetail.asDriver())
    { (bankWorkflow, cardWorkflow, fee, accountDetail) -> String in
        if bankWorkflow {
            return NSLocalizedString("No convenience fee will be applied.", comment: "")
        } else if cardWorkflow {
            return String(format: NSLocalizedString("Your payment includes a %@ convenience fee.", comment: ""),
                          Environment.shared.opco == .bge && !accountDetail.isResidential ? fee.percentString! : fee.currencyString!)
        }
        return ""
    }
    
    private(set) lazy var shouldShowPaymentDateView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.inlineBank.asDriver(), self.inlineCard.asDriver())
    { $0 || $1 || $2 }
    
    private(set) lazy var shouldShowStickyFooterView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.inlineBank.asDriver(), self.inlineCard.asDriver(), self.shouldShowContent)
    { ($0 || $1 || $2) && $3 }
    
    private(set) lazy var selectedWalletItemImage: Driver<UIImage?> = Driver.combineLatest(self.selectedWalletItem.asDriver(), self.inlineBank.asDriver(), self.inlineCard.asDriver())
    {
        if $1 {
            return #imageLiteral(resourceName: "opco_bank_mini")
        } else if $2 {
            return #imageLiteral(resourceName: "opco_credit_card_mini")
        } else {
            guard let walletItem: WalletItem = $0 else { return nil }
            if walletItem.bankOrCard == .bank {
                return #imageLiteral(resourceName: "opco_bank_mini")
            } else {
                return #imageLiteral(resourceName: "opco_credit_card_mini")
            }
        }
    }
    
    private(set) lazy var selectedWalletItemMaskedAccountString: Driver<String> = Driver.combineLatest(self.selectedWalletItem.asDriver(),
                                                                                                        self.inlineBank.asDriver(),
                                                                                                        self.addBankFormViewModel.accountNumber.asDriver(),
                                                                                                        self.inlineCard.asDriver(),
                                                                                                        self.addCardFormViewModel.cardNumber.asDriver())
    {
        if $1 && $2.count >= 4 {
            return "**** \($2[$2.index($2.endIndex, offsetBy: -4)...])"
        } else if $3 && $4.count >= 4 {
            return "**** \($4[$4.index($4.endIndex, offsetBy: -4)...])"
        } else {
            guard let walletItem: WalletItem = $0 else { return "" }
            return "**** \(walletItem.maskedWalletItemAccountNumber ?? "")"
        }
    }
    
    private(set) lazy var selectedWalletItemNickname: Driver<String?> = Driver.combineLatest(self.selectedWalletItem.asDriver(),
                                                                                            self.inlineBank.asDriver(),
                                                                                            self.addBankFormViewModel.nickname.asDriver(),
                                                                                            self.inlineCard.asDriver(),
                                                                                            self.addCardFormViewModel.nickname.asDriver())
    {
        if $1 {
            return $2
        } else if $3 {
            return $4
        } else {
            guard let walletItem = $0, let nickname = walletItem.nickName else { return nil }
            
            if Environment.shared.opco != .bge, let maskedNumber = walletItem.maskedWalletItemAccountNumber {
                return nickname == maskedNumber ? nil : nickname
            } else {
                return nickname
            }
        }
    }
    
    private(set) lazy var showSelectedWalletItemNickname: Driver<Bool> = self.selectedWalletItemNickname.isNil().not()
    
    private(set) lazy var selectedWalletItemA11yLabel: Driver<String> = Driver.combineLatest(self.selectedWalletItem.asDriver(),
                                                                                             self.inlineBank.asDriver(),
                                                                                             self.addBankFormViewModel.accountNumber.asDriver(),
                                                                                             self.addBankFormViewModel.nickname.asDriver(),
                                                                                             self.inlineCard.asDriver(),
                                                                                             self.addCardFormViewModel.cardNumber.asDriver(),
                                                                                             self.addCardFormViewModel.nickname.asDriver(),
                                                                                             self.wouldBeSelectedWalletItemIsExpired.asDriver())
    {
        if $7 {
            return NSLocalizedString("Select Payment Account", comment: "")
        }
        
        var a11yLabel = ""
        
        if $1 {
            a11yLabel = NSLocalizedString("Bank account", comment: "")
            if !$3.isEmpty {
                a11yLabel += ", \($3)"
            }
            a11yLabel += String(format: NSLocalizedString(", Account number ending in, %@", comment: ""), String($2.suffix(4)))
        } else if $4 {
            a11yLabel = NSLocalizedString("Credit card", comment: "")
            if !$6.isEmpty {
                a11yLabel += ", \($6)"
            }
            a11yLabel += String(format: NSLocalizedString(", Account number ending in, %@", comment: ""), String($5.suffix(4)))
        } else {
            if let walletItem: WalletItem = $0 {
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
            }
            
        }
        
        return a11yLabel
    }
    
    private(set) lazy var convenienceFee: Driver<Double> = {
        switch Environment.shared.opco {
        case .bge:
            return self.accountDetail.value.isResidential ?
                Driver.just(self.accountDetail.value.billingInfo.residentialFee!) :
                Driver.just(self.accountDetail.value.billingInfo.commercialFee!)
        case .comEd, .peco:
            return Driver.just(self.accountDetail.value.billingInfo.convenienceFee!)
        }
    }()
    
    private(set) lazy var amountDueCurrencyString: Driver<String?> = self.amountDue.asDriver().map { $0.currencyString }
    
    private(set) lazy var dueDate: Driver<String?> = self.accountDetail.asDriver().map {
        $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
    }
    
    private(set) lazy var shouldShowAddBankAccount: Driver<Bool> = Driver.combineLatest(self.isCashOnlyUser,
                                                                                        self.hasWalletItems,
                                                                                        self.inlineBank.asDriver(),
                                                                                        self.inlineCard.asDriver(),
                                                                                        self.allowEdits.asDriver())
    { !$0 && !$1 && !$2 && !$3 && $4 }
    
    private(set) lazy var shouldShowAddCreditCard: Driver<Bool> = Driver.combineLatest(self.hasWalletItems,
                                                                                       self.inlineBank.asDriver(),
                                                                                       self.inlineCard.asDriver(),
                                                                                       self.allowEdits.asDriver())
    { !$0 && !$1 && !$2 && $3 }
    
    private(set) lazy var shouldShowWalletFooterView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems,
                                                                                          self.inlineBank.asDriver(),
                                                                                          self.inlineCard.asDriver())
    {
        if Environment.shared.opco == .bge {
            return true
        } else {
            if $1 || $2 {
                return true
            }
            return !$0
        }
    }
    
    private(set) lazy var walletFooterLabelText: Driver<String> = Driver.combineLatest(self.hasWalletItems,
                                                                                       self.inlineCard.asDriver(),
                                                                                       self.inlineBank.asDriver())
    {
        if Environment.shared.opco == .bge {
            if $0 || $2 {
                return NSLocalizedString("Any payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
            } else {
                return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.\n\nAny payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
            }
        } else {
            return NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
        }
    }
    
    private(set) lazy var isFixedPaymentDate: Driver<Bool> = Driver.combineLatest(self.accountDetail.asDriver(),
                                                                                  self.cardWorkflow,
                                                                                  self.inlineCard.asDriver(),
                                                                                  self.addBankFormViewModel.saveToWallet.asDriver(),
                                                                                  self.addCardFormViewModel.saveToWallet.asDriver(),
                                                                                  self.allowEdits.asDriver())
    { [weak self] (accountDetail, cardWorkflow, inlineCard, saveBank, saveCard, allowEdits) in
        guard let self = self else { return false }
        return self.fixedPaymentDateLogic(accountDetail: accountDetail,
                                          cardWorkflow: cardWorkflow,
                                          inlineCard: inlineCard,
                                          saveBank: saveBank,
                                          saveCard: saveCard,
                                          allowEdits: allowEdits)
    }
    
    private func fixedPaymentDateLogic(accountDetail: AccountDetail, cardWorkflow: Bool, inlineCard: Bool, saveBank: Bool, saveCard: Bool, allowEdits: Bool) -> Bool {
        if Environment.shared.opco == .bge {
            if (inlineCard && !saveCard) || accountDetail.isActiveSeverance || !allowEdits {
                return true
            }
        } else {
            if cardWorkflow || inlineCard || !saveBank || !allowEdits {
                return true
            }
            if accountDetail.billingInfo.pastDueAmount ?? 0 > 0 { // Past due, avoid shutoff
                return true
            }
            if (accountDetail.billingInfo.restorationAmount ?? 0 > 0 || accountDetail.billingInfo.amtDpaReinst ?? 0 > 0) || accountDetail.isCutOutNonPay { // Cut for non-pay
                return true
            }
            let startOfTodayDate = Calendar.opCo.startOfDay(for: Date())
            if let dueDate = accountDetail.billingInfo.dueByDate {
                if dueDate < startOfTodayDate {
                    return true
                }
            }
        }
        return false
    }
    
    private(set) lazy var isFixedPaymentDatePastDue: Driver<Bool> = self.accountDetail.asDriver().map {
        Environment.shared.opco != .bge && $0.billingInfo.pastDueAmount ?? 0 > 0
    }
    
    private(set) lazy var paymentDateString: Driver<String> = Driver.combineLatest(self.paymentDate.asDriver(), self.isFixedPaymentDate).map {
        if $1 {
            let startOfTodayDate = Calendar.opCo.startOfDay(for: Date())
            if Environment.shared.opco == .bge && Calendar.opCo.component(.hour, from: Date()) >= 20 {
                return Calendar.opCo.date(byAdding: .day, value: 1, to: startOfTodayDate)!.mmDdYyyyString
            }
            return startOfTodayDate.mmDdYyyyString
        }
        return $0.mmDdYyyyString
    }
    
    private(set) lazy var shouldShowDeletePaymentButton: Driver<Bool> = Driver.combineLatest(self.paymentId.asDriver(), self.allowDeletes.asDriver())
    {
        if $0 != nil {
            return $1
        }
        return false
    }
    
    var shouldShowBillMatrixView: Bool = Environment.shared.opco != .bge
    
    // MARK: - Review Payment Drivers
    
    private(set) lazy var reviewPaymentSubmitButtonEnabled: Driver<Bool> = Driver.combineLatest(self.shouldShowTermsConditionsSwitchView,
                                                                                                self.termsConditionsSwitchValue.asDriver(),
                                                                                                self.isOverpaying,
                                                                                                self.overpayingSwitchValue.asDriver(),
                                                                                                self.isActiveSeveranceUser,
                                                                                                self.activeSeveranceSwitchValue.asDriver())
    {
        if $0 && !$1 {
            return false
        }
        if $2 && !$3 {
            return false
        }
        if $4 && !$5 {
            return false
        }
        return true
    }
    
    private(set) lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> = self.cardWorkflow
    
    private(set) lazy var isOverpaying: Driver<Bool> = {
        switch Environment.shared.opco {
        case .bge:
            return Driver.combineLatest(self.amountDue.asDriver(), self.paymentAmount.asDriver().map {
                Double(String($0.filter { "0123456789.".contains($0) })) ?? 0
            }, resultSelector: <)
        case .comEd, .peco:
            return Driver.just(false)
        }
        
    }()
    
    private(set) lazy var isOverpayingCard: Driver<Bool> = Driver.combineLatest(self.isOverpaying, self.cardWorkflow) { $0 && $1 }
    
    private(set) lazy var isOverpayingBank: Driver<Bool> = Driver.combineLatest(self.isOverpaying, self.bankWorkflow) { $0 && $1 }
    
    private(set) lazy var overpayingValueDisplayString: Driver<String?> = {
        Driver.combineLatest(self.amountDue.asDriver(), self.paymentAmount.asDriver().map {
            Double(String($0.filter { "0123456789.".contains($0) })) ?? 0
        })
        { ($1 - $0).currencyString }
    }()
    
    private(set) lazy var shouldShowTermsConditionsSwitchView: Driver<Bool> = self.cardWorkflow.map {
        if Environment.shared.opco == .bge { // On BGE, Speedpay is only for credit cards
            return $0
        } else { // On ComEd/PECO, it's always shown for the terms and conditions agreement
            return true
        }
    }
    
    private(set) lazy var shouldShowOverpaymentSwitchView: Driver<Bool> = self.isOverpaying

    private(set) lazy var paymentAmountDisplayString: Driver<String?> = self.paymentAmount.asDriver().map { "\($0)" }
    
    private(set) lazy var convenienceFeeDisplayString: Driver<String?> = {
        Driver.combineLatest(self.convenienceFee, self.paymentAmount.asDriver().map {
            Double(String($0.filter { "0123456789.".contains($0) })) ?? 0
            })
        { [weak self] in
            guard let self = self else { return nil }
            if Environment.shared.opco == .bge && !self.accountDetail.value.isResidential {
                return (($0 / 100) * $1).currencyString
            } else {
                return $0.currencyString
            }
        }
    }()
    
    private(set) lazy var shouldShowAutoPayEnrollButton: Driver<Bool> = self.accountDetail.asDriver().map {
        !$0.isAutoPay && $0.isAutoPayEligible
    }
    
    private(set) lazy var totalPaymentLabelText: Driver<String> = self.isOverpayingBank.map {
        $0 ? NSLocalizedString("Payment Amount", comment: ""): NSLocalizedString("Total Payment", comment: "")
    }
    
    private(set) lazy var totalPaymentDisplayString: Driver<String?> = {
        Driver.combineLatest(self.paymentAmount.asDriver().map {
            Double(String($0.filter { "0123456789.".contains($0) })) ?? 0
        }, self.reviewPaymentShouldShowConvenienceFeeBox, self.convenienceFee).map { [weak self] in
            guard let self = self else { return nil }
            if $1 {
                if (Environment.shared.opco == .bge) {
                    if (self.accountDetail.value.isResidential) {
                        return ($0 + $2).currencyString
                    } else {
                        return ((1 + $2 / 100) * $0).currencyString
                    }
                } else {
                    return ($0 + $2).currencyString
                }
            } else {
                return $0.currencyString
            }
        }
    }()
    
    private(set) lazy var reviewPaymentFooterLabelText: Driver<String?> = self.cardWorkflow.map {
        if Environment.shared.opco == .bge {
            if $0 {
                return NSLocalizedString("You hereby authorize a payment debit entry to your Credit/Debit/Share Draft account. You understand that if the payment under this authorization is returned or otherwise dishonored, you will promptly remit the payment due plus any fees due under your account.", comment: "")
            }
            return nil
        } else {
            return NSLocalizedString("You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: "")
        }
    }
    
    // MARK: - Payment Confirmation
    
    private(set) lazy var shouldShowConvenienceFeeLabel: Driver<Bool> = self.cardWorkflow
    
    
    // MARK: - Random functions
    
    func formatPaymentAmount() {
        if paymentAmount.value.isEmpty {
            paymentAmount.value = "$0.00"
        } else {
            let textStr = String(paymentAmount.value.filter { "0123456789".contains($0) })
            if let intVal = Double(textStr) {
                if intVal == 0 {
                    paymentAmount.value = "$0.00"
                } else {
                    paymentAmount.value = (intVal / 100).currencyString!
                }
            }
        }
    }
    
}
