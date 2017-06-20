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
    
    required init(withAccountDetail accountDetail: AccountDetail) {
        enrollmentStatus = Variable(accountDetail.isAutoPay ? .isEnrolled:.enrolling)
    }
    
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
