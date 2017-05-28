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
    
    var selectedWalletItem: WalletItem?

    @IBOutlet weak var innerContentView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var bottomBarShadowView: UIView!
    
    @IBOutlet weak var bankImageView: UIImageView!
    @IBOutlet weak var accountIDLabel: UILabel!

    @IBOutlet weak var oneTouchPayView: UIView!
    @IBOutlet weak var oneTouchPayLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var oneTouchPaySwitch: Switch!
    
    @IBOutlet weak var deleteAccountButton: ButtonControl!
    @IBOutlet weak var deleteBankAccountLabel: UILabel!
    
    @IBOutlet weak var walletItemBGView: UIView!
    
    var isOneTouch = false

    var gradientLayer = CAGradientLayer()
    
    var viewModel = EditBankAccountViewModel(walletService: ServiceFactory.createWalletService())

    override func viewDidLoad() {
        super.viewDidLoad()
    
        bindWalletItemToViewElements()
        
        buildGradientAndBackgrounds()
        
        title = NSLocalizedString("Edit Bank Account", comment: "")
        
		buildNavigationButtons()
        
        deleteBankAccountLabel.font = SystemFont.regular.of(textStyle: .headline)
        deleteBankAccountLabel.textColor = UIColor(colorLiteralRed:0/255.0, green: 98/255.0, blue: 154/255.0, alpha: 1)
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
        
        accountIDLabel.textColor = .blackText
        oneTouchPayLabel.textColor = .blackText
        nicknameLabel.textColor = .blackText
        
        bottomBarShadowView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        bottomBarView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        convenienceFeeLabel.textColor = .blackText
    }
    
    func buildNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func bindWalletItemToViewElements() {
        oneTouchPaySwitch.rx.isOn.bind(to: viewModel.isOneTouch).addDisposableTo(disposeBag)

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
        oneTouchPayView.isHidden = !isOneTouch
    }
    
    @IBAction func toggleOneTouch(_ sender: Any) {
        isOneTouch = !isOneTouch

        oneTouchPayView.isHidden = !isOneTouch
        
        // update preferences
    }
    
    @IBAction func onDeletePress(_ sender: Any) {
        deleteBankAccount()
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
        
        viewModel.editBankAccount(onSuccess: {
            LoadingView.hide()
            self.delegate?.editBankAccountViewControllerDidEditAccount(self, message: "Changes saved")
            
            _ = self.navigationController?.popViewController(animated: true)
        }, onError: { errMessage in
            LoadingView.hide()
            
            print(errMessage)
        })
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
    

    ///
    func deleteBankAccount() {
        var messageString = NSLocalizedString("Are you sure you want to delete this Bank Account? Note: If you proceed, all payments scheduled for today's date will still be processed. Pending payments for future dates using this account will be cancelled and you will need to reschedule your payment with another bank account.", comment: "")
        
        if Environment.sharedInstance.opco == .bge {
            messageString = NSLocalizedString("Deleting this payment account will also delete all the pending payments associated with this payment account. Please click 'Delete' to delete this payment account.", comment: "")
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Delete Bank Account", comment: ""), message: messageString, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .default, handler: { _ in
            LoadingView.show()
            
            self.viewModel.editBankAccount(onSuccess: {
                LoadingView.hide()
                self.delegate?.editBankAccountViewControllerDidEditAccount(self, message: "Bank account deleted")
                
                _ = self.navigationController?.popViewController(animated: true)
            }, onError: { errMessage in
                LoadingView.hide()
                
                print(errMessage)
            })
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    
}
