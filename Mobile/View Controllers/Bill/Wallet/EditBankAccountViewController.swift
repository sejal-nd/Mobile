//
//  EditBankAccountViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol EditBankAccountViewControllerDelegate: class {
    func editBankAccountViewControllerDidEditAccount(_ editBankAccountViewController: EditBankAccountViewController, message: String)
}

class EditBankAccountViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    weak var delegate: EditBankAccountViewControllerDelegate?
    
    @IBOutlet weak var innerContentView: UIView!
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var bankImageView: UIImageView!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var oneTouchPayCardView: UIView!
    @IBOutlet weak var oneTouchPayCardLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!

    @IBOutlet weak var deleteAccountButton: ButtonControl!
    @IBOutlet weak var deleteBankAccountLabel: UILabel!
    
    @IBOutlet weak var walletItemBGView: UIView!

    var gradientLayer = CAGradientLayer()
    
    var viewModel = EditBankAccountViewModel(walletService: ServiceFactory.createWalletService())
    
    var shouldPopToRootOnSave = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        buildNavigationButtons()
        buildGradientAndBackgrounds()
        
        title = NSLocalizedString("Edit Bank Account", comment: "")
        
        accountIDLabel.textColor = .blackText
        accountIDLabel.font = OpenSans.regular.of(textStyle: .title1)
        oneTouchPayCardLabel.font = SystemFont.regular.of(textStyle: .footnote)
        oneTouchPayCardLabel.textColor = .blackText
        oneTouchPayCardLabel.text = NSLocalizedString("Default", comment: "")
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayDescriptionLabel.text = viewModel.getOneTouchDisplayString()
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("Default Payment Method", comment: "")
        oneTouchPayLabel.font = SystemFont.regular.of(textStyle: .headline)
        nicknameLabel.textColor = .blackText
        nicknameLabel.font = OpenSans.semibold.of(textStyle: .footnote)

        deleteAccountButton.accessibilityLabel = NSLocalizedString("Delete bank account", comment: "")
        deleteBankAccountLabel.font = SystemFont.regular.of(textStyle: .headline)
        deleteBankAccountLabel.textColor = .actionBlue
        
        if viewModel.accountDetail.isCashOnly {
            oneTouchPayView.isHidden = true
        }
        
        bindWalletItemToViewElements()
    }
    
    func buildGradientAndBackgrounds() {
        walletItemBGView.backgroundColor = StormModeStatus.shared.isOn ? .stormModeBlack : .primaryColor
        
        innerContentView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        innerContentView.layer.cornerRadius = 15
        innerContentView.layer.masksToBounds = true
        
        gradientView.layer.cornerRadius = 15
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 238/255, green: 242/255, blue: 248/255, alpha: 1).cgColor
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func buildNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        viewModel.saveButtonIsEnabled().bind(to: saveButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        innerContentView.layoutIfNeeded()
        gradientLayer.frame = gradientView.frame
    }

    func bindWalletItemToViewElements() {
        let walletItem = viewModel.walletItem!

        // Nickname
        let opco = Environment.shared.opco
        
        if let nickname = walletItem.nickName {
            nicknameLabel.text = nickname.uppercased()
            if opco == .bge {
                if walletItem.bankOrCard == .bank {
                    if let bankAccountType = walletItem.bankAccountType {
                        if bankAccountType.rawValue.uppercased() == "SAVING"{
                            nicknameLabel.text = NSLocalizedString(String(format:"%@, SAVINGS", nickname),comment: "")
                        } else {
                            nicknameLabel.text = NSLocalizedString(String(format:"%@, CHECKING", nickname),comment: "")
                        }
                    }
                }
            }
        } else {
            nicknameLabel.text = ""
            if opco == .bge {
                if let bankAccountType = walletItem.bankAccountType {
                    nicknameLabel.text = bankAccountType.rawValue.uppercased()
                }
            }
        }
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            accountIDLabel.text = "**** \(last4Digits)"
            accountIDLabel.accessibilityLabel = String(format: NSLocalizedString(", Account number ending in %@", comment: ""), last4Digits)
        } else {
            accountIDLabel.text = ""
        }
        
        bankImageView.isAccessibilityElement = true
        bankImageView.accessibilityLabel = NSLocalizedString("Bank account", comment: "")

        bankImageView.image = #imageLiteral(resourceName: "opco_bank")

        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).disposed(by: disposeBag)
        
        oneTouchPayCardView.isHidden = true
        let oneTouchPayWalletItem = viewModel.oneTouchPayItem
        if (oneTouchPayWalletItem == viewModel.walletItem) {
            oneTouchPayCardView.isHidden = false
            viewModel.oneTouchPayInitialValue.value = true
            oneTouchPaySwitch.isOn = true
            oneTouchPaySwitch.sendActions(for: .valueChanged)
        }
        
    }

    @IBAction func onDeletePress(_ sender: Any) {
        deleteBankAccount()
    }
    
    @objc func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onSavePress() {
        view.endEditing(true)

        var shouldShowOneTouchPayReplaceWarning = false
        var shouldShowOneTouchPayDisableWarning = false
        let otpItem = viewModel.oneTouchPayItem
        if viewModel.oneTouchPay.value {
            if otpItem != nil && otpItem != viewModel.walletItem {
                shouldShowOneTouchPayReplaceWarning = true
            }
        } else {
            if otpItem == viewModel.walletItem {
                shouldShowOneTouchPayDisableWarning = true
            }
        }
        
        let saveBankAccountChanges = { [weak self] (oneTouchPay: Bool) in
            LoadingView.show()
            guard let self = self else { return }
            if oneTouchPay {
                self.viewModel.enableOneTouchPay(onSuccess: { [weak self] in
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.delegate?.editBankAccountViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
                    if self.shouldPopToRootOnSave {
                        if StormModeStatus.shared.isOn {
                            if let dest = self.navigationController?.viewControllers
                                .first(where: { $0 is StormModeBillViewController }) {
                                self.navigationController?.popToViewController(dest, animated: true)
                            } else {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }, onError: { [weak self] (errMessage: String) in
                    LoadingView.hide()
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self?.present(alertVc, animated: true, completion: nil)
                })
            } else {
                self.viewModel.deleteOneTouchPay(onSuccess: { [weak self] in
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.delegate?.editBankAccountViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
                    if self.shouldPopToRootOnSave {
                        if StormModeStatus.shared.isOn {
                            if let dest = self.navigationController?.viewControllers
                                .first(where: { $0 is StormModeBillViewController }) {
                                self.navigationController?.popToViewController(dest, animated: true)
                            } else {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }, onError: { [weak self] (errMessage: String) in
                    LoadingView.hide()
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self?.present(alertVc, animated: true, completion: nil)
                })
            }
        }
        
        if shouldShowOneTouchPayReplaceWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to replace your default payment method?", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                saveBankAccountChanges(true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else if shouldShowOneTouchPayDisableWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("Default Payment Method", comment: ""), message: NSLocalizedString("Are you sure you want to turn off your default payment method? You will no longer be able to pay from the Home screen.", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Turn Off", comment: ""), style: .default, handler: { _ in
                saveBankAccountChanges(false)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            saveBankAccountChanges(viewModel.oneTouchPay.value)
        }
    }

    ///
    func deleteBankAccount() {
        var messageString = NSLocalizedString("Are you sure you want to delete this Bank Account? Note: If you proceed, all payments scheduled for today's date will still be processed. Pending payments for future dates using this account will be cancelled and you will need to reschedule your payment with another bank account.", comment: "")
        
        if Environment.shared.opco == .bge {
            messageString = NSLocalizedString("Deleting this payment method will also delete all the pending payments associated with this payment method. Please tap 'Delete' to delete this payment method.", comment: "")
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Delete Bank Account", comment: ""), message: messageString, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { [weak self] _ in
            LoadingView.show()
            self?.viewModel.deleteBankAccount(onSuccess: { [weak self] in
                LoadingView.hide()
                guard let self = self else { return }
                self.delegate?.editBankAccountViewControllerDidEditAccount(self, message: NSLocalizedString("Bank Account deleted", comment: ""))
                if self.shouldPopToRootOnSave {
                    if StormModeStatus.shared.isOn {
                        if let dest = self.navigationController?.viewControllers
                            .first(where: { $0 is StormModeBillViewController }) {
                            self.navigationController?.popToViewController(dest, animated: true)
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })
        }))
        present(alertController, animated: true, completion: nil)
    }
    
}
