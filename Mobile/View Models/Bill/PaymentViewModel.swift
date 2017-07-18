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
    
    init(walletService: WalletService, paymentService: PaymentService, oneTouchPayService: OneTouchPayService, accountDetail: AccountDetail) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.oneTouchPayService = oneTouchPayService
        self.accountDetail = Variable(accountDetail)
        
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
                        if let otpItem = self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: AccountsStore.sharedInstance.customerIdentifier) {
                            for item in walletItems {
                                if item == otpItem && item.bankOrCard == .card {
                                    self.selectedWalletItem.value = item
                                    break
                                }
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
                        if let otpItem = self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: AccountsStore.sharedInstance.customerIdentifier) {
                            for item in walletItems {
                                if item == otpItem {
                                    self.selectedWalletItem.value = item
                                    break
                                }
                            }
                        } else if walletItems.count > 0 { // If no OTP item, default to first wallet item
                            self.selectedWalletItem.value = walletItems[0]
                        }
                    }
                }

                self.walletItems.value = walletItems
                
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
    
    // MARK: - Make Payment Drivers
    
    var makePaymentNextButtonEnabled: Driver<Bool> {
        return Driver.combineLatest(shouldShowContent, selectedWalletItem.asDriver(), paymentAmount.asDriver(), paymentAmountErrorMessage, cvvIsCorrectLength.asDriver(onErrorJustReturn: false)).map {
            if Environment.sharedInstance.opco == .bge {
                if let selectedWalletItem = $1 {
                    if selectedWalletItem.bankOrCard == .card {
                        return $0 && !$2.isEmpty && $3 == nil && $4
                    } else {
                        return $0 && !$2.isEmpty && $3 == nil
                    }
                } else {
                    return false
                }
            } else {
                return $0 && $1 != nil && !$2.isEmpty && $3 == nil
            }
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
    
    lazy var shouldShowPaymentAccountView: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        return $0 != nil
    }
    
    lazy var hasWalletItems: Driver<Bool> = self.walletItems.asDriver().map {
        guard let walletItems: [WalletItem] = $0 else { return false }
        return walletItems.count > 0
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
        return hasWalletItems
    }
    
    var paymentAmountErrorMessage: Driver<String?> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), accountDetail.asDriver(), paymentAmount.asDriver().map { Double($0) }, amountDue.asDriver()).map { (walletItem, accountDetail, paymentAmount, amountDue) -> String? in
            guard let walletItem: WalletItem = walletItem else { return nil }
            guard let paymentAmount: Double = paymentAmount else { return nil }
            
            let commercialUser = UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser)
            
            if walletItem.bankOrCard == .bank {
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
            } else {
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
        return Driver.combineLatest(selectedWalletItem.asDriver(), convenienceFee).map { (walletItem, fee) -> String in
            guard let walletItem = walletItem else { return "" }
            if walletItem.bankOrCard == .bank {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else {
                if Environment.sharedInstance.opco == .bge {
                    let feeStr = String(format: "A convenience fee will be applied by Western Union Speedpay, our payment partner. Residential accounts: $%.2f. Business accounts: %.2f%%.",
                                        self.accountDetail.value.billingInfo.residentialFee!, self.accountDetail.value.billingInfo.commercialFee!)
                    return NSLocalizedString(feeStr, comment: "")
                } else {
                    let feeStr = String(format: "A %@ convenience fee will be applied by Bill Matrix, our payment partner.", fee.currencyString!)
                    return NSLocalizedString(feeStr, comment: "")
                }
            }
        }
    }
    
    var paymentAmountFeeFooterLabelText: Driver<String> {
        return Driver.combineLatest(selectedWalletItem.asDriver(), convenienceFee).map { (walletItem, fee) -> String in
            guard let walletItem = walletItem else { return "" }
            if walletItem.bankOrCard == .bank {
                return NSLocalizedString("No convenience fee will be applied.", comment: "")
            } else {
                let feeStr = String(format: "Your payment includes a %@ convenience fee.",
                                    (Environment.sharedInstance.opco == .bge && !self.accountDetail.value.isResidential) ? String(format: "%.2f%%", fee) : fee.currencyString!)
                return NSLocalizedString(feeStr, comment: "")
            }
        }
    }
    
    var shouldShowPaymentDateView: Driver<Bool> {
        return hasWalletItems
    }
    
    var shouldShowStickyFooterView: Driver<Bool> {
        return hasWalletItems
    }
    
    lazy var selectedWalletItemImage: Driver<UIImage?> = self.selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return nil }
        if walletItem.bankOrCard == .bank {
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
        return Driver.combineLatest(isCashOnlyUser, hasWalletItems).map {
            return !$0 && !$1
        }
    }
    
    var shouldShowAddCreditCard: Driver<Bool> {
        return hasWalletItems.map(!)
    }
    
    var shouldShowWalletFooterView: Driver<Bool> {
        return hasWalletItems.map {
            if Environment.sharedInstance.opco == .bge {
                return true
            } else {
                return !$0
            }
        }
    }
    
    var isFixedPaymentDate: Driver<Bool> {
        return Driver.combineLatest(accountDetail.asDriver(), selectedWalletItem.asDriver()).map {
            if let walletItem = $1 {
                if walletItem.bankOrCard == .card {
                    return true
                }
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
        return Driver.combineLatest(paymentDate.asDriver(), selectedWalletItem.asDriver()).map {
            if let walletItem = $1 {
                if walletItem.bankOrCard == .card {
                    let startOfTodayDate = Calendar.current.startOfDay(for: Date())
                    return startOfTodayDate.mmDdYyyyString
                }
            }
            return $0.mmDdYyyyString
        }
    }
    
    lazy var shouldShowBillMatrixView: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        if let walletItem = $0 {
            if Environment.sharedInstance.opco != .bge && walletItem.bankOrCard == .card {
                return true
            }
        }
        return false
    }
    
    var walletFooterLabelText: Driver<String> {
        return hasWalletItems.map {
            if Environment.sharedInstance.opco == .bge {
                if $0 {
                    return NSLocalizedString("Any payment made for less than the total amount due or after the indicated due date may result in your service being disconnected. Payments may take up to two business days to reflect on your account.", comment: "")
                } else {
                    return NSLocalizedString("We accept: VISA, MasterCard, Discover, and American Express. Small business customers cannot use VISA.", comment: "")
                }
            } else {
                return NSLocalizedString("Up to three payment accounts for credit cards and bank accounts may be saved.\n\nWe accept: Discover, MasterCard, and Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo. American Express is not accepted at this time.", comment: "")
            }
        }
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
    
    lazy var reviewPaymentShouldShowConvenienceFeeBox: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return false }
        return walletItem.bankOrCard == .card
    }
    
    var isOverpaying: Driver<Bool> {
        return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver().map { return Double($0) ?? 0 }).map {
            return $1 > $0
        }
    }
    
    var overpayingValueDisplayString: Driver<String> {
        return Driver.combineLatest(amountDue.asDriver(), paymentAmount.asDriver().map { return Double($0) ?? 0 }).map {
            return ($1 - $0).currencyString!
        }
    }
    
    lazy var shouldShowTermsConditionsSwitchView: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        guard let walletItem: WalletItem = $0 else { return false }
        if Environment.sharedInstance.opco == .bge { // On BGE, Speedpay is only for credit cards
            return walletItem.bankOrCard == .card
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
    
    lazy var convenienceFeeDisplayString: Driver<String> = self.convenienceFee.map {
        return (Environment.sharedInstance.opco == .bge && !self.accountDetail.value.isResidential) ? String(format: "%.2f%%", $0) : $0.currencyString!
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
    
    lazy var shouldShowConvenienceFeeLabel: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        if let walletItem = $0 {
            if walletItem.bankOrCard == .card {
                return true
            }
        }
        return false
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
