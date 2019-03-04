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
    
    let accountDetail: AccountDetail
    let initialEnrollmentStatus: Variable<EnrollmentStatus>
    let selectedWalletItem = Variable<WalletItem?>(nil)
    
    // --- Settings --- //
    let userDidChangeSettings = Variable(false)
    let userDidChangeBankAccount = Variable(false)
    let userDidReadTerms = Variable(false)
    
    let amountToPay = Variable<AmountType>(.amountDue)
    let whenToPay = Variable<PaymentDateType>(.onDueDate)
    
    let amountNotToExceed = Variable(0.0)
    let numberOfDaysBeforeDueDate = Variable(0)
    // ---------------- //

    required init(paymentService: PaymentService, accountDetail: AccountDetail) {
        self.paymentService = paymentService
        self.accountDetail = accountDetail
        initialEnrollmentStatus = Variable(accountDetail.isAutoPay ? .enrolled : .unenrolled)
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
                if let walletItemId = autoPayInfo.walletItemId, let masked4 = autoPayInfo.paymentAccountLast4 {
                    self.selectedWalletItem.value = WalletItem(walletItemID: walletItemId,
                                                               maskedWalletItemAccountNumber: masked4,
                                                               nickName: autoPayInfo.paymentAccountNickname,
                                                               paymentMethodType: .ach,
                                                               bankName: nil,
                                                               expirationDate: nil,
                                                               isDefault: false,
                                                               bankOrCard: .bank,
                                                               isTemporary: false)
                }
                
                if let amountType = autoPayInfo.amountType {
                    self.amountToPay.value = amountType
                }
                
                if let amountThreshold = autoPayInfo.amountThreshold {
                    self.amountNotToExceed.value = amountThreshold
                }
                
                if let paymentDaysBeforeDue = autoPayInfo.paymentDaysBeforeDue {
                    self.numberOfDaysBeforeDueDate.value = paymentDaysBeforeDue
                    self.whenToPay.value = paymentDaysBeforeDue == 0 ? .onDueDate : .beforeDueDate
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
        let daysBefore = whenToPay.value == .onDueDate ? 0 : numberOfDaysBeforeDueDate.value
        paymentService.enrollInAutoPayBGE(accountNumber: accountDetail.accountNumber,
                                          walletItemId: selectedWalletItem.value!.walletItemID,
                                          amountType: amountToPay.value,
                                          amountThreshold: String(amountNotToExceed.value),
                                          paymentDaysBeforeDue: String(daysBefore),
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
    
    private(set) lazy var showUnenrollFooter: Driver<Bool> = initialEnrollmentStatus.asDriver().map {
        $0 == .enrolled
    }
    
    private(set) lazy var shouldShowContent: Driver<Bool> = Driver.combineLatest(self.isFetchingAutoPayInfo.asDriver(), self.isError.asDriver()) {
        return !$0 && !$1
    }
    
    private(set) lazy var shouldShowWalletItem: Driver<Bool> = self.selectedWalletItem.asDriver().map {
        return $0 != nil
    }
    
    private(set) lazy var bankAccountButtonImage: Driver<UIImage> = self.selectedWalletItem.asDriver().map {
            if let walletItem = $0 {
                return walletItem.paymentMethodType.imageMini
            } else {
                return #imageLiteral(resourceName: "bank_building_mini_white_bg")
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

}
