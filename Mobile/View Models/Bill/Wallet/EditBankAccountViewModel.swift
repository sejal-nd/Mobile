//
//  EditBankAccountViewModel.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class EditBankAccountViewModel {
    
    let disposeBag = DisposeBag()
    
    let walletService: WalletService!
    
    var oneTouchPay = Variable(false)
    
    required init(walletService: WalletService) {
        self.walletService = walletService
    }

    
    func editBankAccount(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            onSuccess()
        }
    }
}
