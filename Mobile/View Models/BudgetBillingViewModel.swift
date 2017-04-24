//
//  BudgetBillingViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class BudgetBillingViewModel {
    
    let disposeBag = DisposeBag()
    
    var account: Account?
    
    let initialEnrollment = true
    let currentEnrollment: Variable<Bool>!
    
    //let submitButtonEnabled = Variable(false)
    
    let enrolling = Variable(false)
    let unenrolling = Variable(false)
    var selectedUnenrollmentReason = Variable(-1)
    
    required init() {
        currentEnrollment = Variable(initialEnrollment)
        currentEnrollment.asObservable().subscribe(onNext: { enrolled in
            self.enrolling.value = !self.initialEnrollment && enrolled
            self.unenrolling.value = self.initialEnrollment && !enrolled
        }).addDisposableTo(disposeBag)
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(enrolling.asObservable(), unenrolling.asObservable(), selectedUnenrollmentReason.asObservable()) {
            if $0 { return true }
            if $1 && $2 != -1 { return true }
            return false
        }
    }
    
}

