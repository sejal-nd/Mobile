//
//  EditAccountNickNameViewController.swift
//  BGE
//
//  Created by Majumdar, Amit on 28/05/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

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
        if let accountNickName = accountPicker.currentAccount?.accountNickname {
            viewModel.storedAccountNickName = accountNickName
            viewModel.accountNickName.accept(accountNickName)
            nickNametextField.textField.text = viewModel.accountNickName.value
            viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
        }
    }
}

// MARK: - EditAccountNickNameViewController Private Methods
extension EditAccountNickNameViewController {
    
    private func prepareInterfaceBuilder() {
        title = NSLocalizedString("Edit Account Nickname", comment: "")
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        nickNametextField.placeholder = NSLocalizedString("Account Nickname", comment: "")
        nickNametextField.textField.text = viewModel.accountNickName.value
        nickNametextField.textField.autocorrectionType = .no
        nickNametextField.textField.returnKeyType = .done
        nickNametextField.textField.textContentType = .nickname
        nickNametextField.textField.delegate = self
        viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    func onContinuePress() {
        
    }
}

// MARK: - UITextFieldDelegate Methods
extension EditAccountNickNameViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        viewModel.accountNickName.accept(newString)
        viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
        // Restrict Username to not more than 25 characters
        return !(newString.count > 25)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
        if saveNicknameButton.isEnabled {
             onContinuePress()
             view.endEditing(true)
        } else {
             view.endEditing(true)
        }
        return false
    }
}
