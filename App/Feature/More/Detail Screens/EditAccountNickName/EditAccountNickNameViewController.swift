//
//  EditAccountNickNameViewController.swift
//  BGE
//
//  Created by Majumdar, Amit on 28/05/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit

class EditAccountNickNameViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()

    /// `Nickname`Text Field
    @IBOutlet weak var nickNametextField: FloatLabelTextField!
    
    /// `Save Nickname` Button
    @IBOutlet weak var saveNicknameButton: PrimaryButton!
    /// `EditNicknameViewModel` Instance
    let viewModel = EditNicknameViewModel(accountService: ServiceFactory.createAccountService(),
                                          authService: ServiceFactory.createAuthenticationService(),
                                          usageService: ServiceFactory.createUsageService(useCache: true))
    
   // MARK: - View LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareInterfaceBuilder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: - AccountPickerDelegate Method Implementation
extension EditAccountNickNameViewController: AccountPickerDelegate {

    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchAccountDetail(isRefresh: false)
    }
}

// MARK: - EditAccountNickNameViewController Private Methods
extension EditAccountNickNameViewController {
    
    private func prepareInterfaceBuilder() {
        title = NSLocalizedString("Edit Account Nickname", comment: "")
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        nickNametextField.placeholder = NSLocalizedString("Account Nickname", comment: "")
        nickNametextField.textField.autocorrectionType = .no
        nickNametextField.textField.returnKeyType = .done
        nickNametextField.textField.textContentType = .nickname
        viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
    }
}
