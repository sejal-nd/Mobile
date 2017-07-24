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
    
    let accountDetail: Variable<AccountDetail>
    
    let isFetching = Variable(false) // Combines isFetchingWalletItems & isFetchingWorkdays
    let isError = Variable(false)
    private let isFetchingWalletItems = Variable(false)
    private let isFetchingWorkdays = Variable(false)
    
    let walletItems = Variable<[WalletItem]?>(nil)
    let selectedWalletItem = Variable<WalletItem?>(nil)
    let cvv = Variable("")
    
    let amountDue: Variable<Double>
    let paymentAmount: Variable<String>
    let paymentDate: Variable<Date>
    
    let termsConditionsSwitchValue = Variable(false)
    let overpayingSwitchValue = Variable(false)
    let activeSeveranceSwitchValue = Variable(false)
    
    var workdayArray = [Date]()
    
    let addBankFormViewModel: AddBankFormViewModel!
    let addCardFormViewModel: AddCardFormViewModel!
    let inlineCard = Variable(false)
    let inlineBank = Variable(false)
    var oneTouchPayItem: WalletItem!
    
    init(walletService: WalletService, paymentService: PaymentService, accountDetail: AccountDetail, addBankFormViewModel: AddBankFormViewModel, addCardFormViewModel: AddCardFormViewModel) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.accountDetail = Variable(accountDetail)
        self.addBankFormViewModel = addBankFormViewModel
        self.addCardFormViewModel = addCardFormViewModel
        
        if let netDueAmount = accountDetail.billingInfo.netDueAmount, netDueAmount > 0 {
            amountDue = Variable(netDueAmount)
            paymentAmount = Variable(String(netDueAmount))
        } else {
            amountDue = Variable(0)
            paymentAmount = Variable("")
        }
        
        let startOfTodayDate = Calendar.current.startOfDay(for: Date())
        self.paymentDate = Variable(startOfTodayDate)
        if Environment.sharedInstance.opco == .bge && Calendar.current.component(.hour, from: Date()) >= 20 {
            let tomorrow =  Calendar.current.date(byAdding: .day, value: 1, to: startOfTodayDate)!
            self.paymentDate.value = tomorrow
        }
        if let dueDate = accountDetail.billingInfo.dueByDate {
            if dueDate >= startOfTodayDate && !fixedPaymentDateLogic {
                self.paymentDate.value = dueDate
            }
        }
    }
    
    // MARK: - Service Calls
    
    func fetchWalletItems(onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        isFetching.value = true
        isError.value = false
        
        isFetchingWalletItems.value = true
        walletService.fetchWalletItems()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItems in
                if self.selectedWalletItem.value == nil {
                    if self.accountDetail.value.isCashOnly {
                        // Default to One Touch Pay item IF it's a credit card
                        if let otpItem = walletItems.first(where: { $0.isDefault == true }) {
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
                        if let otpItem = walletItems.first(where: { $0.isDefault == true }) {
                            self.selectedWalletItem.value = otpItem
                        } else if walletItems.count > 0 { // If no OTP item, default to first wallet item
                            self.selectedWalletItem.value = walletItems[0]
                        }
                    }
                }

                self.walletItems.value = walletItems
                self.oneTouchPayItem = walletItems.first(where: { $0.isDefault == true })
                
                self.isFetchingWalletItems.value = false
                if !self.isFetchingWorkdays.value {
                    self.isFetching.value = false
                }
                
                onSuccess?()
            }, onError: { err in
                self.isFetchingWalletItems.value = false
                self.isError.value = true
                onError?(err.localizedDescription)
            }).addDisposableTo(disposeBag)
        
        if Environment.sharedInstance.opco == .peco { // Only PECO prevents certain payment dates
            isFetchingWorkdays.value = true
            paymentService.fetchWorkdays()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { dateArray in
                    self.isFetchingWorkdays.value = false
                    if !self.isFetchingWalletItems.value {
                        self.isFetching.value = false
                    }
                    self.workdayArray = dateArray
                }, onError: { err in
                    self.isFetchingWorkdays.value = false
                    if !self.isFetchingWalletItems.value {
                        self.isFetching.value = false
                    }
                }).addDisposableTo(disposeBag)
        }
    }
    
    func schedulePayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        if inlineBank.value {
            scheduleInlineBankPayment(onSuccess: onSuccess, onError: onError)
        } else if inlineCard.value {
            scheduleInlineCardPayment(onSuccess: onSuccess, onError: onError)
        } else { // Existing wallet item
            let paymentType: PaymentType = selectedWalletItem.value!.bankOrCard == .bank ? .check : .credit
            var paymentDate = self.paymentDate.value
            if let walletItem = selectedWalletItem.value {
                if walletItem.bankOrCard == .card {
                    paymentDate = Calendar.current.startOfDay(for: Date())
                }
            }
            let payment = Payment(accountNumber: accountDetail.value.accountNumber, existingAccount: true, saveAccount: false, maskedWalletAccountNumber: selectedWalletItem.value!.maskedWalletItemAccountNumber!, paymentAmount: Double(paymentAmount.value)!, paymentType: paymentType, paymentDate: paymentDate, walletId: AccountsStore.sharedInstance.customerIdentifier, walletItemId: selectedWalletItem.value!.walletItemID!, cvv: cvv.value)
            paymentService.schedulePayment(payment: payment)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    onSuccess()
                }, onError: { err in
                    onError(err.localizedDescription)
                }).addDisposableTo(disposeBag)
        }
    
    }
    
    private func scheduleInlineBankPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var accountType: String?
        if Environment.sharedInstance.opco == .bge {
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
            .addBankAccount(bankAccount, forCustomerNumber: AccountsStore.sharedInstance.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItemResult in
                if self.addBankFormViewModel.oneTouchPay.value {
                    self.enableOneTouchPay(walletItemID: walletItemResult.walletItemId, onSuccess: nil, onError: nil)
                }
                
                let paymentType: PaymentType = .check
                var paymentDate = self.paymentDate.value
                if !self.addBankFormViewModel.saveToWallet.value {
                    paymentDate = Calendar.current.startOfDay(for: Date())
                }
                
                let accountNum = self.addBankFormViewModel.accountNumber.value
                let maskedAccountNumber = accountNum.substring(from: accountNum.index(accountNum.endIndex, offsetBy: -4))
                
                let payment = Payment(accountNumber: self.accountDetail.value.accountNumber, existingAccount: false, saveAccount: self.addBankFormViewModel.saveToWallet.value, maskedWalletAccountNumber: maskedAccountNumber, paymentAmount: Double(self.paymentAmount.value)!, paymentType: paymentType, paymentDate: paymentDate, walletId: AccountsStore.sharedInstance.customerIdentifier, walletItemId: walletItemResult.walletItemId, cvv: nil)
                self.paymentService.schedulePayment(payment: payment)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        onSuccess()
                    }, onError: { err in
                        if !self.addBankFormViewModel.saveToWallet.value {
                            // Rollback the wallet add
                            self.walletService.deletePaymentMethod(WalletItem.from(["walletItemID": walletItemResult.walletItemId])!, completion: { _ in })
                        }
                        onError(err.localizedDescription)
                    }).addDisposableTo(self.disposeBag)
            }, onError: { (error: Error) in
                onError(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    private func scheduleInlineCardPayment(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var nickname = addCardFormViewModel.nickname.value
        if nickname.isEmpty && Environment.sharedInstance.opco == .bge {
            nickname = "Credit Card" // Doesn't matter because we won't be saving it to the Wallet
        }
        let card = CreditCard(cardNumber: addCardFormViewModel.cardNumber.value, securityCode: addCardFormViewModel.cvv.value, firstName: "", lastName: "", expirationMonth: addCardFormViewModel.expMonth.value, expirationYear: addCardFormViewModel.expYear.value, postalCode: addCardFormViewModel.zipCode.value, nickname: nickname)
        
        walletService
            .addCreditCard(card, forCustomerNumber: AccountsStore.sharedInstance.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { walletItemResult in
                if self.addCardFormViewModel.oneTouchPay.value {
                    self.enableOneTouchPay(walletItemID: walletItemResult.walletItemId, onSuccess: nil, onError: nil)
                }
                
                let paymentType: PaymentType = .credit
                let paymentDate = Calendar.current.startOfDay(for: Date())
                
                let cardNum = self.addCardFormViewModel.cardNumber.value
                let maskedAccountNumber = cardNum.substring(from: cardNum.index(cardNum.endIndex, offsetBy: -4))
                
                let payment = Payment(accountNumber: self.accountDetail.value.accountNumber, existingAccount: false, saveAccount: self.addCardFormViewModel.saveToWallet.value, maskedWalletAccountNumber: maskedAccountNumber, paymentAmount: Double(self.paymentAmount.value)!, paymentType: paymentType, paymentDate: paymentDate, walletId: AccountsStore.sharedInstance.customerIdentifier, walletItemId: walletItemResult.walletItemId, cvv: self.addCardFormViewModel.cvv.value)
                self.paymentService.schedulePayment(payment: payment)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        onSuccess()
                    }, onError: { err in
                        if !self.addCardFormViewModel.saveToWallet.value {
                            // Rollback the wallet add
                            self.walletService.deletePaymentMethod(WalletItem.from(["walletItemID": walletItemResult.walletItemId])!, completion: { _ in })
                        }
                        onError(err.localizedDescription)
                    }).addDisposableTo(self.disposeBag)
            }, onError: { err in
                onError(err.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    func enableOneTouchPay(walletItemID: String, onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        walletService.setOneTouchPayItem(walletItemId: walletItemID,
                                         walletId: nil,
                                         customerId: AccountsStore.sharedInstance.customerIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                onSuccess?()
            }, onError: { err in
                onError?(err.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
    // MARK: - Shared Drivers
    
    var bankWorkflow: Driver<Bool> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), inlineBank.asDriver()).map {
            if $1 {
                return true
            }
            guard let walletItem = $0 else { return false }
            return walletItem.bankOrCard == .bank
        }
    }
    
    var cardWorkflow: Driver<Bool> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), inlineCard.asDriver()).map {
            if $1 {
                return true
            }
            guard let walletItem = $0 else { return false }
            return walletItem.bankOrCard == .card
        }
    }
    
    // MARK: - Inline Bank Validation
    
    var saveToWalletBankFormValidBGE: Driver<Bool> {
        return Driver.combineLatest([addBankFormViewModel.accountHolderNameHasText().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.routingNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberHasText().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.confirmAccountNumberMatches().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.nicknameHasText().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.nicknameIsValid().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    var saveToWalletBankFormValidComEdPECO: Driver<Bool> {
        return Driver.combineLatest([addBankFormViewModel.routingNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberHasText().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.confirmAccountNumberMatches().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.nicknameIsValid().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    var noSaveToWalletBankFormValidBGE: Driver<Bool> {
        return Driver.combineLatest([addBankFormViewModel.accountHolderNameHasText().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.routingNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberHasText().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.confirmAccountNumberMatches().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    var noSaveToWalletBankFormValidComEdPECO: Driver<Bool> {
        return Driver.combineLatest([addBankFormViewModel.routingNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberHasText().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.accountNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addBankFormViewModel.confirmAccountNumberMatches().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    // MARK: - Inline Card Validation
    
    var saveToWalletCardFormValidBGE: Driver<Bool> {
        return Driver.combineLatest([addCardFormViewModel.nameOnCardHasText().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cardNumberHasText().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cardNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIs2Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIsValidMonth().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIs4Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIsNotInPast().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cvvIsCorrectLength().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.zipCodeIs5Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.nicknameHasText().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.nicknameIsValid().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    var saveToWalletCardFormValidComEdPECO: Driver<Bool> {
        return Driver.combineLatest([addCardFormViewModel.cardNumberHasText().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cardNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIs2Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIsValidMonth().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIs4Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIsNotInPast().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cvvIsCorrectLength().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.zipCodeIs5Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.nicknameIsValid().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    var noSaveToWalletCardFormValidBGE: Driver<Bool> {
        return Driver.combineLatest([addCardFormViewModel.nameOnCardHasText().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cardNumberHasText().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cardNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIs2Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIsValidMonth().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIs4Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIsNotInPast().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cvvIsCorrectLength().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.zipCodeIs5Digits().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    var noSaveToWalletCardFormValidComEdPECO: Driver<Bool> {
        return Driver.combineLatest([addCardFormViewModel.cardNumberHasText().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cardNumberIsValid().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIs2Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expMonthIsValidMonth().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIs4Digits().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.expYearIsNotInPast().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.cvvIsCorrectLength().asDriver(onErrorJustReturn: false),
                                     addCardFormViewModel.zipCodeIs5Digits().asDriver(onErrorJustReturn: false)]) {
            return !$0.contains(false)
        }
    }
    
    var inlineBankValid: Driver<Bool> {
        return Driver.combineLatest(addBankFormViewModel.saveToWallet.asDriver(), saveToWalletBankFormValidBGE, saveToWalletBankFormValidComEdPECO, noSaveToWalletBankFormValidBGE, noSaveToWalletBankFormValidComEdPECO).map {
            if $0 { // Save to wallet
                return Environment.sharedInstance.opco == .bge ? $1 : $2
            } else { // No save
                return Environment.sharedInstance.opco == .bge ? $3 : $4
            }
        }
    }
    
    var inlineCardValid: Driver<Bool> {
        return Driver.combineLatest(addCardFormViewModel.saveToWallet.asDriver(), saveToWalletCardFormValidBGE, saveToWalletCardFormValidComEdPECO, noSaveToWalletCardFormValidBGE, noSaveToWalletCardFormValidComEdPECO).map {
            if $0 { // Save to wallet
                return Environment.sharedInstance.opco == .bge ? $1 : $2
            } else { // No save
                return Environment.sharedInstance.opco == .bge ? $3 : $4
            }
        }
    }
    
    var paymentFieldsValid: Driver<Bool> {
        return Driver.combineLatest(shouldShowContent, paymentAmount.asDriver(), paymentAmountErrorMessage).map {
            return $0 && !$1.isEmpty && $2 == nil
        }
    }
    
    // MARK: - Make Payment Drivers
    
    var makePaymentNextButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(inlineBank.asDriver(), inlineBankValid, inlineCard.asDriver(), inlineCardValid, selectedWalletItem.asDriver(), paymentFieldsValid, cvvIsCorrectLength.asDriver(onErrorJustReturn: false)).map { (inlineBank, inlineBankValid, inlineCard, inlineCardValid, selectedWalletItem, paymentFieldsValid, cvvIsCorrectLength) in
            if inlineBank {
                return inlineBankValid && paymentFieldsValid
            } else if inlineCard {
                return inlineCardValid && paymentFieldsValid
            } else {
                if Environment.sharedInstance.opco == .bge {
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
    }
    
    var oneTouchPayDescriptionLabelText: Driver<String> {
        return walletItems.asDriver().map { _ in
            if let item = self.oneTouchPayItem {
                switch item.bankOrCard {
                case .bank:
                    return String(format: NSLocalizedString("You are currently using bank account %@ for One Touch Pay.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
                case .card:
                    return String(format: NSLocalizedString("You are currently using card %@ for One Touch Pay.", comment: ""), "**** \(item.maskedWalletItemAccountNumber!)")
                }
            }
            return NSLocalizedString("Turn on One Touch Pay to easily pay from the Home screen and set this payment account as default.", comment: "")
        }
    }
    
    var shouldShowInlinePaymentDivider: Driver<Bool> {
        return Driver.combineLatest(inlineBank.asDriver(), inlineCard.asDriver()).map {
            return $0 || $1
        }
    }
    
    lazy var isCashOnlyUser: Driver<Bool> = self.accountDetail.asDriver().map {
        return $0.isCashOnly
    }
    
    lazy var isActiveSeveranceUser: Driver<Bool> = self.accountDetail.asDriver().map {
        return $0.isActiveSeverance
    }
    
    var shouldShowContent: Driver<Bool> {
        return Driver.combineLatest(isFetching.asDriver(), isError.asDriver()).map {
            return !$0 && !$1
        }
    }
    
    var shouldShowPaymentAccountView: Driver<Bool> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), inlineBank.asDriver(), inlineCard.asDriver()).map {
            if $1 || $2 {
                return false
            }
            return $0 != nil
        }
    }
    
    var hasWalletItems: Driver<Bool> {
        return Driver.combineLatest(walletItems.asDriver(), isCashOnlyUser).map {
            guard let walletItems: [WalletItem] = $0 else { return false }
            if $1 { // If only bank accounts, treat cash only user as if they have no wallet items
                for item in walletItems {
                    if item.bankOrCard == .card {
                        return true
                    }
                }
                return false
            } else {
                return walletItems.count > 0
            }
        }
    }
    
    lazy var shouldShowCvvTextField: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        if let walletItem = $0 {
            if Environment.sharedInstance.opco == .bge && walletItem.bankOrCard == .card {
                return true
            }
        }
        return false
    }
    
    lazy var cvvIsCorrectLength: Observable<Bool> = self.cvv.asObservable().map {
        return $0.characters.count == 3 || $0.characters.count == 4
    }
    
    var shouldShowPaymentAmountTextField: Driver<Bool> {
        return Driver.combineLatest(hasWalletItems, inlineBank.asDriver(), inlineCard.asDriver()).map {
            return $0 || $1 || $2
        }
    }
    
    var paymentAmountErrorMessage: Driver<String?> {
        return Driver.combineLatest(bankWorkflow, cardWorkflow, accountDetail.asDriver(), paymentAmount.asDriver().map { Double($0) }, amountDue.asDriver()).map { (bankWorkflow, cardWorkflow, accountDetail, paymentAmount, amountDue) -> String? in
            guard let paymentAmount: Double = paymentAmount else { return nil }
            
            let commercialUser = !accountDetail.isResidential
            
            if bankWorkflow {
                if Environment.sharedInstance.opco == .bge {
                    // BGE BANK
                    let minPayment = accountDetail.billingInfo.minPaymentAmountACH ?? 0.01
                    let maxPayment = accountDetail.billingInfo.maxPaymentAmountACH ?? (commercialUser ? 99999.99 : 9999.99)
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString!)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum Payment allowed is \(maxPayment.currencyString!)", comment: "")
                    }
                } else {
                    // COMED/PECO BANK
                    let minPayment = accountDetail.billingInfo.minPaymentAmountACH ?? 5
                    let maxPayment = accountDetail.billingInfo.maxPaymentAmountACH ?? 90000
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString!)", comment: "")
                    } else if paymentAmount > amountDue {
                        return NSLocalizedString("Payment must be less than or equal to amount due", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum Payment allowed is \(maxPayment.currencyString!)", comment: "")
                    }
                }
            } else if cardWorkflow {
                if Environment.sharedInstance.opco == .bge {
                    // BGE CREDIT CARD
                    let minPayment = accountDetail.billingInfo.minPaymentAmount ?? 0.01
                    let maxPayment = accountDetail.billingInfo.maxPaymentAmount ?? (commercialUser ? 25000 : 600)
                    if paymentAmount < minPayment {
                        return NSLocalizedString("Minimum payment allowed is \(minPayment.currencyString!)", comment: "")
                    } else if paymentAmount > maxPayment {
                        return NSLocalizedString("Maximum Payment allowed is \(maxPayment.currencyString!)", comment: "")
                    }
                } else {
                    // COMED/PECO CREDIT CARD
                    let minPayment = accountDetail.billingInfo.minPaymentAmount ?? 5
                    let maxPayment = accountDetail.billingInfo.maxPaymentAmount ?? 5000
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
    }
    
    var paymentAmountFeeLabelText: Driver<String> {
        return Driver.combineLatest(bankWorkflow, cardWorkflow, convenienceFee).map { (bankWorkflow, cardWorkflow, fee) -> String in
            if bankWorkflow {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else if cardWorkflow {
                if Environment.sharedInstance.opco == .bge {
                    return NSLocalizedString(self.accountDetail.value.billingInfo.convenienceFeeString(isComplete: true), comment: "")
                } else {
                    let feeStr = String(format: "A %@ convenience fee will be applied by Bill Matrix, our payment partner.", fee.currencyString!)
                    return NSLocalizedString(feeStr, comment: "")
                }
            }
            return ""
        }
    }
    
    var paymentAmountFeeFooterLabelText: Driver<String> {
        return Driver.combineLatest(bankWorkflow, cardWorkflow, convenienceFee).map { (bankWorkflow, cardWorkflow, fee) -> String in
            if bankWorkflow {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else if cardWorkflow {
                let feeStr = String(format: "Your payment includes a %@ convenience fee.",
                                    (Environment.sharedInstance.opco == .bge && !self.accountDetail.value.isResidential) ? fee.percentString! : fee.currencyString!)
                return NSLocalizedString(feeStr, comment: "")
            }
            return ""
        }
    }
    
    var shouldShowPaymentDateView: Driver<Bool> {
        return Driver.combineLatest(hasWalletItems, inlineBank.asDriver(), inlineCard.asDriver()).map {
            return $0 || $1 || $2
        }
    }
    
    var shouldShowStickyFooterView: Driver<Bool> {
        return Driver.combineLatest(hasWalletItems, inlineBank.asDriver(), inlineCard.asDriver()).map {
            return $0 || $1 || $2
        }
    }
    
    var selectedWalletItemImage: Driver<UIImage?> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), inlineBank.asDriver(), inlineCard.asDriver()).map {
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
    }
    
    var selectedWalletItemMaskedAccountString: Driver<String?> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), inlineBank.asDriver(), addBankFormViewModel.accountNumber.asDriver(), inlineCard.asDriver(), addCardFormViewModel.cardNumber.asDriver()).map {
            if $1 && $2.characters.count >= 4 {
                return "**** \($2.substring(from: $2.index($2.endIndex, offsetBy: -4)))"
            } else if $3 && $4.characters.count >= 4 {
                return "**** \($4.substring(from: $4.index($4.endIndex, offsetBy: -4)))"
            } else {
                guard let walletItem: WalletItem = $0 else { return "" }
                return "**** \(walletItem.maskedWalletItemAccountNumber ?? "")"
            }
        }
    }
    
    var selectedWalletItemNickname: Driver<String> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), inlineBank.asDriver(), addBankFormViewModel.nickname.asDriver(), inlineCard.asDriver(), addCardFormViewModel.nickname.asDriver()).map {
            if $1 {
                return $2
            } else if $3 {
                return $4
            } else {
                guard let walletItem: WalletItem = $0 else { return "" }
                return walletItem.nickName ?? ""
            }
        }
    }
    
    var convenienceFee: Driver<Double> {
        switch Environment.sharedInstance.opco {
        case .bge:
            return accountDetail.value.isResidential ? Driver.just(accountDetail.value.billingInfo.residentialFee!) : Driver.just(accountDetail.value.billingInfo.commercialFee!)
        case .comEd, .peco:
            return Driver.just(accountDetail.value.billingInfo.convenienceFee!)
        
        }
    }
    
    lazy var amountDueCurrencyString: Driver<String> = self.amountDue.asDriver().map {
        return $0.currencyString!
    }
    
    lazy var dueDate: Driver<String?> = self.accountDetail.asDriver().map {
        return $0.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
    }
    
    var shouldShowAddBankAccount: Driver<Bool> {
        return Driver.combineLatest(isCashOnlyUser, hasWalletItems, inlineBank.asDriver(), inlineCard.asDriver()).map {
            return !$0 && !$1 && !$2 && !$3
        }
    }
    
    var shouldShowAddCreditCard: Driver<Bool> {
        return Driver.combineLatest(hasWalletItems, inlineBank.asDriver(), inlineCard.asDriver()).map {
            return !$0 && !$1 && !$2
        }
    }
    
    var shouldShowWalletFooterView: Driver<Bool> {
        return Driver.combineLatest(hasWalletItems, inlineBank.asDriver(), inlineCard.asDriver()).map {
            if Environment.sharedInstance.opco == .bge {
                return true
            } else {
                if $1 {
                    return false
                } else if $2 {
                    return true
                }
                return !$0
            }
        }
    }
    
    var walletFooterLabelText: Driver<String> {
        return Driver.combineLatest(hasWalletItems, inlineCard.asDriver()).map {
            if Environment.sharedInstance.opco == .bge {
                if $0 {
                    return NSLocalizedString("Any payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
                } else {
                    return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.", comment: "")
                }
            } else {
                if $1 {
                    return NSLocalizedString("We accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
                } else {
                    return NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
                }
            }
        }
    }
    
    var isFixedPaymentDate: Driver<Bool> {
        return Driver.combineLatest(accountDetail.asDriver(), cardWorkflow, addBankFormViewModel.saveToWallet.asDriver()).map {
            if $1 || !$2 {
                return true
            }
            
            if self.fixedPaymentDateLogic {
                return true
            }

            let startOfTodayDate = Calendar.current.startOfDay(for: Date())
            if let dueDate = $0.billingInfo.dueByDate {
                if dueDate < startOfTodayDate {
                    return true
                }
            }
            
            return false
        }
    }
    
    private var fixedPaymentDateLogic: Bool {
        if accountDetail.value.billingInfo.pastDueAmount ?? 0 > 0 { // Past due, avoid shutoff
            return true
        }
        if (accountDetail.value.billingInfo.restorationAmount ?? 0 > 0 || accountDetail.value.billingInfo.amtDpaReinst ?? 0 > 0) || accountDetail.value.isCutOutNonPay { // Cut for non-pay
            return true
        }
        if accountDetail.value.isActiveSeverance {
            return true
        }
        return false
    }
    
    lazy var isFixedPaymentDatePastDue: Driver<Bool> = self.accountDetail.asDriver().map {
        return $0.billingInfo.pastDueAmount ?? 0 > 0
    }
    
    var paymentDateString: Driver<String> {
        return Driver.combineLatest(paymentDate.asDriver(), cardWorkflow, addBankFormViewModel.saveToWallet.asDriver()).map {
            if $1 || !$2 {
                let startOfTodayDate = Calendar.current.startOfDay(for: Date())
                return startOfTodayDate.mmDdYyyyString
            }
            return $0.mmDdYyyyString
        }
    }
    
    lazy var shouldShowBillMatrixView: Driver<Bool> = self.cardWorkflow.map {
        if Environment.sharedInstance.opco != .bge && $0 {
            return true
        }
        return false
    }
    
    
    // MARK: - Review Payment Drivers
    
    var reviewPaymentSubmitButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(shouldShowTermsConditionsSwitchView, termsConditionsSwitchValue.asDriver(), isOverpaying, overpayingSwitchValue.asDriver(), isActiveSeveranceUser, activeSeveranceSwitchValue.asDriver()).map {
            var isValid = true
            if $0 {
                isValid = $1
            }
            if $2 {
                isValid = $3
            }
            if $4 {
                isValid = $5
            }
            return isValid
        }
    }
    
    lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> = self.cardWorkflow.map {
        return $0
    }
    
    var isOverpaying: Driver<Bool> {
        return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver().map { return Double($0) ?? 0 }).map {
            return $1 > $0
        }
    }
    
    var isOverpayingCard: Driver<Bool> {
        return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver().map { return Double($0) ?? 0 }, cardWorkflow).map {
            return $1 > $0 && $2
        }
    }
    
    var isOverpayingBank: Driver<Bool> {
        return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver().map { return Double($0) ?? 0 }, bankWorkflow).map {
            return $1 > $0 && $2
        }
    }
    
    var overpayingValueDisplayString: Driver<String> {
        return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver().map { return Double($0) ?? 0 }).map {
            return ($1 - $0).currencyString!
        }
    }
    
    lazy var shouldShowTermsConditionsSwitchView: Driver<Bool> = self.cardWorkflow.map {
        if Environment.sharedInstance.opco == .bge { // On BGE, Speedpay is only for credit cards
            return $0
        } else { // On ComEd/PECO, it's always shown for the terms and conditions agreement
            return true
        }
    }
    
    var shouldShowOverpaymentSwitchView: Driver<Bool> {
        return isOverpaying
    }

    lazy var paymentAmountDisplayString: Driver<String> = self.paymentAmount.asDriver().map {
        return "$\($0)"
    }
    
    var convenienceFeeDisplayString: Driver<String> {
        return Driver.combineLatest(convenienceFee, paymentAmount.asDriver().map { return Double($0) ?? 0 }).map {
            return (Environment.sharedInstance.opco == .bge && !self.accountDetail.value.isResidential) ? (($0 / 100) * $1).currencyString! : $0.currencyString!
        }
    }
    
    lazy var shouldShowAutoPayEnrollButton: Driver<Bool> = self.accountDetail.asDriver().map {
        return !$0.isAutoPay && $0.isAutoPayEligible
    }
    
    var totalPaymentDisplayString: Driver<String> {
        return Driver.combineLatest(paymentAmount.asDriver().map { return Double($0) ?? 0 }, reviewPaymentShouldShowConvenienceFeeBox, convenienceFee).map {
            if $1 {
                if (Environment.sharedInstance.opco == .bge) {
                    if (self.accountDetail.value.isResidential) {
                        return ($0 + $2).currencyString!
                    } else {
                        return ((1 + $2 / 100) * $0).currencyString!
                    }
                } else {
                    return ($0 + $2).currencyString!
                }
            } else {
                return $0.currencyString!
            }
        }
    }
    
    // MARK: - Payment Confirmation
    
    lazy var shouldShowConvenienceFeeLabel: Driver<Bool> = self.cardWorkflow.asDriver().map {
        return $0
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
