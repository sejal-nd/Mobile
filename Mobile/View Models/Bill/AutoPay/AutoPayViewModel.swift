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
        case enrolling, isEnrolled, unenrolling
    }
    
    let enrollmentStatus: Variable<AutoPayEnrollmentStatus>
    
    let accountDetail: AccountDetail
    
    let bankAccountType = Variable<BankAccountType>(.checking)
    let nameOnAccount = Variable("")
    let routingNumber = Variable("")
    let accountNumber = Variable("")
    let confirmAccountNumber = Variable("")
    let termsAndConditionsCheck: Variable<Bool>
    let selectedUnenrollmentReason = Variable<String?>(nil)
    
    required init(withAccountDetail accountDetail: AccountDetail) {
        self.accountDetail = accountDetail
        enrollmentStatus = Variable(accountDetail.isAutoPay ? .isEnrolled:.enrolling)
        termsAndConditionsCheck = Variable(Environment.sharedInstance.opco != .comEd)
    }
    
    lazy var nameOnAccountHasText: Driver<Bool> = self.nameOnAccount.asDriver()
        .map { !$0.isEmpty }
        .distinctUntilChanged()
    
    lazy var nameOnAccountIsValid: Driver<Bool> = self.nameOnAccount.asDriver()
        .map {
            var trimString = $0.components(separatedBy: CharacterSet.whitespaces).joined(separator: "")
            trimString = trimString.components(separatedBy: CharacterSet.alphanumerics).joined(separator: "")
            return trimString.isEmpty
        }
        .distinctUntilChanged()
    
    lazy var routingNumberIsValid: Driver<Bool> = self.routingNumber.asDriver()
        .map { $0.characters.count == 9 }
        .distinctUntilChanged()
    
    lazy var accountNumberHasText: Driver<Bool> = self.accountNumber.asDriver()
        .map { !$0.isEmpty }
        .distinctUntilChanged()
    
    lazy var accountNumberIsValid: Driver<Bool> = self.accountNumber.asDriver()
        .map { 8...17 ~= $0.characters.count }
        .distinctUntilChanged()
    
    lazy var confirmAccountNumberMatches: Driver<Bool> = Driver.combineLatest(self.accountNumber.asDriver(),
                                                                              self.confirmAccountNumber.asDriver())
        .map(==)
        .distinctUntilChanged()
    
    lazy var canSubmitNewAccount: Driver<Bool> = {
        var validationDrivers = [self.nameOnAccountHasText,
                                 self.routingNumberIsValid,
                                 self.accountNumberHasText,
                                 self.accountNumberIsValid,
                                 self.confirmAccountNumberMatches]
        
        if Environment.sharedInstance.opco == .comEd {
            validationDrivers.append(self.termsAndConditionsCheck.asDriver())
        }
        
        return Driver.combineLatest(validationDrivers)
            .map { !$0.contains(false) }
            .distinctUntilChanged()
    }()
    
    lazy var canSubmitUnenroll: Driver<Bool> = self.selectedUnenrollmentReason.asDriver().map { $0 != nil }
    
    lazy var canSubmit: Driver<Bool> = Driver.combineLatest(self.enrollmentStatus.asDriver(),
                                                            self.canSubmitNewAccount,
                                                            self.canSubmitUnenroll)
        .map { status, canSubmitNewAccount, canSubmitUnenroll in
            switch status {
            case .enrolling:
                return canSubmitNewAccount
            case .isEnrolled, .unenrolling:
                return canSubmitUnenroll
            }
        }
        .distinctUntilChanged()
    
    lazy var nameOnAccountErrorText: Driver<String?> = self.nameOnAccountIsValid.asDriver()
        .distinctUntilChanged()
        .map { $0 ? nil: NSLocalizedString("Can only contain letters, numbers, and spaces", comment: "") }
    
    lazy var routingNumberErrorText: Driver<String?> = self.routingNumber.asDriver()
        .map { $0.characters.count == 9 || $0.isEmpty }
        .distinctUntilChanged()
        .map { $0 ? nil: NSLocalizedString("Must be 9 digits", comment: "") }
    
    lazy var accountNumberErrorText: Driver<String?> = self.accountNumber.asDriver()
        .map { 8...17 ~= $0.characters.count }
        .distinctUntilChanged()
        .map { $0 ? nil: NSLocalizedString("Must be between 8-17 digits", comment: "") }
    
    lazy var confirmAccountNumberErrorText: Driver<String?> = Driver.combineLatest(self.confirmAccountNumber.asDriver().map { $0.isEmpty },
                                                                                   self.confirmAccountNumberMatches)
        .map { $0 || $1 }
        .distinctUntilChanged()
        .map { $0 ? nil: NSLocalizedString("Account numbers do not match", comment: "") }
    
    lazy var confirmAccountNumberIsValid: Driver<Bool> = self.confirmAccountNumberErrorText.map { $0 == nil }
    
    lazy var confirmAccountNumberIsEnabled: Driver<Bool> = self.accountNumberHasText
    
    let shouldShowTermsAndConditionsCheck = Environment.sharedInstance.opco == .comEd
    
    var shouldShowThirdPartyLabel: Bool {
        return Environment.sharedInstance.opco == .peco && (self.accountDetail.isSupplier || self.accountDetail.isDualBillOption)
    }
    
    let reasonStrings = [String(format: NSLocalizedString("Closing %@ account", comment: ""), Environment.sharedInstance.opco.displayString),
                         NSLocalizedString("Changing bank account", comment: ""),
                         NSLocalizedString("Dissatisfied with the program", comment: ""),
                         NSLocalizedString("Program no longer meets my needs", comment: ""),
                         NSLocalizedString("Other", comment: "")]
    
    lazy var footerText: Driver<String> = self.enrollmentStatus.asDriver().map { enrollmentStatus in
		var footerText: String
        switch (Environment.sharedInstance.opco, enrollmentStatus) {
        case (.peco, .enrolling):
            footerText = NSLocalizedString("Your recurring payment will apply to the next PECO bill you receive. You will need to submit a payment for your current PECO bill if you have not already done so.", comment: "")
        case (.comEd, .enrolling):
            footerText = NSLocalizedString("Your recurring payment will apply to the next ComEd bill you receive. You will need to submit a payment for your current ComEd bill if you have not already done so.", comment: "")
        case (.peco, .isEnrolled):
            footerText = NSLocalizedString("Changing your bank account information takes up to 7 days to process. If this change is submitted less than 7 days prior to your next due date, the funds may be deducted from your original bank account.", comment: "")
        case (.comEd, .isEnrolled):
            footerText = NSLocalizedString("If this change is submitted more than 4 business days prior to the bill due date, you will need to pay your current bill using another payment method because the existing bank information on file will be canceled. If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        case (.peco, .unenrolling),
             (.comEd, .unenrolling):
            footerText = NSLocalizedString("If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        default:
            fatalError("BGE account attempted to access the ComEd/PECO AutoPay screen.")
        }
		
		if self.shouldShowThirdPartyLabel {
			footerText += "\n\n" + NSLocalizedString("Please note that AutoPay will only include PECO charges. Energy Supply charges are billed separately by your chosen generation provider.", comment: "")
		}
		
		return footerText
    }
    
}
