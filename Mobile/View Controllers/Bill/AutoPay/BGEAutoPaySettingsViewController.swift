//
//  BGEAutoPaySettingsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class BGEAutoPaySettingsViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var group1StackView: UIStackView!
    @IBOutlet weak var group2StackView: UIStackView!
    @IBOutlet weak var group3StackView: UIStackView!
    
    @IBOutlet weak var group1HeaderLabel: UILabel!
    @IBOutlet weak var group2HeaderLabel: UILabel!
    @IBOutlet weak var group3HeaderLabel: UILabel!
    
    
    @IBOutlet var radioControlsSet1 = [UIControl]()
    @IBOutlet var radioControlsSet2 = [UIControl]()
    @IBOutlet var radioControlsSet3 = [UIControl]()
    
    let control1Nibless = RadioSelectControl.create(withTitle: NSLocalizedString("Total Amount Due", comment: ""))
    
    let control2Nibless = RadioSelectControl.create(withTitle: NSLocalizedString("Amount Not To Exceed", comment: ""))
    let amountNotToExceedTextField = FloatLabelTextField(frame: .zero)
    let amountNotToExceedDetailsLabel = UILabel(frame: .zero)
    var amountNotToExceedHairline = UIView(frame: .zero)
    
    let control3Nibless = RadioSelectControl.create(withTitle: NSLocalizedString("On Due Date", comment: ""))
    let onDueDateDetailsLabel = UILabel(frame: .zero)
    var onDueDateHairline = UIView(frame: .zero)
    
    let control4Nibless = RadioSelectControl.create(withTitle: NSLocalizedString("Before Due Date", comment: ""))
    
    let control5Nibless = RadioSelectControl.create(withTitle: NSLocalizedString("Until Canceled", comment: ""))
    let untilCanceledDetailsLabel = UILabel(frame: .zero)
    var untilCanceledHairline = UIView(frame: .zero)
    
    let control6Nibless = RadioSelectControl.create(withTitle: NSLocalizedString("For Number of Payments", comment: ""))
    let numberOfPaymentsTextField = FloatLabelTextField(frame: .zero)
    let numberOfPaymentsDetailsLabel = UILabel(frame: .zero)
    var numberOfPaymentsHairline = UIView(frame: .zero)
    
    let control7Nibless = RadioSelectControl.create(withTitle: NSLocalizedString("Until Date", comment: ""))
    let untilDateButton = DateDisclosureButton.create(withLabel: NSLocalizedString("Until Date*", comment: ""))
    let untilDateDetailsLabel = UILabel(frame: .zero)
    var untilDateHairline = UIView(frame: .zero)
    
    var viewModel = AutoPaySettingsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("AutoPay Settings", comment: "")
        
        loadSettings()
        
        buildNavigationButtons()
        
        buildStackViews()
    }
    
    func loadSettings() {
        // placeholder for now
        switch(viewModel.amountToPay.value) {
        case .totalAmountDue:
            control1Nibless.isSelected = true
            control2Nibless.isSelected = false
        
        case .amountNotToExceed:
            control1Nibless.isSelected = false
            control2Nibless.isSelected = true
        }
        
        switch (viewModel.whenToPay.value) {
        case .onDueDate:
            control3Nibless.isSelected = true
            control4Nibless.isSelected = false
       
        case .beforeDueDate:
            control3Nibless.isSelected = false
            control4Nibless.isSelected = true
        }
        
        switch (viewModel.howLongForAutoPay.value) {
        case .untilCanceled:
            control5Nibless.isSelected = true
            control6Nibless.isSelected = false
            control7Nibless.isSelected = false
            
        case .forNumberOfPayments:
            control5Nibless.isSelected = false
            control6Nibless.isSelected = true
            control7Nibless.isSelected = false
            
        case .untilDate:
            control5Nibless.isSelected = false
            control6Nibless.isSelected = false
            control7Nibless.isSelected = true
        }

        hideAmountNotToExceedControlViews(viewModel.amountToPay.value == .totalAmountDue)
        hideBeforeDueDateControlViews(viewModel.whenToPay.value != .onDueDate)
        
        hideUntilCanceled(viewModel.howLongForAutoPay.value != .untilCanceled)
        hideNumberOfPayments(viewModel.howLongForAutoPay.value != .forNumberOfPayments)
        hideUntilDate(viewModel.howLongForAutoPay.value != .untilDate)
    }
    
    func hideAmountNotToExceedControlViews(_ isHidden: Bool) {
        amountNotToExceedTextField.isHidden = isHidden
        amountNotToExceedDetailsLabel.isHidden = isHidden
        
//        var hairlineSize = control1Nibless.intrinsicContentSize
//        
//        if !isHidden {
//            hairlineSize.height += amountNotToExceedTextField.frame.size.height
//            hairlineSize.height += amountNotToExceedDetailsLabel.frame.size.height
//        }
//        
//        amountNotToExceedHairline.removeFromSuperview()
//        amountNotToExceedHairline = createHairline(ofSize: hairlineSize)
//        control2Nibless.addSubview(amountNotToExceedHairline)
    }
    
    func hideBeforeDueDateControlViews(_ isHidden: Bool) {
        onDueDateDetailsLabel.isHidden = isHidden
    }
    
    func hideUntilCanceled(_ isHidden: Bool) {
        untilCanceledDetailsLabel.isHidden = isHidden
    }
    
    func hideNumberOfPayments(_ isHidden: Bool) {
        numberOfPaymentsTextField.isHidden = isHidden
        numberOfPaymentsDetailsLabel.isHidden = isHidden
    }
    
    func hideUntilDate(_ isHidden: Bool) {
        untilDateButton.isHidden = isHidden
        untilDateDetailsLabel.isHidden = isHidden
    }
    
    func buildNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
    }
    
    func buildStackViews() {
        
        let stackView1 = buildAmountToPayGroup()
        
        stackView.addArrangedSubview(stackView1)
        
        let stackView2 = buildWhenToPayGroup()
        
        stackView.addArrangedSubview(stackView2)
        
        let stackView3 = buildRegularPaymentGroup()

        stackView.addArrangedSubview(stackView3)

        let bottomSpace = UIView(frame: .zero)
        
        stackView.addArrangedSubview(bottomSpace)
}
    
    func createHairline() -> UIView {
        let separator = UIView()
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.addConstraint(separator.heightAnchor.constraint(equalToConstant: 1.0))
        separator.backgroundColor = .black
        
        return separator
    }
    
    func buildAmountToPayGroup() -> UIStackView {
        //
        group1HeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        group1HeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        group1HeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        group1HeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        group1HeaderLabel.setContentHuggingPriority(999, for: .vertical)
        group1HeaderLabel.numberOfLines = 0
        group1HeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        group1HeaderLabel.text = NSLocalizedString("How much do you want to pay?", comment: "")
        
        control1Nibless.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        // adding first button
        group1StackView.addArrangedSubview(control1Nibless)
        radioControlsSet1.append(control1Nibless)
        
        // adding divider
        let separator1 = createHairline()
        
        group1StackView.addArrangedSubview(separator1)
        
        control2Nibless.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        // adding second button
        group1StackView.addArrangedSubview(control2Nibless)
        radioControlsSet1.append(control2Nibless)
        
        amountNotToExceedTextField.textField.placeholder = NSLocalizedString("Amount Not To Exceed*", comment: "")
        amountNotToExceedTextField.textField.autocorrectionType = .no
        amountNotToExceedTextField.textField.returnKeyType = .next
        amountNotToExceedTextField.textField.delegate = self
        amountNotToExceedTextField.textField.isShowingAccessory = true
        amountNotToExceedTextField.textField.rx.text.orEmpty.bind(to: viewModel.amountNotToExceed).addDisposableTo(disposeBag)
        amountNotToExceedTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        amountNotToExceedTextField.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        // adding textfield for second button
        group1StackView.addArrangedSubview(amountNotToExceedTextField)
        
        amountNotToExceedDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        amountNotToExceedDetailsLabel.numberOfLines = 0
        amountNotToExceedDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        amountNotToExceedDetailsLabel.text = NSLocalizedString("If your bill amount exceeds this threshold you will receive an email alert at the time the bill is created, and you will be responsible for manually scheduling a payment of the remaining amount. \n\nPlease note that any payments made for less than the total amount due or after the indicated due date may result in your service being disconnect.", comment: "")
        // adding details for second button
        group1StackView.addArrangedSubview(amountNotToExceedDetailsLabel)
        
        let separator2 = createHairline()
        
        group1StackView.addArrangedSubview(separator2)
        
//        amountNotToExceedDetailsLabel.addSubview(hairlineView)
        
        //        accountNumberTextField?.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
        //            if self.viewModel.accountNumber.value.characters.count > 0 {
        //                self.viewModel.accountNumberHasTenDigits().single().subscribe(onNext: { valid in
        //                    if !valid {
        //                        self.accountNumberTextField?.setError(NSLocalizedString("Account number must be 10 digits long.", comment: ""))
        //                    }
        //                }).addDisposableTo(self.disposeBag)
        //            }
        //        }).addDisposableTo(disposeBag)
        //
        //        accountNumberTextField?.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
        //            self.accountNumberTextField?.setError(nil)
        //        }).addDisposableTo(disposeBag)
        
        
        for control in radioControlsSet1 {
            control.addTarget(self, action: #selector(radioControlSet1Pressed(control:)), for: .touchUpInside)
        }
        
        return group1StackView
    }
    
    func buildWhenToPayGroup() -> UIStackView {
        //
        group2HeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        group2HeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        group2HeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        group2HeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        group2HeaderLabel.setContentHuggingPriority(999, for: .vertical)
        group2HeaderLabel.numberOfLines = 0
        group2HeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        group2HeaderLabel.text = NSLocalizedString("When do you want to pay?", comment: "")
        
        control3Nibless.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        group2StackView.addArrangedSubview(control3Nibless)
        
        radioControlsSet2.append(control3Nibless)
        
        onDueDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        onDueDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        onDueDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        onDueDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        onDueDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        onDueDateDetailsLabel.numberOfLines = 0
        onDueDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        onDueDateDetailsLabel.text = NSLocalizedString("Your payments will process on each bill's due date. A pending payment will be created several days before it is processed to give you the opportunity to edit or cancel the payment if necessary.", comment: "")
        group2StackView.addArrangedSubview(onDueDateDetailsLabel)
        
        let separator1 = createHairline()
        group2StackView.addArrangedSubview(separator1)
        
        control4Nibless.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        control4Nibless.detailButtonTitle = NSLocalizedString("Select Number", comment: "")
        group2StackView.addArrangedSubview(control4Nibless)
        
        let separator2 = createHairline()
        group2StackView.addArrangedSubview(separator2)

        radioControlsSet2.append(control4Nibless)
        
        for control in radioControlsSet2 {
            control.addTarget(self, action: #selector(radioControlSet2Pressed(control:)), for: .touchUpInside)
        }

        return group2StackView
    }
    
    func buildRegularPaymentGroup() -> UIStackView {
        ///
        group3HeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        group3HeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        group3HeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        group3HeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        group3HeaderLabel.setContentHuggingPriority(999, for: .vertical)
        group3HeaderLabel.numberOfLines = 0
        group3HeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        group3HeaderLabel.text = NSLocalizedString("How long do you want to use AutoPay?", comment: "")
        
        control5Nibless.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        group3StackView.addArrangedSubview(control5Nibless)
        
        radioControlsSet3.append(control5Nibless)
        
        untilCanceledDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        untilCanceledDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        untilCanceledDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        untilCanceledDetailsLabel.numberOfLines = 0
        untilCanceledDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        untilCanceledDetailsLabel.text = NSLocalizedString("AutoPay will schedule each month's payment until you manually unenroll from AutoPay, or your account is issued a final bill. This is the best way to keep your payments ongoing.", comment: "")
        
        group3StackView.addArrangedSubview(untilCanceledDetailsLabel)
        
        let separator1 = createHairline()
        group3StackView.addArrangedSubview(separator1)
        
        control6Nibless.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        group3StackView.addArrangedSubview(control6Nibless)
        
        radioControlsSet3.append(control6Nibless)
        
        numberOfPaymentsTextField.textField.placeholder = NSLocalizedString("Number of Payments*", comment: "")
        numberOfPaymentsTextField.textField.autocorrectionType = .no
        numberOfPaymentsTextField.textField.returnKeyType = .next
        numberOfPaymentsTextField.textField.delegate = self
        numberOfPaymentsTextField.textField.isShowingAccessory = true
        numberOfPaymentsTextField.textField.rx.text.orEmpty.bind(to: viewModel.amountNotToExceed).addDisposableTo(disposeBag)
        numberOfPaymentsTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        numberOfPaymentsTextField.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        group3StackView.addArrangedSubview(numberOfPaymentsTextField)
        
        numberOfPaymentsDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        numberOfPaymentsDetailsLabel.numberOfLines = 0
        numberOfPaymentsDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        numberOfPaymentsDetailsLabel.text = NSLocalizedString("After your selected number of payments have been created, AutoPay will automatically stop and you will be responsible for restarting AutoPay or resuming manual payments on your accounts.", comment: "")
        
        group3StackView.addArrangedSubview(numberOfPaymentsDetailsLabel)
        
        let separator2 = createHairline()
        group3StackView.addArrangedSubview(separator2)
        
        control7Nibless.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        group3StackView.addArrangedSubview(control7Nibless)
        radioControlsSet3.append(control7Nibless)
        
        untilDateButton.addTarget(self, action: #selector(onDateButtonSelected), for: .touchUpInside)
        
        group3StackView.addArrangedSubview(untilDateButton)
        
        untilDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        untilDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        untilDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        untilDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        untilDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        untilDateDetailsLabel.numberOfLines = 0
        untilDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        untilDateDetailsLabel.text = NSLocalizedString("AutoPay will schedule each month's payment until the date you choose, after which AutoPay will automatically stop and you will be responsible for restarting AutoPay or manual payments on your account.", comment: "")
        
        group3StackView.addArrangedSubview(untilDateDetailsLabel)
        
        let separator3 = createHairline()
        group3StackView.addArrangedSubview(separator3)
        
        for control in radioControlsSet3 {
            control.addTarget(self, action: #selector(radioControlSet3Pressed(control:)), for: .touchUpInside)
        }

        return group3StackView
    }
    
    func onDateButtonSelected() {
        
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func radioControlSet1Pressed(control: UIControl) {
        control.isSelected = true
        
        radioControlsSet1
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }

        hideAmountNotToExceedControlViews(control != control2Nibless)
    }
    
    func radioControlSet2Pressed(control: UIControl) {
        control.isSelected = true
        
        radioControlsSet2
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }
        
        hideBeforeDueDateControlViews(control != control3Nibless)
    }
    
    func radioControlSet3Pressed(control: UIControl) {
        control.isSelected = true
        
        radioControlsSet3
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }
        
        hideUntilCanceled(control != control5Nibless)
        hideNumberOfPayments(control != control6Nibless)
        hideUntilDate(control != control7Nibless)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        totalAmountDueButtonView.label.text = NSLocalizedString("Total Amount Due", comment: "")
//        totalAmountDueButtonView.setSelected(true, animated: false)
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        print("Submit")
    }

}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension BGEAutoPaySettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == amountNotToExceedTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 10
        } else if textField == numberOfPaymentsTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 4
        }
        
        return true
    }
}
