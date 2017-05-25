//
//  EditBankAccountViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class EditBankAccountViewController: UIViewController {
    
    var selectedWalletItem: WalletItem?

    @IBOutlet weak var walletItemDetailsView: UIView!
    @IBOutlet weak var bankImageView: UIImageView!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var oneTouchPayConfirmationLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    
    @IBOutlet weak var deleteAccountLabel: UILabel!
    @IBOutlet weak var deleteAccountButton: UIButton!
    
    @IBOutlet weak var walletItemBGView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindWalletItemToViewElements()
        
        //walletItemBGView.backgroundColor = UIColor.primaryColor
        
        title = NSLocalizedString("Edit Bank Account", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        deleteAccountButton.setImage(imageFrom(systemItem: .trash), for: .normal) // UIBarButtonSystemItemTrash, UIControlStateNormal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///
    func bindWalletItemToViewElements() {
        if let walletItem = selectedWalletItem {
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
            } else {
                accountIDLabel.text = ""
            }
            
            convenienceFeeLabel.text = NSLocalizedString("No Fee Applied", comment: "") // Default display
            switch opco {
            case .comEd, .peco:
                if walletItem.paymentCategoryType == .credit {
                    convenienceFeeLabel.text = NSLocalizedString("$2.35 Convenience Fee", comment: "")
                    if let paymentMethodType = walletItem.paymentMethodType {
                        switch paymentMethodType {
                        case .visa:
                            bankImageView.image = #imageLiteral(resourceName: "ic_visa")
                        case .mastercard:
                            bankImageView.image = #imageLiteral(resourceName: "ic_mastercard")
                        default:
                            bankImageView.image = #imageLiteral(resourceName: "ic_credit_placeholder")
                        }
                    }
                    
                } else if walletItem.paymentCategoryType == .check {
                    bankImageView.image = #imageLiteral(resourceName: "opco_bank")
                }
                
            case .bge:
                bankImageView.image = #imageLiteral(resourceName: "opco_bank")
                
                convenienceFeeLabel.textColor = .successGreenText
                convenienceFeeLabel.text = NSLocalizedString("Verification Status: Active", comment: "")
                
                // if credit card:
                // bottomBarLabel.text = NSLocalizedString("Fees: $1.50 Residential | 2.4% Business", comment: "")
            }
        }
        
        // TODO: Make this work
        oneTouchPayConfirmationLabel.isHidden = true
    }
    
    @IBAction func toggleOneTouch(_ sender: Any) {
    }
    
    ///
    func onCancelPress() {
        // We do this to cover the case where we push ForgotUsernameViewController from ForgotPasswordViewController.
        // When that happens, we want the cancel action to go straight back to LoginViewController.
        for vc in (navigationController?.viewControllers)! {
            guard let walletVC = vc as? WalletViewController else {
                continue
            }
            
            navigationController?.popToViewController(walletVC, animated: true)
            
            break
        }
    }
    
    func onSavePress() {
        view.endEditing(true)
        
        LoadingView.show()
//        viewModel.validateAccount(onSuccess: {
//            LoadingView.hide()
//            self.performSegue(withIdentifier: "forgotUsernameResultSegue", sender: self)
//        }, onNeedAccountNumber: {
//            LoadingView.hide()
//            self.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
//        }, onError: { (title, message) in
//            LoadingView.hide()
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
//            self.present(alertController, animated: true, completion: nil)
//        })
        
        for vc in (navigationController?.viewControllers)! {
            guard let walletVC = vc as? WalletViewController else {
                continue
            }
            
            LoadingView.hide()

            navigationController?.popToViewController(walletVC, animated: true)
            
            break
        }
    }

    func imageFrom(systemItem: UIBarButtonSystemItem)-> UIImage? {
        let tempItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)
        
        // add to toolbar and render it
        UIToolbar().setItems([tempItem], animated: false)
        
        // got image from real uibutton
        let itemView = tempItem.value(forKey: "view") as! UIView
        for view in itemView.subviews {
            if let button = view as? UIButton, let imageView = button.imageView {
                return imageView.image
            }
        }
        
        return nil
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func deleteBankAccountTextButton(_ sender: Any) {
        deleteBankAccount()
    }
    
    @IBAction func deleteBankAccountImageButton(_ sender: Any) {
        deleteBankAccount()
    }
    
    func deleteBankAccount() {
        var messageString = NSLocalizedString("Are you sure you want to delete this Bank Account? Note: If you proceed, all payments scheduled for today's date will still be processed. Pending payments for future dates using this account will be cancelled and you will need to reschedule your payment with another bank account.", comment: "")
        
        if Environment.sharedInstance.opco == .bge {
            messageString = NSLocalizedString("Deleting this payment account will also delete all the pending payments associated with this payment account. Please click 'Delete' to delete this payment account.", comment: "")
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Delete Bank Account", comment: ""), message: messageString, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
}
