//
//  AlertPreferencesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AlertPreferencesViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var accountPickerContainerView: UIView!
    @IBOutlet weak var accountPickerSpacerView: UIView!
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Alert Preferences", comment: "")
        
        accountPickerContainerView.backgroundColor = .primaryColor
        if Environment.sharedInstance.opco == .bge {
            accountPicker.isHidden = true
            accountPickerSpacerView.isHidden = true
        }
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                break
            case .readyToFetchData:
                print("Alert Preferences - Fetch Data")
//                if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
//                    self.getOutageStatus()
//                } else if self.viewModel.currentOutageStatus == nil {
//                    self.getOutageStatus()
//                }
            }
        }).disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }
    


}

extension AlertPreferencesViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        print("Alert Preferences - Changed Account - Fetch Data")
    }
    
}
