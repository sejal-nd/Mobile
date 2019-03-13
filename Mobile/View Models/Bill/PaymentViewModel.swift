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
    let newlyAddedWalletItem = Variable<WalletItem?>(nil) // Set if the user adds a new item from the Paymentus iFrame in this workflow
    let wouldBeSelectedWalletItemIsExpired = Variable(false)
    let cvv = Variable("")
    
    let amountDue: Variable<Double>
    let paymentAmount: Variable<Double>
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
    let allowCancel = Variable(false)
    
    let speedpayCutoffDate = Variable<Date?>(nil)
    
    var confirmationNumber: String?
    
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
            self.allowCancel.value = billingHistoryItem.flagAllowDeletes
        }
        
        self.paymentDate = Variable(Date()) // May be updated later...see computeDefaultPaymentDate()

        amountDue = Variable(accountDetail.billingInfo.netDueAmount ?? 0)
        paymentAmount = Variable(billingHistoryItem?.amountPaid ?? accountDetail.billingInfo.netDueAmount ?? 0)
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
    
    func fetchSpeedpayCutoff() -> Observable<Date> {
        return paymentService.fetchPaymentFreezeDate().map { date in
            self.speedpayCutoffDate.value = date
            return date
        }
    }
    
    func checkForCutoff(onShouldReject: @escaping (() -> Void), onShouldContinue: @escaping (() -> Void)) {
        switch Environment.shared.opco {
        case .bge:
            isFetching.value = true
            fetchSpeedpayCutoff()
                .subscribe(onNext: { [weak self] cutoffDate in
                    guard let self = self else { return }
                    self.isFetching.value = false
                    if Date() >= cutoffDate || self.paymentDate.value >= cutoffDate {
                        onShouldReject()
                    } else {
                        onShouldContinue()
                    }
                    }, onError: { [weak self] _ in
                        self?.isFetching.value = false
                        onShouldContinue()
                })
                .disposed(by: disposeBag)
        case .comEd, .peco:
            onShouldContinue()
        }
    }
    
    func computeDefaultPaymentDate() {
        let now = Date()
        
        switch Environment.shared.opco {
        case .comEd, .peco:
            paymentDate.value = now
        case .bge:
            let startOfTodayDate = Calendar.opCo.startOfDay(for: now)
            let tomorrow = Calendar.opCo.date(byAdding: .day, value: 1, to: startOfTodayDate)!
            
            if Calendar.opCo.component(.hour, from: Date()) >= 20 &&
                !accountDetail.value.isActiveSeverance {
                paymentDate.value = tomorrow
            }
            
            let isFixedPaymentDate = fixedPaymentDateLogic(accountDetail: accountDetail.value, cardWorkflow: false, inlineCard: false, saveBank: true, saveCard: true, allowEdits: allowEdits.value)
            if !accountDetail.value.isActiveSeverance && !isFixedPaymentDate {
                paymentDate.value = Calendar.opCo.component(.hour, from: Date()) < 20 ? now: tomorrow
            } else if let dueDate = accountDetail.value.billingInfo.dueByDate {
                if dueDate >= now && !isFixedPaymentDate {
                    if let cutoffDate = self.speedpayCutoffDate.value {
                        self.paymentDate.value = min(dueDate, cutoffDate)
                    } else {
                        self.paymentDate.value = dueDate
                    }
                }
            }
        }
    }
    
    func fetchData(onSuccess: (() -> ())?, onError: (() -> ())?, onSpeedpayCutoff: (() -> ())?) {
        var observables = [fetchWalletItems()]
        if Environment.shared.opco == .bge {
            let cutoffObservable = fetchSpeedpayCutoff()
                .do(onNext: { [weak self] date in
                    self?.speedpayCutoffDate.value = date
                })
                .mapTo(())
                .catchErrorJustReturn(())
            
            observables.append(cutoffObservable)
        }
        
        if let paymentId = paymentId.value, paymentDetail.value == nil {
            observables.append(fetchPaymentDetails(paymentId: paymentId))
        }
        
        isFetching.value = true
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.isFetching.value = false
                
                if let cutoffDate = self.speedpayCutoffDate.value {
                    var earliestDate = Date()
                    if Calendar.opCo.component(.hour, from: earliestDate) >= 20 &&
                    !self.accountDetail.value.isActiveSeverance {
                        let tomorrow = Calendar.opCo.date(byAdding: DateComponents(day: 1), to: earliestDate)!
                        earliestDate = Calendar.opCo.startOfDay(for: tomorrow)
                    }
                    
                    guard earliestDate < cutoffDate else {
                        onSpeedpayCutoff?()
                        return
                    }
                }
                
                self.computeDefaultPaymentDate()
                
                if let walletItems = self.walletItems.value {
                    if self.selectedWalletItem.value == nil { // Initial wallet item selection logic
                        if let paymentDetail = self.paymentDetail.value, self.paymentId.value != nil { // Modifiying Payment
                            self.paymentAmount.value = paymentDetail.paymentAmount
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
                }
                if self.newlyAddedWalletItem.value != nil {
                    self.selectedWalletItem.value = self.newlyAddedWalletItem.value
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
                                      existingAccount: !self.selectedWalletItem.value!.isTemporary,
                                      saveAccount: false,
                                      maskedWalletAccountNumber: self.selectedWalletItem.value!.maskedWalletItemAccountNumber!,
                                      paymentAmount: self.paymentAmount.value,
                                      paymentType: paymentType,
                                      paymentDate: paymentDate,
                                      walletId: AccountsStore.shared.customerIdentifier,
                                      walletItemId: self.selectedWalletItem.value!.walletItemID!,
                                      cvv: self.cvv.value)
                
                self.paymentService.schedulePayment(payment: payment)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] confirmationNumber in
                        self?.confirmationNumber = confirmationNumber
                        onSuccess()
                    }, onError: { err in
                        onError(err as! ServiceError)
                    }).disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
        }
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
                    
                    let paymentDate = isFixed ? Date() : self.paymentDate.value
                    let maskedAccountNumber = String(self.addBankFormViewModel.accountNumber.value.suffix(4))
                    
                    let payment = Payment(accountNumber: self.accountDetail.value.accountNumber,
                                          existingAccount: false,
                                          saveAccount: self.addBankFormViewModel.saveToWallet.value,
                                          maskedWalletAccountNumber: maskedAccountNumber,
                                          paymentAmount: self.paymentAmount.value,
                                          paymentType: .check,
                                          paymentDate: paymentDate,
                                          walletId: AccountsStore.shared.customerIdentifier,
                                          walletItemId: walletItemResult.walletItemId,
                                          cvv: nil)
                    
                    self.paymentService.schedulePayment(payment: payment)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] confirmationNumber in
                            self?.confirmationNumber = confirmationNumber
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
        let card = CreditCard(cardNumber: addCardFormViewModel.cardNumber.value,
                              securityCode: addCardFormViewModel.cvv.value,
                              cardHolderName: addCardFormViewModel.nameOnCard.value,
                              expirationMonth: addCardFormViewModel.expMonth.value,
                              expirationYear: addCardFormViewModel.expYear.value,
                              postalCode: addCardFormViewModel.zipCode.value,
                              nickname: addCardFormViewModel.nickname.value)
        
        if Environment.shared.opco == .bge && !addCardFormViewModel.saveToWallet.value {
            self.isFixedPaymentDate.asObservable().single().subscribe(onNext: { [weak self] isFixed in
                guard let self = self else { return }
                
                let paymentDate = isFixed ? Date() : self.paymentDate.value
                
                self.paymentService.scheduleBGEOneTimeCardPayment(accountNumber: self.accountDetail.value.accountNumber,
                                                                  paymentAmount: self.paymentAmount.value,
                                                                  paymentDate: paymentDate,
                                                                  creditCard: card)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] confirmationNumber in
                        self?.confirmationNumber = confirmationNumber
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
                        
                        let paymentDate = isFixed ? Date() : self.paymentDate.value
                        let maskedAccountNumber = String(self.addCardFormViewModel.cardNumber.value.suffix(4))
                        
                        let payment = Payment(accountNumber: self.accountDetail.value.accountNumber,
                                              existingAccount: false,
                                              saveAccount: self.addCardFormViewModel.saveToWallet.value,
                                              maskedWalletAccountNumber: maskedAccountNumber,
                                              paymentAmount: self.paymentAmount.value,
                                              paymentType: .credit,
                                              paymentDate: paymentDate,
                                              walletId: AccountsStore.shared.customerIdentifier,
                                              walletItemId: walletItemResult.walletItemId,
                                              cvv: self.addCardFormViewModel.cvv.value)
                        
                        self.paymentService.schedulePayment(payment: payment)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { [weak self] confirmationNumber in
                                self?.confirmationNumber = confirmationNumber
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
        paymentService.cancelPayment(accountNumber: accountDetail.value.accountNumber, paymentId: paymentId.value!, paymentDetail: paymentDetail.value!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess()
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func modifyPayment(onSuccess: @escaping () -> Void, onError: @escaping (ServiceError) -> Void) {
        self.isFixedPaymentDate.asObservable().single().subscribe(onNext: { [weak self] isFixed in
            guard let self = self else { return }
            let paymentType: PaymentType = self.selectedWalletItem.value!.bankOrCard == .bank ? .check : .credit
            let paymentDate = isFixed ? Date() : self.paymentDate.value
            
            let payment = Payment(accountNumber: self.accountDetail.value.accountNumber,
                                  existingAccount: true,
                                  saveAccount: false,
                                  maskedWalletAccountNumber: self.selectedWalletItem.value!.maskedWalletItemAccountNumber!,
                                  paymentAmount: self.paymentAmount.value,
                                  paymentType: paymentType,
                                  paymentDate: paymentDate,
                                  walletId: AccountsStore.shared.customerIdentifier,
                                  walletItemId: self.selectedWalletItem.value!.walletItemID!,
                                  cvv: self.cvv.value)
            
            self.paymentService.updatePayment(paymentId: self.paymentId.value!, payment: payment)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    onSuccess()
                }, onError: { err in
                    onError(err as! ServiceError)
                }).disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Shared Drivers
    
    private(set) lazy var paymentAmountString = paymentAmount.asDriver()
        .map { $0.currencyString }
    
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
    
    private(set) lazy var saveToWalletBankFormValidBGE: Driver<Bool> = Driver
        .combineLatest([addBankFormViewModel.accountHolderNameHasText,
                        addBankFormViewModel.accountHolderNameIsValid,
                        addBankFormViewModel.routingNumberIsValid,
                        addBankFormViewModel.accountNumberHasText,
                        addBankFormViewModel.accountNumberIsValid,
                        addBankFormViewModel.confirmAccountNumberMatches,
                        addBankFormViewModel.nicknameHasText,
                        addBankFormViewModel.nicknameErrorString.map{ $0 == nil }])
        { !$0.contains(false) }
    
    private(set) lazy var saveToWalletBankFormValidComEdPECO: Driver<Bool> = Driver
        .combineLatest([addBankFormViewModel.routingNumberIsValid,
                        addBankFormViewModel.accountNumberHasText,
                        addBankFormViewModel.accountNumberIsValid,
                        addBankFormViewModel.confirmAccountNumberMatches,
                        addBankFormViewModel.nicknameErrorString.map{ $0 == nil }])
    { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletBankFormValidBGE: Driver<Bool> = Driver
        .combineLatest([addBankFormViewModel.accountHolderNameHasText,
                        addBankFormViewModel.accountHolderNameIsValid,
                        addBankFormViewModel.routingNumberIsValid,
                        addBankFormViewModel.accountNumberHasText,
                        addBankFormViewModel.accountNumberIsValid,
                        addBankFormViewModel.confirmAccountNumberMatches])
        { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletBankFormValidComEdPECO: Driver<Bool> = Driver
        .combineLatest([addBankFormViewModel.routingNumberIsValid,
                        addBankFormViewModel.accountNumberHasText,
                        addBankFormViewModel.accountNumberIsValid,
                        addBankFormViewModel.confirmAccountNumberMatches])
    { !$0.contains(false) }
    
    // MARK: - Inline Card Validation
    
    private(set) lazy var bgeCommercialUserEnteringVisa: Driver<Bool> = Driver
        .combineLatest(addCardFormViewModel.cardNumber.asDriver(),
                       accountDetail.asDriver())
        {
            if Environment.shared.opco == .bge && !$1.isResidential {
                return $0.first == "4"
            } else {
                return false
            }
    }
    
    private(set) lazy var saveToWalletCardFormValidBGE: Driver<Bool> = Driver
        .combineLatest([addCardFormViewModel.nameOnCardHasText,
                        addCardFormViewModel.cardNumberHasText,
                        addCardFormViewModel.cardNumberIsValid,
                        bgeCommercialUserEnteringVisa.map(!),
                        addCardFormViewModel.expMonthIs2Digits,
                        addCardFormViewModel.expMonthIsValidMonth,
                        addCardFormViewModel.expYearIs4Digits,
                        addCardFormViewModel.expYearIsNotInPast,
                        addCardFormViewModel.cvvIsCorrectLength,
                        addCardFormViewModel.zipCodeIs5Digits,
                        addCardFormViewModel.nicknameHasText,
                        addCardFormViewModel.nicknameErrorString.map{ $0 == nil }])
        .map { !$0.contains(false) }
        .asDriver(onErrorJustReturn: false)
    
    private(set) lazy var saveToWalletCardFormValidComEdPECO: Driver<Bool> = Driver
        .combineLatest([addCardFormViewModel.cardNumberHasText,
                        addCardFormViewModel.cardNumberIsValid,
                        addCardFormViewModel.expMonthIs2Digits,
                        addCardFormViewModel.expMonthIsValidMonth,
                        addCardFormViewModel.expYearIs4Digits,
                        addCardFormViewModel.expYearIsNotInPast,
                        addCardFormViewModel.cvvIsCorrectLength,
                        addCardFormViewModel.zipCodeIs5Digits,
                        addCardFormViewModel.nicknameErrorString.map{ $0 == nil }])
        { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletCardFormValidBGE: Driver<Bool> = Driver
        .combineLatest([addCardFormViewModel.nameOnCardHasText,
                        addCardFormViewModel.cardNumberHasText,
                        addCardFormViewModel.cardNumberIsValid,
                        bgeCommercialUserEnteringVisa.map(!),
                        addCardFormViewModel.expMonthIs2Digits,
                        addCardFormViewModel.expMonthIsValidMonth,
                        addCardFormViewModel.expYearIs4Digits,
                        addCardFormViewModel.expYearIsNotInPast,
                        addCardFormViewModel.cvvIsCorrectLength,
                        addCardFormViewModel.zipCodeIs5Digits])
        { !$0.contains(false) }
    
    private(set) lazy var noSaveToWalletCardFormValidComEdPECO: Driver<Bool> = Driver
        .combineLatest([addCardFormViewModel.cardNumberHasText,
                        addCardFormViewModel.cardNumberIsValid,
                        addCardFormViewModel.expMonthIs2Digits,
                        addCardFormViewModel.expMonthIsValidMonth,
                        addCardFormViewModel.expYearIs4Digits,
                        addCardFormViewModel.expYearIsNotInPast,
                        addCardFormViewModel.cvvIsCorrectLength,
                        addCardFormViewModel.zipCodeIs5Digits])
    { !$0.contains(false) }
    
    private(set) lazy var inlineBankValid: Driver<Bool> = Driver
        .combineLatest(addBankFormViewModel.saveToWallet.asDriver(),
                       saveToWalletBankFormValidBGE,
                       saveToWalletBankFormValidComEdPECO,
                       noSaveToWalletBankFormValidBGE,
                       noSaveToWalletBankFormValidComEdPECO)
    {
        if $0 { // Save to wallet
            return Environment.shared.opco == .bge ? $1 : $2
        } else { // No save
            return Environment.shared.opco == .bge ? $3 : $4
        }
    }
    
    private(set) lazy var inlineCardValid: Driver<Bool> = Driver
        .combineLatest(addCardFormViewModel.saveToWallet.asDriver(),
                       saveToWalletCardFormValidBGE,
                       saveToWalletCardFormValidComEdPECO,
                       noSaveToWalletCardFormValidBGE,
                       noSaveToWalletCardFormValidComEdPECO)
        {
        if $0 { // Save to wallet
            return Environment.shared.opco == .bge ? $1 : $2
        } else { // No save
            return Environment.shared.opco == .bge ? $3 : $4
        }
    }
    
    private(set) lazy var paymentFieldsValid: Driver<Bool> = Driver
        .combineLatest(shouldShowContent,
                       paymentAmountErrorMessage)
        { $0 && $1 == nil }
    
    // MARK: - Make Payment Drivers
    
    private(set) lazy var makePaymentNextButtonEnabled: Driver<Bool> = Driver
        .combineLatest(inlineBank.asDriver(),
                       inlineBankValid,
                       inlineCard.asDriver(),
                       inlineCardValid,
                       selectedWalletItem.asDriver(),
                       paymentFieldsValid,
                       cvvIsCorrectLength)
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
                    return String(format: NSLocalizedString("You are currently using bank account %@ as your default payment method.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
            case .card:
                    return String(format: NSLocalizedString("You are currently using card %@ as your default payment method.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
            }
        }
        return NSLocalizedString("Set this payment method as default to easily pay from the Home and Bill screens.", comment: "")
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
            if let tempItem = self.newlyAddedWalletItem.value {
                return true
            }
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
        return Driver.combineLatest(bankWorkflow, cardWorkflow, accountDetail.asDriver(), paymentAmount.asDriver(), amountDue.asDriver())
        { (bankWorkflow, cardWorkflow, accountDetail, paymentAmount, amountDue) -> String? in
            if bankWorkflow {
                let minPayment = accountDetail.minPaymentAmount(bankOrCard: .bank)
                let maxPayment = accountDetail.maxPaymentAmount(bankOrCard: .bank)
                if Environment.shared.opco == .bge {
                    // BGE BANK
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                } else {
                    // COMED/PECO BANK
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to total amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                }
            } else if cardWorkflow {
                let minPayment = accountDetail.minPaymentAmount(bankOrCard: .card)
                let maxPayment = accountDetail.maxPaymentAmount(bankOrCard: .card)
                if Environment.shared.opco == .bge {
                    // BGE CREDIT CARD
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                } else {
                    // COMED/PECO CREDIT CARD
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to total amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum payment allowed is \(maxPayment.currencyString)", comment: "")
                    }
                }
            }
            return nil
        }
    }()
    
    private(set) lazy var shouldShowSelectPaymentAmount: Driver<Bool> = self.selectedWalletItem.asDriver().map { [weak self] in
        guard Environment.shared.opco != .bge else { return false } //TODO: Remove when BGE gets paymentus
        guard let self = self else { return false }
        guard let bankOrCard = $0?.bankOrCard else { return false }
        
        if self.paymentAmounts.isEmpty {
            return false
        }
        
        let min = self.accountDetail.value.minPaymentAmount(bankOrCard: bankOrCard)
        let max = self.accountDetail.value.maxPaymentAmount(bankOrCard: bankOrCard)
        for paymentAmount in self.paymentAmounts {
            guard let amount = paymentAmount.0 else { continue }
            if amount < min || amount > max {
                return false
            }
        }
        return true
    }
    
    /**
     Some funky logic going on here. Basically, there are three cases in which we just return []
     
     1. No pastDueAmount
     2. netDueAmount == pastDueAmount, no other precarious amounts exist
     3. netDueAmount == pastDueAmount == other precarious amount (restorationAmount, amtDpaReinst, disconnectNoticeArrears)
     
     In these cases we don't give the user multiple payment amount options, just the text field.
    */
    lazy var paymentAmounts: [(Double?, String)] = {
        //TODO: Remove when BGE gets paymentus
        guard Environment.shared.opco != .bge else { return [] }
        
        let billingInfo = accountDetail.value.billingInfo
        
        guard let netDueAmount = billingInfo.netDueAmount,
            let pastDueAmount = billingInfo.pastDueAmount,
            pastDueAmount > 0 else {
            return []
        }
        
        let totalAmount: (Double?, String)
        if pastDueAmount == netDueAmount {
            totalAmount = (netDueAmount, NSLocalizedString("Total Past Due Amount", comment: ""))
        } else {
            totalAmount = (netDueAmount, NSLocalizedString("Total Amount Due", comment: ""))
        }
        
        let pastDue: (Double?, String) = (pastDueAmount, NSLocalizedString("Past Due Amount", comment: ""))
        let other: (Double?, String) = (nil, NSLocalizedString("Enter Custom Amount", comment: ""))
        
        var amounts: [(Double?, String)] = [totalAmount, other]
        var precariousAmounts = [(Double?, String)]()
        if let restorationAmount = billingInfo.restorationAmount, restorationAmount > 0 &&
            Environment.shared.opco != .bge && accountDetail.value.isCutOutNonPay {
            guard pastDueAmount != netDueAmount || restorationAmount != netDueAmount else {
                return []
            }
            
            if pastDueAmount != netDueAmount && pastDueAmount != restorationAmount {
                precariousAmounts.append(pastDue)
            }
            
            precariousAmounts.append((restorationAmount, NSLocalizedString("Restoration Amount", comment: "")))
        } else if let arrears = billingInfo.disconnectNoticeArrears, arrears > 0 {
            guard pastDueAmount != netDueAmount || arrears != netDueAmount else {
                return []
            }
            
            if pastDueAmount != netDueAmount && pastDueAmount != arrears {
                precariousAmounts.append(pastDue)
            }
            
            precariousAmounts.append((arrears, NSLocalizedString("Turn-Off Notice Amount", comment: "")))
        } else if let amtDpaReinst = billingInfo.amtDpaReinst, amtDpaReinst > 0 && Environment.shared.opco != .bge {
            guard pastDueAmount != netDueAmount || amtDpaReinst != netDueAmount else {
                return []
            }
            
            if pastDueAmount != netDueAmount && pastDueAmount != amtDpaReinst {
                precariousAmounts.append(pastDue)
            }
            
            precariousAmounts.append((amtDpaReinst, NSLocalizedString("Amount Due to Catch Up on Agreement", comment: "")))
        } else {
            guard pastDueAmount != netDueAmount else {
                return []
            }
            
            precariousAmounts.append(pastDue)
        }
        
        amounts.insert(contentsOf: precariousAmounts, at: 1)
        return amounts
    }()
    
    private(set) lazy var paymentAmountFeeLabelText: Driver<String?> = Driver
        .combineLatest(bankWorkflow, cardWorkflow)
    { [weak self] (bankWorkflow, cardWorkflow) -> String? in
        guard let self = self else { return nil }
        if bankWorkflow {
            return NSLocalizedString("No convenience fee will be applied.", comment: "")
        } else if cardWorkflow {
            if Environment.shared.opco == .bge {
                return NSLocalizedString(self.accountDetail.value.billingInfo.convenienceFeeString(isComplete: true), comment: "")
            } else {
                return String.localizedStringWithFormat("A %@ convenience fee will be applied by Paymentus, our payment partner.", self.convenienceFee.currencyString)
            }
        }
        return ""
    }
    
    private(set) lazy var paymentAmountFeeFooterLabelText: Driver<String> = Driver
        .combineLatest(bankWorkflow, cardWorkflow, accountDetail.asDriver())
        { [weak self] (bankWorkflow, cardWorkflow, accountDetail) -> String in
            guard let self = self else { return "" }
            if bankWorkflow {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else if cardWorkflow {
                return String(format: NSLocalizedString("Your payment includes a %@ convenience fee.", comment: ""),
                              Environment.shared.opco == .bge && !accountDetail.isResidential ? self.convenienceFee.percentString! : self.convenienceFee.currencyString)
            }
            return ""
    }
    
    private(set) lazy var shouldShowPaymentDateView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.inlineBank.asDriver(), self.inlineCard.asDriver(), self.paymentId.asDriver())
    { $0 || $1 || $2 || $3 != nil }
    
    private(set) lazy var shouldShowStickyFooterView: Driver<Bool> = Driver.combineLatest(self.hasWalletItems, self.inlineBank.asDriver(), self.inlineCard.asDriver(), self.shouldShowContent)
    { ($0 || $1 || $2) && $3 }
    
    private(set) lazy var selectedWalletItemImage: Driver<UIImage?> = Driver
        .combineLatest(selectedWalletItem.asDriver(), inlineBank.asDriver(), inlineCard.asDriver())
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
    
    private(set) lazy var selectedWalletItemMaskedAccountString: Driver<String> = Driver
        .combineLatest(selectedWalletItem.asDriver(),
                       inlineBank.asDriver(),
                       addBankFormViewModel.accountNumber.asDriver(),
                       inlineCard.asDriver(),
                       addCardFormViewModel.cardNumber.asDriver())
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
    
    private(set) lazy var selectedWalletItemNickname: Driver<String?> = Driver
        .combineLatest(selectedWalletItem.asDriver(),
                       inlineBank.asDriver(),
                       addBankFormViewModel.nickname.asDriver(),
                       inlineCard.asDriver(),
                       addCardFormViewModel.nickname.asDriver())
        {
            if $1 {
                return $2
            } else if $3 {
                return $4
            } else {
                guard let walletItem = $0, let nickname = walletItem.nickName else { return nil }
                return nickname
            }
    }
    
    private(set) lazy var showSelectedWalletItemNickname: Driver<Bool> = selectedWalletItemNickname.isNil().not()
    
    private(set) lazy var selectedWalletItemA11yLabel: Driver<String> = Driver
        .combineLatest(selectedWalletItem.asDriver(),
                       inlineBank.asDriver(),
                       addBankFormViewModel.accountNumber.asDriver(),
                       addBankFormViewModel.nickname.asDriver(),
                       inlineCard.asDriver(),
                       addCardFormViewModel.cardNumber.asDriver(),
                       addCardFormViewModel.nickname.asDriver(),
                       wouldBeSelectedWalletItemIsExpired.asDriver())
        {
            if $7 {
                return NSLocalizedString("Select Payment Method", comment: "")
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
    
    var convenienceFee: Double {
        switch Environment.shared.opco {
        case .bge:
            return self.accountDetail.value.isResidential ?
                accountDetail.value.billingInfo.residentialFee! :
                accountDetail.value.billingInfo.commercialFee!
        case .comEd, .peco:
            return accountDetail.value.billingInfo.convenienceFee!
        }
    }
    
    private(set) lazy var amountDueCurrencyString: Driver<String?> = amountDue.asDriver().map { $0.currencyString }
    
    private(set) lazy var dueDate: Driver<String?> = accountDetail.asDriver().map {
        $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
    }
    
    private(set) lazy var shouldShowAddBankAccount: Driver<Bool> = Driver
        .combineLatest(isCashOnlyUser,
                       hasWalletItems,
                       inlineBank.asDriver(),
                       inlineCard.asDriver(),
                       allowEdits.asDriver())
        { !$0 && !$1 && !$2 && !$3 && $4 }
    
    private(set) lazy var shouldShowAddCreditCard: Driver<Bool> = Driver
        .combineLatest(hasWalletItems,
                       inlineBank.asDriver(),
                       inlineCard.asDriver(),
                       allowEdits.asDriver())
        { !$0 && !$1 && !$2 && $3 }
    
    private(set) lazy var shouldShowAddPaymentMethodView: Driver<Bool> = Driver
        .combineLatest(shouldShowAddBankAccount, shouldShowAddCreditCard)
        { $0 || $1 }
    
    private(set) lazy var walletFooterLabelText: Driver<String> = Driver
        .combineLatest(hasWalletItems, inlineCard.asDriver(), inlineBank.asDriver())
    {
        if Environment.shared.opco == .bge {
            if $0 || $2 {
                return NSLocalizedString("Any payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
            } else {
                return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Business customers cannot use VISA.\n\nAny payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
            }
        } else {
            return NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation.", comment: "")
        }
    }
    
    private(set) lazy var isFixedPaymentDate: Driver<Bool> = Driver
        .combineLatest(accountDetail.asDriver(),
                       cardWorkflow,
                       inlineCard.asDriver(),
                       addBankFormViewModel.saveToWallet.asDriver(),
                       addCardFormViewModel.saveToWallet.asDriver(),
                       allowEdits.asDriver())
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
            if !allowEdits {
                return true
            }
            
            let startOfTodayDate = Calendar.opCo.startOfDay(for: Date())
            if let dueDate = accountDetail.billingInfo.dueByDate {
                if dueDate <= startOfTodayDate {
                    return true
                }
            }
        }
        
        return false
    }
    
    private(set) lazy var shouldShowPastDueLabel: Driver<Bool> = accountDetail.asDriver().map { [weak self] in
        if Environment.shared.opco == .bge || self?.paymentId.value != nil {
            return false
        }
        
        guard let pastDueAmount = $0.billingInfo.pastDueAmount,
            let netDueAmount = $0.billingInfo.netDueAmount,
            let dueDate = $0.billingInfo.dueByDate else {
                return false
        }
        let startOfTodayDate = Calendar.opCo.startOfDay(for: Date())
        if pastDueAmount > 0 && pastDueAmount != netDueAmount && dueDate > startOfTodayDate {
            // Past due amount but with a new bill allows user to future date, so we should hide
            return false
        }

        return pastDueAmount > 0
    }
    
    private(set) lazy var paymentDateString: Driver<String> = Driver
        .combineLatest(paymentDate.asDriver(), isFixedPaymentDate, paymentDetail.asDriver())
        .map {
            if $1 {
                if let paymentDate = $2?.paymentDate, Environment.shared.opco != .bge {
                    return paymentDate.mmDdYyyyString
                }
                let startOfTodayDate = Calendar.opCo.startOfDay(for: Date())
                if Environment.shared.opco == .bge && Calendar.opCo.component(.hour, from: Date()) >= 20 {
                    return Calendar.opCo.date(byAdding: .day, value: 1, to: startOfTodayDate)!.mmDdYyyyString
                }
                return startOfTodayDate.mmDdYyyyString
            }
            return $0.mmDdYyyyString
    }
    
    private(set) lazy var shouldShowCancelPaymentButton: Driver<Bool> = Driver
        .combineLatest(paymentId.asDriver(), allowCancel.asDriver())
        {
            if $0 != nil {
                return $1
            }
            return false
    }
    
    // MARK: - Review Payment Drivers
    
    private(set) lazy var reviewPaymentSubmitButtonEnabled: Driver<Bool> = Driver
        .combineLatest(shouldShowTermsConditionsSwitchView,
                       termsConditionsSwitchValue.asDriver(),
                       isOverpaying,
                       overpayingSwitchValue.asDriver(),
                       isActiveSeveranceUser,
                       activeSeveranceSwitchValue.asDriver())
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
    
    private(set) lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> = cardWorkflow
    
    private(set) lazy var isOverpaying: Driver<Bool> = {
        switch Environment.shared.opco {
        case .bge:
            return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver(), resultSelector: <)
        case .comEd, .peco:
            return Driver.just(false)
        }
        
    }()
    
    private(set) lazy var isOverpayingCard: Driver<Bool> = Driver.combineLatest(isOverpaying, cardWorkflow) { $0 && $1 }
    
    private(set) lazy var isOverpayingBank: Driver<Bool> = Driver.combineLatest(isOverpaying, bankWorkflow) { $0 && $1 }
    
    private(set) lazy var overpayingValueDisplayString: Driver<String?> = Driver
        .combineLatest(amountDue.asDriver(), paymentAmount.asDriver())
        { ($1 - $0).currencyString }
    
    private(set) lazy var shouldShowTermsConditionsSwitchView: Driver<Bool> = cardWorkflow.map {
        if Environment.shared.opco == .bge { // On BGE, Speedpay is only for credit cards
            return $0
        } else { // On ComEd/PECO, it's always shown for the terms and conditions agreement
            return true
        }
    }
    
    private(set) lazy var shouldShowOverpaymentSwitchView: Driver<Bool> = isOverpaying

    private(set) lazy var convenienceFeeDisplayString: Driver<String?> = paymentAmount.asDriver().map { [weak self] in
            guard let self = self else { return nil }
            if Environment.shared.opco == .bge && !self.accountDetail.value.isResidential {
                return (($0 / 100) * self.convenienceFee).currencyString
            } else {
                return self.convenienceFee.currencyString
            }
    }
        
    private(set) lazy var shouldShowAutoPayEnrollButton: Driver<Bool> = accountDetail.asDriver().map {
        !$0.isAutoPay && $0.isAutoPayEligible && !StormModeStatus.shared.isOn
    }
    
    private(set) lazy var totalPaymentLabelText: Driver<String> = isOverpayingBank.map {
        $0 ? NSLocalizedString("Payment Amount", comment: ""): NSLocalizedString("Total Payment", comment: "")
    }
    
    private(set) lazy var totalPaymentDisplayString: Driver<String?> = Driver
        .combineLatest(paymentAmount.asDriver(), reviewPaymentShouldShowConvenienceFeeBox)
        .map { [weak self] paymentAmount, showConvenienceFeeBox in
            guard let self = self else { return nil }
            if showConvenienceFeeBox {
                switch Environment.shared.opco {
                case .bge:
                    if self.accountDetail.value.isResidential {
                        return (paymentAmount + self.convenienceFee).currencyString
                    } else {
                        return ((1 + self.convenienceFee / 100) * paymentAmount).currencyString
                    }
                case .comEd, .peco:
                    return (paymentAmount + self.convenienceFee).currencyString
                }
            } else {
                return paymentAmount.currencyString
            }
    }
    
    private(set) lazy var reviewPaymentFooterLabelText: Driver<String?> = cardWorkflow.map {
        if Environment.shared.opco == .bge {
            if $0 {
                return NSLocalizedString("You hereby authorize a payment debit entry to your Credit/Debit/Share Draft account. You understand that if the payment under this authorization is returned or otherwise dishonored, you will promptly remit the payment due plus any fees due under your account.", comment: "")
            }
            return nil
        } else {
            return NSLocalizedString("All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment.", comment: "")
        }
    }
    
    // MARK: - Payment Confirmation
    
    private(set) lazy var shouldShowConvenienceFeeLabel: Driver<Bool> = cardWorkflow
    
    var errorPhoneNumber: String {
        switch Environment.shared.opco {
        case .bge:
            return "1-800-685-0123"
        case .comEd:
            return "1-800-334-7661"
        case .peco:
            return "1-800-494-4000"
        }
    }
    
}
