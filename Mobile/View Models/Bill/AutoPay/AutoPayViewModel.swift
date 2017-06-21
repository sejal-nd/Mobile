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
    
    enum EnrollmentStatus {
        case enrolling, isEnrolled, unenrolling
    }
    
    let enrollmentStatus: Variable<EnrollmentStatus>
    
    let bankAccountType = Variable<BankAccountType>(.checking)
    let nameOnAccount = Variable("")
    let routingNumber = Variable("")
    let accountNumber = Variable("")
    let confirmAccountNumber = Variable("")
    
    required init(withAccountDetail accountDetail: AccountDetail) {
        enrollmentStatus = Variable(accountDetail.isAutoPay ? .isEnrolled:.enrolling)
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
        .map { $0.characters.count >= 8 && $0.characters.count <= 17 }
        .distinctUntilChanged()
    
    lazy var confirmAccountNumberMatches: Driver<Bool> = Driver.combineLatest(self.accountNumber.asDriver(),
                                                            self.confirmAccountNumber.asDriver())
        .map(==)
        .distinctUntilChanged()
    
    lazy var canSubmit: Driver<Bool> = Driver.combineLatest([self.nameOnAccountHasText,
                                                             self.routingNumberIsValid,
                                                             self.accountNumberHasText,
                                                             self.accountNumberIsValid])
        .map { !$0.contains(false) }
        .distinctUntilChanged()
    
    lazy var confirmAccountNumberIsEnabled: Driver<Bool> = self.accountNumberHasText
    
    lazy var footerText: Driver<String> = self.enrollmentStatus.asDriver().map { enrollmentStatus in
        switch (Environment.sharedInstance.opco, enrollmentStatus) {
        case (.peco, .enrolling):
            return NSLocalizedString("Your recurring payment will apply to the next PECO bill you receive. You will need to submit a payment for your current PECO bill if you have not already done so.", comment: "")
        case (.comEd, .enrolling):
            return NSLocalizedString("Your recurring payment will apply to the next ComEd bill you receive. You will need to submit a payment for your current ComEd bill if you have not already done so.", comment: "")
        case (.peco, .isEnrolled):
            return NSLocalizedString("Changing your bank account information takes up to 7 days to process. If this change is submitted less than 7 days prior to your next due date, the funds may be deducted from your original bank account.", comment: "")
        case (.comEd, .isEnrolled):
            return NSLocalizedString("If this change is submitted more than 4 business days prior to the bill due date, you will need to pay your current bill using another payment method because the existing bank information on file will be canceled. If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        case (.peco, .unenrolling),
             (.comEd, .unenrolling):
            return NSLocalizedString("If this change is submitted less than 3 business days prior to the bill due date, the funds will be deducted from your original bank account.", comment: "")
        default:
            fatalError("BGE account attempted to access the ComEd/PECO AutoPay screen.")
        }
    }
    
}
