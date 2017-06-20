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
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var bottomBarShadowView: UIView!
    
    @IBOutlet weak var bankImageView: UIImageView!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var oneTouchPayCardView: UIView!
    @IBOutlet weak var oneTouchPayCardLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var bottomBarLabel: UILabel!
    
    @IBOutlet weak var oneTouchPayDescriptionLabel: UILabel!
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    @IBOutlet weak var oneTouchPayLabel: UILabel!

    @IBOutlet weak var deleteAccountButton: ButtonControl!
    @IBOutlet weak var deleteBankAccountLabel: UILabel!
    
    @IBOutlet weak var walletItemBGView: UIView!

    var gradientLayer = CAGradientLayer()
    
    var viewModel = EditBankAccountViewModel(walletService: ServiceFactory.createWalletService())
    
    let oneTouchPayService = ServiceFactory.createOneTouchPayService()

    override func viewDidLoad() {
        super.viewDidLoad()
    
        buildNavigationButtons()
        buildGradientAndBackgrounds()
        
        title = NSLocalizedString("Edit Bank Account", comment: "")
        
        accountIDLabel.textColor = .blackText
        oneTouchPayCardLabel.textColor = .blackText
        oneTouchPayCardLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        oneTouchPayDescriptionLabel.textColor = .blackText
        oneTouchPayDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        oneTouchPayDescriptionLabel.text = oneTouchPayService.getOneTouchPayDisplayString(forCustomerNumber: viewModel.accountDetail.customerInfo.number)
        oneTouchPayLabel.textColor = .blackText
        oneTouchPayLabel.text = NSLocalizedString("One Touch Pay", comment: "")
        nicknameLabel.textColor = .blackText

        deleteAccountButton.accessibilityLabel = NSLocalizedString("Delete bank account", comment: "")
        deleteBankAccountLabel.font = SystemFont.regular.of(textStyle: .headline)
        deleteBankAccountLabel.textColor = .actionBlue
        
        bindWalletItemToViewElements()
    }
    
    func buildGradientAndBackgrounds() {
        walletItemBGView.backgroundColor = .primaryColor
        
        innerContentView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        innerContentView.layer.cornerRadius = 15
        
        gradientView.layer.cornerRadius = 15
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 238/255, green: 242/255, blue: 248/255, alpha: 1).cgColor
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        

        
        bottomBarShadowView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        bottomBarView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        bottomBarLabel.textColor = .blackText
    }
    
    func buildNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        viewModel.saveButtonIsEnabled().bind(to: saveButton.rx.isEnabled).addDisposableTo(disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        innerContentView.layoutIfNeeded()
        
        // Round only the top corners
        gradientLayer.frame = gradientView.frame
        
        let gradientPath = UIBezierPath(roundedRect:gradientLayer.bounds,
                                        byRoundingCorners:[.topLeft, .topRight],
                                        cornerRadii: CGSize(width: 15, height:  15))
        let gradientMaskLayer = CAShapeLayer()
        gradientMaskLayer.path = gradientPath.cgPath
        gradientLayer.mask = gradientMaskLayer
        
        // Round only the bottom corners
        let bottomBarPath = UIBezierPath(roundedRect:bottomBarView.bounds,
                                         byRoundingCorners:[.bottomLeft, .bottomRight],
                                         cornerRadii: CGSize(width: 15, height:  15))
        let bottomBarMaskLayer = CAShapeLayer()
        bottomBarMaskLayer.path = bottomBarPath.cgPath
        bottomBarView.layer.mask = bottomBarMaskLayer
    }

    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func bindWalletItemToViewElements() {
        let walletItem = viewModel.walletItem!

        // Nickname
        let opco = Environment.sharedInstance.opco
        
        if let nickname = walletItem.nickName {
            if opco == .bge {
                if let bankAccountType = walletItem.bankAccountType {
                    nicknameLabel.text = "\(nickname), \(bankAccountType.rawValue.uppercased())"
                } else {
                    nicknameLabel.text = nickname.uppercased()
                }
            } else {
                nicknameLabel.text = nickname.uppercased()
            }
        } else {
            if opco == .bge {
                if let bankAccountType = walletItem.bankAccountType {
                    nicknameLabel.text = bankAccountType.rawValue.uppercased()
                }
            } else {
                nicknameLabel.text = ""
            }
        }
        
        if let last4Digits = walletItem.maskedWalletItemAccountNumber {
            accountIDLabel.text = "**** \(last4Digits)"
            accountIDLabel.accessibilityLabel = String(format: NSLocalizedString(", Account number ending in %@", comment: ""), last4Digits)
        } else {
            accountIDLabel.text = ""
        }
        
        bottomBarLabel.text = NSLocalizedString("No Fee Applied", comment: "") // Default display
        bankImageView.isAccessibilityElement = true
        bankImageView.accessibilityLabel = NSLocalizedString("Bank account", comment: "")
        switch opco {
        case .comEd, .peco:
            bankImageView.image = #imageLiteral(resourceName: "opco_bank")
        case .bge:
            bankImageView.image = #imageLiteral(resourceName: "opco_bank")
            
            switch walletItem.walletItemStatusTypeBGE! {
            case .pndWait:
                bottomBarLabel.font = OpenSans.italic.of(textStyle: .footnote)
                bottomBarLabel.textColor = .deepGray
                bottomBarLabel.text = NSLocalizedString("Verification Status: Processing", comment: "")
            case .pndActive:
                bottomBarLabel.font = OpenSans.italic.of(textStyle: .footnote)
                bottomBarLabel.textColor = .deepGray
                bottomBarLabel.text = NSLocalizedString("Verification Status: Pending", comment: "")
            case .cancel:
                bottomBarLabel.font = OpenSans.italic.of(textStyle: .footnote)
                bottomBarLabel.textColor = .deepGray
                bottomBarLabel.text = NSLocalizedString("Verification Status: Cancelled", comment: "")
            case .bad_active:
                bottomBarLabel.font = OpenSans.italic.of(textStyle: .footnote)
                bottomBarLabel.textColor = .deepGray
                bottomBarLabel.text = NSLocalizedString("Verification Status: Failed", comment: "")
            case .deleted:
                break
            case .active:
                bottomBarLabel.textColor = .successGreenText
                bottomBarLabel.text = NSLocalizedString("Verification Status: Active", comment: "")
            }

        }
        
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.oneTouchPay).addDisposableTo(disposeBag)
        
        oneTouchPayCardView.isHidden = true
        let oneTouchPayWalletItem = oneTouchPayService.oneTouchPayItem(forCustomerNumber: viewModel.accountDetail.customerInfo.number)
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
    
    ///
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSavePress() {
        view.endEditing(true)
        
        let customerNumber = viewModel.accountDetail.customerInfo.number
        
        var shouldShowOneTouchPayReplaceWarning = false
        var shouldShowOneTouchPayDisableWarning = false
        let otpItem = self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: customerNumber)
        if self.viewModel.oneTouchPay.value {
            if otpItem != nil && otpItem != self.viewModel.walletItem {
                shouldShowOneTouchPayReplaceWarning = true
            }
        } else {
            if otpItem == self.viewModel.walletItem {
                shouldShowOneTouchPayDisableWarning = true
            }
        }
        
        let saveBankAccountChanges = { (oneTouchPay: Bool) in
            if oneTouchPay {
                self.oneTouchPayService.setOneTouchPayItem(walletItemID: self.viewModel.walletItem.walletItemID!, maskedWalletItemAccountNumber: self.viewModel.walletItem.maskedWalletItemAccountNumber!, paymentCategoryType: .check, forCustomerNumber: customerNumber)
            } else {
                self.oneTouchPayService.deleteTouchPayItem(forCustomerNumber: customerNumber)
            }
            
            self.delegate?.editBankAccountViewControllerDidEditAccount(self, message: NSLocalizedString("Changes saved", comment: ""))
            _ = self.navigationController?.popViewController(animated: true)
        }
        
        if shouldShowOneTouchPayReplaceWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("One Touch Pay", comment: ""), message: NSLocalizedString("Are you sure you want to replace your current One Touch Pay payment account?", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                saveBankAccountChanges(true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else if shouldShowOneTouchPayDisableWarning {
            let alertVc = UIAlertController(title: NSLocalizedString("One Touch Pay", comment: ""), message: NSLocalizedString("Are you sure you want to turn off One Touch Pay? You will no longer be able to pay from the home screen, and your payment will no longer be set as default.", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Turn Off", comment: ""), style: .default, handler: { _ in
                saveBankAccountChanges(false)
            }))
            self.present(alertVc, animated: true, completion: nil)
        } else {
            saveBankAccountChanges(viewModel.oneTouchPay.value)
        }

    }

    ///
    func deleteBankAccount() {
        var messageString = NSLocalizedString("Are you sure you want to delete this Bank Account? Note: If you proceed, all payments scheduled for today's date will still be processed. Pending payments for future dates using this account will be cancelled and you will need to reschedule your payment with another bank account.", comment: "")
        
        if Environment.sharedInstance.opco == .bge {
            messageString = NSLocalizedString("Deleting this payment account will also delete all the pending payments associated with this payment account. Please click 'Delete' to delete this payment account.", comment: "")
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Delete Bank Account", comment: ""), message: messageString, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
            LoadingView.show()
            self.viewModel.deleteBankAccount(onSuccess: {
                let customerNumber = self.viewModel.accountDetail.customerInfo.number
                if self.oneTouchPayService.oneTouchPayItem(forCustomerNumber: customerNumber) == self.viewModel.walletItem {
                    self.oneTouchPayService.deleteTouchPayItem(forCustomerNumber: customerNumber)
                }
                LoadingView.hide()
                self.delegate?.editBankAccountViewControllerDidEditAccount(self, message: NSLocalizedString("Bank account deleted", comment: ""))
                _ = self.navigationController?.popViewController(animated: true)
            }, onError: { errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    
}
