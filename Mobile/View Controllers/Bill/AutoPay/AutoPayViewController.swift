//
//  AutoPayViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AutoPayViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var learnMoreButton: ButtonControl!
    @IBOutlet weak var learnMoreLabel: UILabel!
    @IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
    @IBOutlet weak var nameTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTooltipButton: UIButton!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    @IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var footerLabel: UILabel!
    
    let bag = DisposeBag()
    
    var accountDetail: AccountDetail!
    lazy var viewModel: AutoPayViewModel = { AutoPayViewModel(withAccountDetail: self.accountDetail) }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("AutoPay", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        
        learnMoreButton.addShadow(color: .black, opacity: 0.12, offset: .zero, radius: 3)
        let learnMoreString = NSLocalizedString("Learn more about ", comment: "")
        let autoPayString = NSLocalizedString("AutoPay", comment: "")
        let learnMoreAboutAutoPayString = learnMoreString + "\n" + autoPayString
        let learnMoreAboutAutoPayAttrString = NSMutableAttributedString(string: learnMoreAboutAutoPayString, attributes: [NSForegroundColorAttributeName: UIColor.blackText])
        
        learnMoreAboutAutoPayAttrString.addAttribute(NSFontAttributeName,
                                                     value: OpenSans.regular.of(size: 18),
                                                     range: NSMakeRange(0, learnMoreString.characters.count))
        
        learnMoreAboutAutoPayAttrString.addAttribute(NSFontAttributeName,
                                                     value: OpenSans.bold.of(size: 18),
                                                     range: NSMakeRange(learnMoreString.characters.count + 1, autoPayString.characters.count))
        
        learnMoreLabel.attributedText = learnMoreAboutAutoPayAttrString
        
        checkingSavingsSegmentedControl.items = [NSLocalizedString("Checking", comment: ""), NSLocalizedString("Savings", comment: "")]
        
        checkingSavingsSegmentedControl.selectedIndex.asObservable()
            .map { selectedIndex -> BankAccountType in
                selectedIndex == 0 ? .checking: .savings
            }
            .bind(to: viewModel.bankAccountType)
            .addDisposableTo(bag)
        
        nameTextField.textField.placeholder = NSLocalizedString("Name on Account*", comment: "")
        nameTextField.textField.delegate = self
        nameTextField.textField.returnKeyType = .next
        
        routingNumberTextField.textField.placeholder = NSLocalizedString("Routing Number*", comment: "")
        routingNumberTextField.textField.delegate = self
        routingNumberTextField.textField.returnKeyType = .next
        routingNumberTextField.textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        routingNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.returnKeyType = .next
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        confirmAccountNumberTextField.textField.placeholder = NSLocalizedString("Confirm Account Number*", comment: "")
        confirmAccountNumberTextField.textField.delegate = self
        
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        footerLabel.setLineHeight(lineHeight: 16)
        viewModel.footerText.drive(footerLabel.rx.text).addDisposableTo(bag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.removeFromSuperlayer()
        
        let gLayer = CAGradientLayer()
        gLayer.frame = gradientView.bounds
        gLayer.colors = [UIColor.softGray.cgColor, UIColor.white.cgColor]
        
        gradientLayer = gLayer
        gradientView.layer.addSublayer(gLayer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        gradientLayer.frame = gradientView.bounds
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        print("Submit")
    }
    
}

extension AutoPayViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == routingNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 9
        } else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet)
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if textField == routingNumberTextField.textField && textField.text?.characters.count == 9 {
            accountNumberTextField.textField.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField.textField {
            routingNumberTextField.textField.becomeFirstResponder()
        } else if textField == routingNumberTextField.textField {
            accountNumberTextField.textField.becomeFirstResponder()
        } else if textField == accountNumberTextField.textField {
            if confirmAccountNumberTextField.isUserInteractionEnabled {
                confirmAccountNumberTextField.textField.becomeFirstResponder()
            }
        }
        return false
    }
}

