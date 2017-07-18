//
//  AddBankFormViewViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 7/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AddBankFormViewModel {
    
    let walletService: WalletService!

    required init(walletService: WalletService) {
        self.walletService = walletService
    }
    
}
