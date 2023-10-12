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
import Toast

final class EditAccountNickNameViewController: AccountPickerViewController {
    
    /// `DisposeBag` instance
    private let disposeBag = DisposeBag()

    /// `Nickname`Text Field
    @IBOutlet weak private var nickNametextField: FloatLabelTextField!
    
    /// `Save Nickname` Button
    @IBOutlet weak private var saveNicknameButton: PrimaryButton!
    
    /// `EditNicknameViewModel` Instance
    private let viewModel = EditNicknameViewModel()
    
    /// `NSLayoutConstraint` instance for Footer Bottom View
    @IBOutlet weak private var footerBottomAnchor: NSLayoutConstraint!
    
    /// `Save Nickname` Button
    @IBOutlet weak private var resetNicknameButton: UIButton!
    
    /// Identifies whether device has a top notch or not
    var hasTopNotch: Bool {
        var safeAreaInset: CGFloat?
        if (UIApplication.shared.statusBarOrientation == .portrait) {
            safeAreaInset = UIApplication.shared.delegate?.window??.safeAreaInsets.top
        }
        else if (UIApplication.shared.statusBarOrientation == .landscapeLeft) {
            safeAreaInset = UIApplication.shared.delegate?.window??.safeAreaInsets.left
        }
        else if (UIApplication.shared.statusBarOrientation == .landscapeRight) {
            safeAreaInset = UIApplication.shared.delegate?.window??.safeAreaInsets.right
        }
        return safeAreaInset ?? .zero > 24
    }
    
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
    
    @IBAction func resetNicknameAction(_ sender: Any) {
        nickNametextField.textField.text = ""
        viewModel.accountNickName.accept("")
    }
    
    // MARK: - Deinitializer
    deinit {
        NotificationCenter.default.removeObserver(self)
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
            nickNametextField.textField.text = viewModel.accountNickName.value == accountNumber ? "" : viewModel.accountNickName.value
            viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
        }
    }
}

// MARK: - EditAccountNickNameViewController Private Methods
extension EditAccountNickNameViewController {
    
    /// This method customizes the initial layout
    private func prepareInterfaceBuilder() {
        title = NSLocalizedString("Edit Account Nickname", comment: "")
        observeNotifications()
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        nickNametextField.placeholder = NSLocalizedString("Account Nickname", comment: "")
        nickNametextField.textField.autocorrectionType = .no
        nickNametextField.textField.returnKeyType = .done
        nickNametextField.textField.textContentType = .nickname
        nickNametextField.textField.delegate = self
        nickNametextField.textField.text = viewModel.accountNickName.value
        resetNicknameButton.setTitleColor(.primaryColorDark, for: .normal)
        resetNicknameButton.titleLabel?.font = .bodyBold
        viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)

        if var text = nickNametextField.textField.text {
            text = (text == viewModel.accountNumber ? "" : text)
            enableResetNicknameButton(isEnabled: !(text.isEmpty))
        }
    }
    
    /// This method performs operation of saving a nickname
    private func performSaveOperation() {
        LoadingView.show()
        view.endEditing(true)
        viewModel.setAccountNickname(onSuccess: { [weak self] in
            guard let self = self else { return }
            LoadingView.hide()
            self.view.showToast(NSLocalizedString("Changes Saved", comment: ""))
            
            if let text = self.nickNametextField.textField.text {
                self.viewModel.storedAccountNickName = text
                self.viewModel.accountNickName.accept(text)
                self.viewModel.saveNicknameEnabled.asDriver().drive(self.saveNicknameButton.rx.isEnabled).disposed(by: self.disposeBag)
            }
            }, onError: { [weak self] (errorMessage)  in
                LoadingView.hide()
                guard let self = self else { return }
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        })
    }
    
    /// This method will observe Notifications
    private func observeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// This method adjusts Keyboard
    /// - Parameter notification: `Notification` instance
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        // view.endEditing() triggers the `keyboardWillHideNotification` with a non-zero height,
        // so only trust the keyboardFrameValue for a `keyboardWillShowNotification`
        var keyboardHeight: CGFloat = .zero
        if notification.name == UIResponder.keyboardWillShowNotification {
            keyboardHeight = keyboardFrameValue.cgRectValue.size.height
        }
        
        let options = UIView.AnimationOptions(rawValue: curve.uintValue << 16)
        UIView.animate(withDuration: duration, delay: .zero, options: options, animations: {
            self.footerBottomAnchor.constant = notification.name == UIResponder.keyboardWillShowNotification ? self.hasTopNotch ? keyboardHeight - 34 : keyboardHeight : keyboardHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func enableResetNicknameButton(isEnabled: Bool) {
        resetNicknameButton.setTitleColor(isEnabled ? .primaryColor : .neutralDark, for: .normal)
        resetNicknameButton.alpha = isEnabled ? 1.0 : 0.4
    }
}

// MARK: - UITextFieldDelegate Methods
extension EditAccountNickNameViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        viewModel.accountNickName.accept(newString)
        viewModel.saveNicknameEnabled.asDriver().drive(saveNicknameButton.rx.isEnabled).disposed(by: disposeBag)
        enableResetNicknameButton(isEnabled: !newString.isEmpty)
        // Restrict Username to be not more than 25 characters
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
