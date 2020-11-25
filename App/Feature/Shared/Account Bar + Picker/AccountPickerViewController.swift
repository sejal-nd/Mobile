//
//  AccountPickerViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/4/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

enum AccountPickerViewControllerState {
    case loadingAccounts
    case readyToFetchData
}

class AccountPickerViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
        
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var accountPicker: AccountPicker!
    
    var defaultStatusBarStyle: UIStatusBarStyle { return .default }
    var safeAreaTop: CGFloat = 0
    var shouldLoadAccounts = true
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return defaultStatusBarStyle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard shouldLoadAccounts else { return }
        
        if AccountsStore.shared.currentIndex == nil {
            fetchAccounts()
        } else {
            accountPicker.refresh()
        }
    }
    
    func fetchAccounts() {
        accountPicker.setLoading(true)
        
        AccountService.fetchAccounts { [weak self] result in
            switch result {
            case .success:
                AccountService.fetchAccountDetails { [weak self] accountDetailsResult in
                    switch accountDetailsResult {
                    case .success(let accountDetail):
                        AccountsStore.shared.premiseNumber = accountDetail.premiseNumber
                        AccountsStore.shared.accountOpco = accountDetail.opcoType ?? Environment.shared.opco
                        self?.accountPicker.setLoading(false)
                        self?.accountPicker.refresh()
                        self?.setupUpdatedData()
                    case .failure:
                        AuthenticationService.logout()
                    }
                }
            case .failure:
                AuthenticationService.logout()
            }
        }
    }
    
    func setupUpdatedData() {
        // Override this method to re-populate data with latest Account Details
    }
    
}

