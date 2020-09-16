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
    private var walletService: WalletService

    let isLoading = BehaviorRelay(value: false)
    let isError = BehaviorRelay(value: false)
    
    let accountDetail: AccountDetail
    let initialEnrollmentStatus: BehaviorRelay<EnrollmentStatus>
    var confirmationNumber: String?
    
    var walletItems: [WalletItem]?
    let selectedWalletItem = BehaviorRelay<WalletItem?>(value: nil)
    
    // --- Settings --- //
    let userDidChangeSettings = BehaviorRelay(value: false)
    let userDidChangeBankAccount = BehaviorRelay(value: false)
    let userDidReadTerms = BehaviorRelay(value: false)
    
    let amountToPay = BehaviorRelay<AmountType>(value: .amountDue)
    let whenToPay = BehaviorRelay<PaymentDateType>(value: .onDueDate)
    
    let amountNotToExceed = BehaviorRelay(value: 0.0)
    let numberOfDaysBeforeDueDate = BehaviorRelay(value: 0)
    // ---------------- //

    required init(paymentService: PaymentService, walletService: WalletService, accountDetail: AccountDetail) {
        self.paymentService = paymentService
        self.walletService = walletService
        self.accountDetail = accountDetail

        initialEnrollmentStatus = BehaviorRelay(value: accountDetail.isAutoPay ? .enrolled : .unenrolled)
    }
    
    func fetchData(onSuccess: (() -> Void)?, onError: ((String) -> Void)?) {
        var observables = [fetchWalletItems()]
        if initialEnrollmentStatus.value == .enrolled {
            observables.append(fetchAutoPayInfo())
        }
        
        isLoading.accept(true)
        isError.accept(false)
        Observable.zip(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.isLoading.accept(false)
                self.isError.accept(false)
                onSuccess?()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.isLoading.accept(false)
                self.isError.accept(true)
                onError?(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func fetchWalletItems() -> Observable<Void> {
        return walletService.fetchWalletItems()
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] walletItems in
                self?.walletItems = walletItems
            })
            .mapTo(())
    }
    
    func fetchAutoPayInfo() -> Observable<Void> {
        return paymentService.fetchBGEAutoPayInfo(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
            .observeOn(MainScheduler.instance)
            .do(onNext: { autoPayInfo in
                self.confirmationNumber = autoPayInfo.confirmationNumber
                
                // Sync up our view model with the existing AutoPay settings
                if let walletItemId = autoPayInfo.walletItemId, let masked4 = autoPayInfo.paymentAccountLast4 {
                    self.selectedWalletItem.accept(WalletItem(walletItemId: walletItemId,
                                                               maskedWalletItemAccountNumber: masked4,
                                                               nickName: autoPayInfo.paymentAccountNickname,
                                                               paymentMethodType: .ach,
                                                               bankName: nil,
                                                               expirationDate: nil,
                                                               isDefault: false,
                                                               isTemporary: false))
                }
                
                if let amountType = autoPayInfo.amountType {
                    self.amountToPay.accept(amountType)
                }
                
                if let amountThreshold = autoPayInfo.amountThreshold {
                    self.amountNotToExceed.accept(amountThreshold)
                }
                
                if let paymentDaysBeforeDue = autoPayInfo.paymentDaysBeforeDue {
                    self.numberOfDaysBeforeDueDate.accept(paymentDaysBeforeDue)
                    self.whenToPay.accept(paymentDaysBeforeDue == 0 ? .onDueDate : .beforeDueDate)
                }
            })
            .mapTo(())
    }
    
    func enroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let daysBefore = whenToPay.value == .onDueDate ? 0 : numberOfDaysBeforeDueDate.value
        paymentService.enrollInAutoPayBGE(accountNumber: accountDetail.accountNumber,
                                          walletItemId: selectedWalletItem.value?.walletItemId,
                                          amountType: amountToPay.value,
                                          amountThreshold: amountNotToExceed.value.twoDecimalString,
                                          paymentDaysBeforeDue: String(daysBefore))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func update(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        let daysBefore = whenToPay.value == .onDueDate ? 0 : numberOfDaysBeforeDueDate.value
        paymentService.updateAutoPaySettingsBGE(accountNumber: accountDetail.accountNumber,
                                          walletItemId: selectedWalletItem.value?.walletItemId,
                                          confirmationNumber: confirmationNumber!,
                                          amountType: amountToPay.value,
                                          amountThreshold: amountNotToExceed.value.twoDecimalString,
                                          paymentDaysBeforeDue: String(daysBefore))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func unenroll(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        paymentService.unenrollFromAutoPayBGE(accountNumber: accountDetail.accountNumber, confirmationNumber: confirmationNumber!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                onSuccess()
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private(set) lazy var showBottomLabel: Driver<Bool> =
        Driver.combineLatest(self.isLoading.asDriver(), self.initialEnrollmentStatus.asDriver()) {
            return !$0 && $1 != .enrolled
    }
    
    private(set) lazy var submitButtonEnabled: Driver<Bool> = Driver
        .combineLatest(initialEnrollmentStatus.asDriver(),
                       selectedWalletItem.asDriver(),
                       userDidChangeSettings.asDriver(),
                       userDidChangeBankAccount.asDriver(),
                       userDidReadTerms.asDriver())
        { initialEnrollmentStatus, selectedWalletItem, userDidChangeSettings, userDidChangeBankAccount, userDidReadTerms in
            if initialEnrollmentStatus == .unenrolled && selectedWalletItem != nil && userDidReadTerms { // Unenrolled with bank account selected
                return true
            }
            
            // Enrolled with a selected wallet item, changed settings or bank, read terms
            if initialEnrollmentStatus == .enrolled &&
                selectedWalletItem != nil &&
                (userDidChangeSettings || userDidChangeBankAccount) &&
                userDidReadTerms {
                return true
            }
            
            return false
    }
    
    private(set) lazy var userPerformedAnyChanges: Bool = userDidChangeSettings.value || userDidChangeBankAccount.value || userDidReadTerms.value
    
    private(set) lazy var showUnenrollFooter: Driver<Bool> = initialEnrollmentStatus.asDriver().map {
        $0 == .enrolled
    }
    
    private(set) lazy var shouldShowContent: Driver<Bool> = Driver.combineLatest(self.isLoading.asDriver(), self.isError.asDriver()) {
        return !$0 && !$1
    }
    
    private(set) lazy var shouldShowWalletItem: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        return $0 != nil
    }
    
    private(set) lazy var bankAccountButtonImage: Driver<UIImage> = self.selectedWalletItem.asDriver().map {
            if let walletItem = $0 {
                return walletItem.paymentMethodType.imageMini
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
        guard let walletItem = $0 else { return NSLocalizedString("Select Bank Account", comment: "") }
        return walletItem.accessibilityDescription()
    }
    
    private(set) lazy var settingsButtonAmountText: Driver<String> = Driver
        .combineLatest(amountToPay.asDriver(), amountNotToExceed.asDriver())
        { amountToPay, amountNotToExceed in
            switch amountToPay {
            case .upToAmount:
                return String.localizedStringWithFormat("Pay Maximum of %@", amountNotToExceed.currencyString)
            case .amountDue:
                return NSLocalizedString("Pay Total Amount Billed", comment: "")
            }
    }
    
    private(set) lazy var settingsButtonDaysBeforeText: Driver<String> = Driver
        .combineLatest(whenToPay.asDriver(), numberOfDaysBeforeDueDate.asDriver())
        { whenToPay, numberOfDays in
            switch whenToPay {
            case .onDueDate:
                return NSLocalizedString("On Due Date", comment: "")
            case .beforeDueDate:
                return String.localizedStringWithFormat("%@ Day%@ Before Due Date", String(numberOfDays), numberOfDays == 1 ? "":"s")
            }
    }
    
    private(set) lazy var settingsButtonA11yLabel: Driver<String> = Driver
        .combineLatest(settingsButtonAmountText,
                       settingsButtonDaysBeforeText)
        { String.localizedStringWithFormat("AutoPay settings. Selected %@, %@", $0, $1) }
    
    var learnMoreDescriptionText: String {
        if accountDetail.isResidential {
            if Environment.shared.opco.isPHI {
                let formatText = """
                           Enroll in AutoPay to have your payment automatically deducted from your bank account on your preferred payment date. Upon payment, you will receive a payment confirmation for your records.
                           
                           AutoPay will charge the amount billed each month or the maximum amount specified, up to a limit of %@, if applicable. You will receive a notification after your new bill is generated and an upcoming automatic payment is created. Upcoming automatic payments may be viewed or cancelled on the Bill & Payment Activity page. Submitting other payments may result in overpaying and a credit being applied to your account. Please ensure you have adequate funds in your bank account to cover the AutoPay deduction.
                           """
                let maxPaymentAmountString = accountDetail.billingInfo
                    .maxPaymentAmount(bankOrCard: .bank)
                    .currencyNoDecimalString
                return String(format: formatText, maxPaymentAmountString)
            } else {
                return NSLocalizedString("""
                Enroll in AutoPay to have your payment automatically deducted from your bank account on your preferred payment date. Upon payment, you will receive a payment confirmation for your records.
                
                AutoPay will charge the amount billed each month or the maximum amount specified, if applicable. You will receive a notification after your new bill is generated and an upcoming automatic payment is created. Upcoming automatic payments may be viewed or cancelled on the Bill & Payment Activity page. Submitting other payments may result in overpaying and a credit being applied to your account. Please ensure you have adequate funds in your bank account to cover the AutoPay deduction.
                """, comment: "")
            }
        } else {
            let formatText = """
            Enroll in AutoPay to have your payment automatically deducted from your bank account on your preferred payment date. Upon payment, you will receive a payment confirmation for your records.
            
            AutoPay will charge the amount billed each month or the maximum amount specified, up to a limit of %@, if applicable. You will receive a notification after your new bill is generated and an upcoming automatic payment is created. Upcoming automatic payments may be viewed or cancelled on the Bill & Payment Activity page. Submitting other payments may result in overpaying and a credit being applied to your account. Please ensure you have adequate funds in your bank account to cover the AutoPay deduction.
            """
            let maxPaymentAmountString = accountDetail.billingInfo
                .maxPaymentAmount(bankOrCard: .bank)
                .currencyNoDecimalString
            return String(format: formatText, maxPaymentAmountString)
        }
    }
    
    var bottomLabelText: String {
        let billingInfo = accountDetail.billingInfo
        if accountDetail.isAutoPay {
            return NSLocalizedString("""
            Editing or unenrolling in AutoPay will go into effect with your next bill. Any upcoming payments for your current bill may be viewed or canceled in Bill & Payment Activity.
            """, comment: "")
        } else if let netDueAmount = billingInfo.netDueAmount, netDueAmount > 0 {
            let formatText = "If you enroll today, AutoPay will begin with your next bill. You must submit a separate payment for your account balance of %@. Any past due amount is due immediately.".localized()
            return String(format: formatText, netDueAmount.currencyString)
        } else {
            return NSLocalizedString("""
            Enroll in AutoPay to have your payment automatically deducted from your bank account on your preferred payment date. Upon payment you will receive a payment confirmation for your records.
            """, comment: "")
        }
    }

}
