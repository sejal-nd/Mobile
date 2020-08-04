//
//  AutoPayViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 6/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class AutoPayViewModel {
    
    let bag = DisposeBag()
    
    enum AutoPayEnrollmentStatus {
        case enrolled, unenrolled
    }
    
    let enrollmentStatus: BehaviorRelay<AutoPayEnrollmentStatus>
    
    let accountDetail: AccountDetail
    
    let checkingSavingsSegmentedControlIndex = BehaviorRelay(value: 0)
    let nameOnAccount = BehaviorRelay(value: "")
    let routingNumber = BehaviorRelay(value: "")
    let accountNumber = BehaviorRelay(value: "")
    let confirmAccountNumber = BehaviorRelay(value: "")
    let termsAndConditionsCheck: BehaviorRelay<Bool>
    let selectedUnenrollmentReason = BehaviorRelay<String?>(value: nil)
    
    let walletService: WalletService
    
    var bankName = ""
    
    required init(walletService: WalletService, accountDetail: AccountDetail) {
        self.walletService = walletService
        self.accountDetail = accountDetail
        enrollmentStatus = BehaviorRelay(value: accountDetail.isAutoPay ? .enrolled : .unenrolled)
        termsAndConditionsCheck = BehaviorRelay(value: Environment.shared.opco != .comEd)
    }
    
    func enroll() -> Observable<Bool> {
        let bankAccountType = checkingSavingsSegmentedControlIndex.value == 0 ? "checking" : "saving"
        
        let enrollRequest = AutoPayEnrollRequest(nameOfAccount: nameOnAccount.value, bankAccountType: bankAccountType, routingNumber: routingNumber.value, bankAccountNumber: accountNumber.value, isUpdate: false)
        
        return PaymentService.rx.autoPayEnroll(accountNumber: accountDetail.accountNumber, request: enrollRequest).map { _ in true }
    }
    
    func changeBank() -> Observable<Bool> {
        let bankAccountType = checkingSavingsSegmentedControlIndex.value == 0 ? "checking" : "saving"
        
        let enrollRequest = AutoPayEnrollRequest(nameOfAccount: nameOnAccount.value, bankAccountType: bankAccountType, routingNumber: routingNumber.value, bankAccountNumber: accountNumber.value, isUpdate: true)
        
        return PaymentService.rx.autoPayEnroll(accountNumber: accountDetail.accountNumber, request: enrollRequest).map { _ in true }
    }
    
    func unenroll() -> Observable<Bool> {
        GoogleAnalytics.log(event: .autoPayUnenrollOffer)
        let unenrollRequest = AutoPayUnenrollRequest(reason: selectedUnenrollmentReason.value!)
        return PaymentService.rx.autoPayUnenroll(accountNumber: accountNumber.value, request: unenrollRequest).map { _ in false }
    }
    
    func getBankName(onSuccess: @escaping () -> Void, onError: @escaping () -> Void) {
        walletService.fetchBankName(routingNumber: routingNumber.value)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] bankName in
                self?.bankName = bankName
                onSuccess()
            }, onError: { (error: Error) in
                onError()
            }).disposed(by: bag)
    }

    private(set) lazy var nameOnAccountHasText: Driver<Bool> = self.nameOnAccount.asDriver()
        .map { !$0.isEmpty }
        .distinctUntilChanged()
    
    private(set) lazy var nameOnAccountIsValid: Driver<Bool> = self.nameOnAccount.asDriver()
        .map {
            var trimString = $0.components(separatedBy: CharacterSet.whitespaces).joined(separator: "")
            trimString = trimString.components(separatedBy: CharacterSet.alphanumerics).joined(separator: "")
            return trimString.isEmpty
        }
        .distinctUntilChanged()
    
    private(set) lazy var routingNumberIsValid: Driver<Bool> = self.routingNumber.asDriver()
        .map { $0.count == 9 }
        .distinctUntilChanged()
    
    private(set) lazy var accountNumberHasText: Driver<Bool> = self.accountNumber.asDriver()
        .map { !$0.isEmpty }
        .distinctUntilChanged()
    
    private(set) lazy var accountNumberIsValid: Driver<Bool> = self.accountNumber.asDriver()
        .map { 4...17 ~= $0.count }
        .distinctUntilChanged()
    
    private(set) lazy var confirmAccountNumberMatches: Driver<Bool> =
        Driver.combineLatest(self.accountNumber.asDriver(),
                             self.confirmAccountNumber.asDriver(),
                             resultSelector: ==)
            .distinctUntilChanged()
    
    private(set) lazy var canSubmitNewAccount: Driver<Bool> = {
        var validationDrivers = [self.nameOnAccountHasText,
                                 self.routingNumberIsValid,
                                 self.accountNumberHasText,
                                 self.accountNumberIsValid,
                                 self.confirmAccountNumberMatches]
        
        if Environment.shared.opco == .comEd {
            validationDrivers.append(self.termsAndConditionsCheck.asDriver())
        }
        
        return Driver.combineLatest(validationDrivers)
            .map { !$0.contains(false) }
            .distinctUntilChanged()
    }()
    
    private(set) lazy var canSubmitUnenroll: Driver<Bool> = self.selectedUnenrollmentReason.asDriver().isNil().not()
        
    private(set) lazy var nameOnAccountErrorText: Driver<String?> = self.nameOnAccountIsValid.asDriver()
        .distinctUntilChanged()
        .map { $0 ? nil: NSLocalizedString("Can only contain letters, numbers, and spaces", comment: "") }
    
    private(set) lazy var routingNumberErrorText: Driver<String?> = self.routingNumber.asDriver()
        .map { $0.count == 9 || $0.isEmpty }
        .distinctUntilChanged()
        .map { $0 ? nil : NSLocalizedString("Must be 9 digits", comment: "") }
    
    private(set) lazy var accountNumberErrorText: Driver<String?> = self.accountNumber.asDriver()
        .map { 4...17 ~= $0.count || $0.isEmpty }
        .distinctUntilChanged()
        .map { $0 ? nil: NSLocalizedString("Must be between 4-17 digits", comment: "") }
    
    private(set) lazy var confirmAccountNumberErrorText: Driver<String?> = Driver.combineLatest(self.confirmAccountNumber.asDriver().map { $0.isEmpty },
                                                                                                self.confirmAccountNumberMatches)
        .map { $0 || $1 }
        .distinctUntilChanged()
        .map { $0 ? nil: NSLocalizedString("Account numbers do not match", comment: "") }
    
    private(set) lazy var confirmAccountNumberIsValid: Driver<Bool> = Driver.combineLatest(self.confirmAccountNumberErrorText.map { $0 == nil }, self.confirmAccountNumber.asDriver()) {
        return $0 && !$1.isEmpty
    }
    
    private(set) lazy var confirmAccountNumberIsEnabled: Driver<Bool> = self.accountNumberHasText
    
    let tacLabelText = NSLocalizedString("Yes, I have read, understand and agree to the terms and conditions below, and by checking this box, I authorize ComEd to regularly debit the bank account provided.\nI understand that my bank account will be automatically debited each billing period for the total amount due, that these are variable charges, and that my bill being posted in the ComEd mobile app acts as my notification.\nCustomers can see their bill monthly through the ComEd mobile app. Bills are delivered online during each billing cycle. Please note that this will not change your preferred bill delivery method.", comment: "")
    
    let tacSwitchAccessibilityLabel = "I agree to ComEd’s AutoPay Terms and Conditions"
    
    let shouldShowTermsAndConditionsCheck = Environment.shared.opco == .comEd
    
    var shouldShowThirdPartyLabel: Bool {
        return Environment.shared.opco == .peco && (accountDetail.isSupplier || accountDetail.isDualBillOption)
    }
    
    let reasonStrings = [String(format: NSLocalizedString("Closing %@ account", comment: ""), Environment.shared.opco.displayString),
                         NSLocalizedString("Changing bank account", comment: ""),
                         NSLocalizedString("Dissatisfied with the program", comment: ""),
                         NSLocalizedString("Program no longer meets my needs", comment: ""),
                         NSLocalizedString("Other", comment: "")]
    
    private(set) lazy var footerText: Driver<String?> = self.enrollmentStatus.asDriver().map { [weak self] enrollmentStatus in
        guard let self = self else { return nil }
		var footerText: String
        switch (Environment.shared.opco, enrollmentStatus) {
        case (.peco, .unenrolled):
            footerText = NSLocalizedString("Your recurring payment will apply to the next PECO bill you receive. You will need to submit a payment for your current PECO bill if you have not already done so.", comment: "")
        case (.comEd, .unenrolled):
            footerText = NSLocalizedString("Your recurring payment will apply to the next ComEd bill you receive. You will need to submit a payment for your current ComEd bill if you have not already done so.", comment: "")
        case (.ace, .unenrolled):
                   footerText = NSLocalizedString("Your recurring payment will apply to the next ComEd bill you receive. You will need to submit a payment for your current ComEd bill if you have not already done so.", comment: "")
        case (.delmarva, .unenrolled):
                   footerText = NSLocalizedString("Your recurring payment will apply to the next ComEd bill you receive. You will need to submit a payment for your current ComEd bill if you have not already done so.", comment: "")
        case (.pepco, .unenrolled):
                   footerText = NSLocalizedString("Your recurring payment will apply to the next ComEd bill you receive. You will need to submit a payment for your current ComEd bill if you have not already done so.", comment: "")
        case (.peco, .enrolled):
            footerText = NSLocalizedString("Changing your bank account information takes up to 7 days to process. If this change is submitted less than 7 days prior to your next due date, the funds may be deducted from your original bank account.", comment: "")
        case (.comEd, .enrolled):
            footerText = NSLocalizedString("If this change is submitted more than 4 business days prior to the bill due date, you will need to pay your current bill using another payment method because the existing bank information on file will be canceled. If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        case (.ace, .enrolled):
        footerText = NSLocalizedString("If this change is submitted more than 4 business days prior to the bill due date, you will need to pay your current bill using another payment method because the existing bank information on file will be canceled. If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        case (.delmarva, .enrolled):
        footerText = NSLocalizedString("If this change is submitted more than 4 business days prior to the bill due date, you will need to pay your current bill using another payment method because the existing bank information on file will be canceled. If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        case (.pepco, .enrolled):
        footerText = NSLocalizedString("If this change is submitted more than 4 business days prior to the bill due date, you will need to pay your current bill using another payment method because the existing bank information on file will be canceled. If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        default:
            fatalError("BGE account attempted to access the ComEd/PECO AutoPay screen.")
        }
		
		if self.shouldShowThirdPartyLabel {
			footerText += "\n\n" + NSLocalizedString("Please note that AutoPay will only include PECO charges. Energy Supply charges are billed separately by your chosen generation provider.", comment: "")
		}
		
		return footerText
    }
    
}
