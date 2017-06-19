//
//  AutoPaySettingsViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

enum AmountToPay{
    case totalAmountDue
    case amountNotToExceed
}

enum WhenToPay {
    case onDueDate
    case beforeDueDate
}

enum HowLongForAutoPay {
    case untilCanceled
    case forNumberOfPayments
    case untilDate
}

class AutoPaySettingsViewModel {
    let disposeBag = DisposeBag()
    
    let amountToPay = Variable<AmountToPay>(.totalAmountDue)
    let whenToPay = Variable<WhenToPay>(.onDueDate)
    let howLongForAutoPay = Variable<HowLongForAutoPay>(.untilCanceled)
    
    let amountNotToExceed = Variable("")
    let numberOfPayments = Variable("")
    
    var primaryProfile = Variable<Bool>(false)
    
}
