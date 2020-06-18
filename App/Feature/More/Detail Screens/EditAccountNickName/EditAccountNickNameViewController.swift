//
//  EditAccountNickNameViewController.swift
//  Mobile
//
//  Created by Majumdar, Amit on 28/05/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

final class EditAccountNickNameViewController: AccountPickerViewController {
    
    /// `DisposeBag` instance
    private let disposeBag = DisposeBag()

    /// `Nickname`Text Field
    @IBOutlet weak private var nickNametextField: FloatLabelTextField!
    
    /// `Save Nickname` Button
    @IBOutlet weak private var saveNicknameButton: PrimaryButton!
    
    /// `EditNicknameViewModel` Instance
    private let viewModel = EditNicknameViewModel(accountService: ServiceFactory.createAccountService())
    
   // MARK: - View LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareInterfaceBuilder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - IBAction Methods
    @IBAction func saveAction(_ sender: UIButton) {
        performSaveOperation()
    }
}

// MARK: - AccountPickerDelegate Method Implementation
extension EditAccountNickNameViewController: AccountPickerDelegate {

    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchAccountDetail(isRefresh: false)
        if let accountNickName = accountPicker.currentAccount?.accountNickname,
           let accountNumber = accountPicker.currentAccount?.accountNumber {
            viewModel.storedAccountNickName = accountNickName
            viewModel.accountNumber = accountNumber
            viewModel.accountNickName.accept(accountNickName)
            nickNametextField.textField.text = viewModel.accountNickName.value
            viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
        }
    }
}

// MARK: - EditAccountNickNameViewController Private Methods
extension EditAccountNickNameViewController {
    
    /// This method customizes the initial layout
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
    
    /// This method performs operation of saving a nickname
    private func performSaveOperation() {
        LoadingView.show()
        view.endEditing(true)
        viewModel.setAccountNickname(onSuccess: { [weak self] in
            guard let self = self else { return }
            if let text = self.nickNametextField.textField.text {
                self.viewModel.storedAccountNickName = text
                self.viewModel.accountNickName.accept(text)
                self.viewModel.saveNicknameEnabled.asDriver().drive(self.saveNicknameButton.rx.isEnabled).disposed(by: self.disposeBag)
            }
            LoadingView.hide()
            }, onError: { [weak self] (errorMessage)  in
                LoadingView.hide()
                guard let self = self else { return }
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        })
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
            saveAction(saveNicknameButton)
            view.endEditing(true)
        } else {
            view.endEditing(true)
        }
        return false
    }
}
