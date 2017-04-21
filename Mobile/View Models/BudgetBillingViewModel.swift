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
    
    let submitButtonEnabled = Variable(false)
    let reasonForStoppingViewVisible = Variable(false)
    
    required init() {
        currentEnrollment = Variable(initialEnrollment)
        
        currentEnrollment.asObservable().subscribe(onNext: { enrolled in
            self.submitButtonEnabled.value = enrolled != self.initialEnrollment
            
            self.reasonForStoppingViewVisible.value = self.initialEnrollment && !enrolled
        }).addDisposableTo(disposeBag)
    }
    
}

