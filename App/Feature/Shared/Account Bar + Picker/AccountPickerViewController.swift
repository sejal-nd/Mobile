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
    
    private let accountService = ServiceFactory.createAccountService()
    
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
        
        AuthenticatedService.fetchAccounts {  [weak self] result in
            switch result {
            case .success(_):
                guard let self = self else { return }
                self.accountPicker.setLoading(false)
                self.accountPicker.refresh()
            case .failure(_):
                MCSApi.shared.logout()
                NotificationCenter.default.post(name: .didReceiveAccountListError, object: self)
            }
        }
        
//        accountService.fetchAccounts()
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] _ in
//                guard let self = self else { return }
//                self.accountPicker.setLoading(false)
//                self.accountPicker.refresh()
//            }, onError: { _ in
//                MCSApi.shared.logout()
//                NotificationCenter.default.post(name: .didReceiveAccountListError, object: self)
//            }).disposed(by: disposeBag)
    }
        
}

