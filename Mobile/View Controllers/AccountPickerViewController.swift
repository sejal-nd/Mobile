//
//  AccountPickerViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AccountPickerViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountPicker: AccountPicker!
    
    let accountPickerViewControllerWillAppear = PublishSubject<Void>()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AccountsStore.sharedInstance.currentAccount != accountPicker.currentAccount {
            accountPicker.updateCurrentAccount()
        }
        
        accountPickerViewControllerWillAppear.onNext()
    }
    
}
