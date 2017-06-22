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
    
    var selectedUntilDate: Date?

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var amountDueStackView: UIStackView!
    @IBOutlet weak var dueDateStackView: UIStackView!
    @IBOutlet weak var numberOfPaymentsStackView: UIStackView!
    
    @IBOutlet weak var amountDueHeaderLabel: UILabel!
    @IBOutlet weak var dueDateHeaderLabel: UILabel!
    @IBOutlet weak var numberOfPaymentsHeaderLabel: UILabel!
    
    @IBOutlet var amountDueRadioControlsSet = [UIControl]()
    @IBOutlet var dueDateRadioControlsSet = [UIControl]()
    @IBOutlet var numberOfPaymentsRadioControlsSet = [UIControl]()
    
    let totalAmountDueRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Total Amount Due", comment: ""))
    
    let amountNotToExceedRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Amount Not To Exceed", comment: ""))
    let amountNotToExceedTextField = FloatLabelTextField(frame: .zero)
    let amountNotToExceedDetailsLabel = UILabel(frame: .zero)
    var amountNotToExceedHairline = UIView(frame: .zero)
    
    let onDueDateRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("On Due Date", comment: ""))
    let onDueDateDetailsLabel = UILabel(frame: .zero)
    var onDueDateHairline = UIView(frame: .zero)
    
    let beforeDueDateRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Before Due Date", comment: ""))
    let beforeDueDateDetailsLabel = UILabel(frame: .zero)
    let beforeDueDateHairline = UIView(frame: .zero)
    
    let untilCanceledRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Until Canceled", comment: ""))
    let untilCanceledDetailsLabel = UILabel(frame: .zero)
    var untilCanceledHairline = UIView(frame: .zero)
    
    let numberOfPaymentsRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("For Number of Payments", comment: ""))
    let numberOfPaymentsTextField = FloatLabelTextField(frame: .zero)
    let numberOfPaymentsDetailsLabel = UILabel(frame: .zero)
    var numberOfPaymentsHairline = UIView(frame: .zero)
    
    let untilDateRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Until Date", comment: ""))
    let untilDateButton = DateDisclosureButton.create(withLabel: NSLocalizedString("Until Date*", comment: ""))
    let untilDateDetailsLabel = UILabel(frame: .zero)
    var untilDateHairline = UIView(frame: .zero)
    
    let now = Calendar.current.startOfDay(for: Date())
    let lastDate = Calendar.current.date(byAdding: .year, value: 100, to: Calendar.current.startOfDay(for: Date()))
    
    var dayPickerView: DayPickerContainerView!
    
    var numberOfDaysBefore: [String]!

    var viewModel: BGEAutoPayViewModel! // Passed from BGEAutoPayViewController
    
    var zPositionForWindow:CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = self.view
        
//        buildPickerView()
        
        title = NSLocalizedString("AutoPay Settings", comment: "")
        
        loadSettings()
        
        buildStackViews()
    }
    
    func loadSettings() {
        // placeholder for now
        switch(viewModel.amountToPay.value) {
        case .totalAmountDue:
            totalAmountDueRadioControl.isSelected = true
            amountNotToExceedRadioControl.isSelected = false
        
        case .amountNotToExceed:
            totalAmountDueRadioControl.isSelected = false
            amountNotToExceedRadioControl.isSelected = true
        }
        
        //
        switch (viewModel.whenToPay.value) {
        case .onDueDate:
            onDueDateRadioControl.isSelected = true
            beforeDueDateRadioControl.isSelected = false
       
        case .beforeDueDate:
            onDueDateRadioControl.isSelected = false
            beforeDueDateRadioControl.isSelected = true
        }
        
        //
        switch (viewModel.howLongForAutoPay.value) {
        case .untilCanceled:
            untilCanceledRadioControl.isSelected = true
            numberOfPaymentsRadioControl.isSelected = false
            untilDateRadioControl.isSelected = false
            
        case .forNumberOfPayments:
            untilCanceledRadioControl.isSelected = false
            numberOfPaymentsRadioControl.isSelected = true
            untilDateRadioControl.isSelected = false
            
        case .untilDate:
            untilCanceledRadioControl.isSelected = false
            numberOfPaymentsRadioControl.isSelected = false
            untilDateRadioControl.isSelected = true
        }

        //
        hideAmountNotToExceedControlViews(viewModel.amountToPay.value == .totalAmountDue)
        hideBeforeDueDateControlViews(viewModel.whenToPay.value != .onDueDate)
        
        hideUntilCanceled(viewModel.howLongForAutoPay.value != .untilCanceled)
        hideNumberOfPayments(viewModel.howLongForAutoPay.value != .forNumberOfPayments)
        hideUntilDate(viewModel.howLongForAutoPay.value != .untilDate)
    }
    
    func hideAmountNotToExceedControlViews(_ isHidden: Bool) {
        amountNotToExceedTextField.isHidden = isHidden
        amountNotToExceedDetailsLabel.isHidden = isHidden
        
        viewModel.amountToPay.value = isHidden ? .totalAmountDue : .amountNotToExceed
    }
    
    func hideBeforeDueDateControlViews(_ isHidden: Bool) {
        onDueDateDetailsLabel.isHidden = isHidden
        beforeDueDateDetailsLabel.isHidden = !isHidden
        
        viewModel.whenToPay.value = isHidden ? .beforeDueDate : .onDueDate
    }
    
    func hideUntilCanceled(_ isHidden: Bool) {
        untilCanceledDetailsLabel.isHidden = isHidden
        
        if !isHidden {
            viewModel.howLongForAutoPay.value = .untilCanceled
        }
    }
    
    func hideNumberOfPayments(_ isHidden: Bool) {
        numberOfPaymentsTextField.isHidden = isHidden
        numberOfPaymentsDetailsLabel.isHidden = isHidden
        
        if !isHidden {
            viewModel.howLongForAutoPay.value = .forNumberOfPayments
        }
    }
    
    func hideUntilDate(_ isHidden: Bool) {
        untilDateButton.isHidden = isHidden
        untilDateDetailsLabel.isHidden = isHidden
        
        if !isHidden {
            viewModel.howLongForAutoPay.value = .untilDate
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        buildPickerView()
    }
    
    func buildPickerView() {
        let currentWindow = UIApplication.shared.keyWindow
        dayPickerView = DayPickerContainerView(frame: (currentWindow?.frame)!)
        
        currentWindow?.addSubview(dayPickerView)
        
        dayPickerView.leadingAnchor.constraint(equalTo: (currentWindow?.leadingAnchor)!, constant: 0).isActive = true
        dayPickerView.trailingAnchor.constraint(equalTo: (currentWindow?.trailingAnchor)!, constant: 0).isActive = true
        dayPickerView.topAnchor.constraint(equalTo: (currentWindow?.topAnchor)!, constant: 0).isActive = true

        let height = dayPickerView.containerView.frame.size.height + 8
        dayPickerView.bottomConstraint.constant = height
        
        dayPickerView.delegate = self
        
        zPositionForWindow = (currentWindow?.layer.zPosition)!

        dayPickerView.isHidden = true
    }
    
    func showPickerView(_ showPicker: Bool, completion: (() -> ())? = nil) {
        if showPicker {
            self.dayPickerView.isHidden = false
            
            let row = viewModel.numberOfDaysBeforeDueDate.value == "" ? 1 : Int(viewModel.numberOfDaysBeforeDueDate.value)!
            
            self.dayPickerView.selectRow(row - 1)
        }
        
        self.dayPickerView.layer.zPosition = showPicker ? self.zPositionForWindow : -1
        UIApplication.shared.keyWindow?.layer.zPosition = showPicker ? -1 : self.zPositionForWindow

        self.dayPickerView.layoutIfNeeded()
        
        var bottomAnchorLength = self.dayPickerView.containerView.frame.size.height + 8
        var alpha:Float = 0.0
        
        if showPicker {
            alpha = 0.6
            bottomAnchorLength = -8
        }

        self.dayPickerView.bottomConstraint.constant = bottomAnchorLength
        
        self.dayPickerView.setNeedsLayout()
        
        UIView.animate(withDuration: 0.25, animations: {
            self.dayPickerView.layoutIfNeeded()
            
            self.dayPickerView.backgroundColor =  UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: alpha)
        }, completion: { _ in
            if !showPicker {
                self.dayPickerView.isHidden = true
            }
            
            completion?()
        })
        
//        UIView.animate(withDuration: 1.5, animations: {
//        }, completion: {_ in
//        })
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
    
    func buildAmountToPayGroup() -> UIStackView {
        //
        amountDueHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        amountDueHeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        amountDueHeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        amountDueHeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        amountDueHeaderLabel.setContentHuggingPriority(999, for: .vertical)
        amountDueHeaderLabel.numberOfLines = 0
        amountDueHeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        amountDueHeaderLabel.text = NSLocalizedString("How much do you want to pay?", comment: "")
        
        totalAmountDueRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        // adding first button
        amountDueStackView.addArrangedSubview(totalAmountDueRadioControl)
        amountDueRadioControlsSet.append(totalAmountDueRadioControl)
        
        // adding divider
        let separator1 = SeparatorLineView.create(leadingSpace: 34)
        
        amountDueStackView.addArrangedSubview(separator1)
        
        amountNotToExceedRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        // adding second button
        amountDueStackView.addArrangedSubview(amountNotToExceedRadioControl)
        amountDueRadioControlsSet.append(amountNotToExceedRadioControl)
        
        amountNotToExceedTextField.textField.placeholder = NSLocalizedString("Amount Not To Exceed*", comment: "")
        amountNotToExceedTextField.textField.autocorrectionType = .no
        amountNotToExceedTextField.textField.returnKeyType = .next
        amountNotToExceedTextField.textField.delegate = self
        amountNotToExceedTextField.textField.isShowingAccessory = true
        amountNotToExceedTextField.textField.rx.text.orEmpty.bind(to: viewModel.amountNotToExceed).addDisposableTo(disposeBag)
        amountNotToExceedTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        amountNotToExceedTextField.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        // adding textfield for second button
        amountDueStackView.addArrangedSubview(amountNotToExceedTextField)
        
        amountNotToExceedTextField.textField.rx.text.orEmpty.bind(to: viewModel.amountNotToExceed).addDisposableTo(disposeBag)
        
        amountNotToExceedDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        amountNotToExceedDetailsLabel.numberOfLines = 0
        amountNotToExceedDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        amountNotToExceedDetailsLabel.text = NSLocalizedString("If your bill amount exceeds this threshold you will receive an email alert at the time the bill is created, and you will be responsible for manually scheduling a payment of the remaining amount. \n\nPlease note that any payments made for less than the total amount due or after the indicated due date may result in your service being disconnect.", comment: "")
        // adding details for second button
        amountDueStackView.addArrangedSubview(amountNotToExceedDetailsLabel)
        
        let separator2 = SeparatorLineView.create(leadingSpace: 34)
        
        amountDueStackView.addArrangedSubview(separator2)
        
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
        
        
        for control in amountDueRadioControlsSet {
            control.addTarget(self, action: #selector(radioControlSet1Pressed(control:)), for: .touchUpInside)
        }
        
        return amountDueStackView
    }
    
    func buildWhenToPayGroup() -> UIStackView {
        //
        dueDateHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateHeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        dueDateHeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        dueDateHeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        dueDateHeaderLabel.setContentHuggingPriority(999, for: .vertical)
        dueDateHeaderLabel.numberOfLines = 0
        dueDateHeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        dueDateHeaderLabel.text = NSLocalizedString("When do you want to pay?", comment: "")
        
        //
        onDueDateRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        dueDateStackView.addArrangedSubview(onDueDateRadioControl)
        
        dueDateRadioControlsSet.append(onDueDateRadioControl)
        
        onDueDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        onDueDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        onDueDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        onDueDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        onDueDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        onDueDateDetailsLabel.numberOfLines = 0
        onDueDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        onDueDateDetailsLabel.text = NSLocalizedString("Your payments will process on each bill's due date. A pending payment will be created several days before it is processed to give you the opportunity to edit or cancel the payment if necessary.", comment: "")
        dueDateStackView.addArrangedSubview(onDueDateDetailsLabel)
        
        let separator1 = SeparatorLineView.create(leadingSpace: 34)
        dueDateStackView.addArrangedSubview(separator1)
        
        //
        beforeDueDateRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        beforeDueDateRadioControl.detailButtonTitle = NSLocalizedString("Select Number", comment: "")
        dueDateStackView.addArrangedSubview(beforeDueDateRadioControl)
        
        beforeDueDateRadioControl.detailButton.addTarget(self, action: #selector(beforeDueDateButtonPressed), for: .touchUpInside)
        
        let separator2 = SeparatorLineView.create(leadingSpace: 34)
        dueDateStackView.addArrangedSubview(separator2)

        beforeDueDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        beforeDueDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        beforeDueDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        beforeDueDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        beforeDueDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        beforeDueDateDetailsLabel.numberOfLines = 0
        beforeDueDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        beforeDueDateDetailsLabel.text = NSLocalizedString("Your payment will process on your selected number of days before each bill's due date. A pending payment will be created several days before it is processed to give you the opportunity to edit or cancel the payment if necessary.\n\nBGE recommends paying a few days before the due date to ensure adequate processing time.", comment: "")
        
        if viewModel.numberOfDaysBeforeDueDate.value != "" {
            modifyBeforeDueDateDetailsLabel()
        }
        
        dueDateStackView.addArrangedSubview(beforeDueDateDetailsLabel)

        dueDateRadioControlsSet.append(beforeDueDateRadioControl)
        
        for control in dueDateRadioControlsSet {
            control.addTarget(self, action: #selector(radioControlSet2Pressed(control:)), for: .touchUpInside)
        }

        return dueDateStackView
    }
    
    func buildRegularPaymentGroup() -> UIStackView {
        ///
        numberOfPaymentsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        numberOfPaymentsHeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        numberOfPaymentsHeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        numberOfPaymentsHeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        numberOfPaymentsHeaderLabel.setContentHuggingPriority(999, for: .vertical)
        numberOfPaymentsHeaderLabel.numberOfLines = 0
        numberOfPaymentsHeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        numberOfPaymentsHeaderLabel.text = NSLocalizedString("How long do you want to use AutoPay?", comment: "")
        
        untilCanceledRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        numberOfPaymentsStackView.addArrangedSubview(untilCanceledRadioControl)
        
        numberOfPaymentsRadioControlsSet.append(untilCanceledRadioControl)
        
        untilCanceledDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        untilCanceledDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        untilCanceledDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        untilCanceledDetailsLabel.numberOfLines = 0
        untilCanceledDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        untilCanceledDetailsLabel.text = NSLocalizedString("AutoPay will schedule each month's payment until you manually unenroll from AutoPay, or your account is issued a final bill. This is the best way to keep your payments ongoing.", comment: "")
        
        numberOfPaymentsStackView.addArrangedSubview(untilCanceledDetailsLabel)
        
        let separator1 = SeparatorLineView.create(leadingSpace: 34)
        numberOfPaymentsStackView.addArrangedSubview(separator1)
        
        numberOfPaymentsRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        numberOfPaymentsStackView.addArrangedSubview(numberOfPaymentsRadioControl)
        
        numberOfPaymentsRadioControlsSet.append(numberOfPaymentsRadioControl)
        
        numberOfPaymentsTextField.textField.placeholder = NSLocalizedString("Number of Payments*", comment: "")
        numberOfPaymentsTextField.textField.autocorrectionType = .no
        numberOfPaymentsTextField.textField.returnKeyType = .next
        numberOfPaymentsTextField.textField.delegate = self
        numberOfPaymentsTextField.textField.isShowingAccessory = true
        numberOfPaymentsTextField.textField.rx.text.orEmpty.bind(to: viewModel.amountNotToExceed).addDisposableTo(disposeBag)
        numberOfPaymentsTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        numberOfPaymentsTextField.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        numberOfPaymentsTextField.textField.rx.text.orEmpty.bind(to: viewModel.numberOfDaysBeforeDueDate).addDisposableTo(disposeBag)

        numberOfPaymentsStackView.addArrangedSubview(numberOfPaymentsTextField)
        
        numberOfPaymentsDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        numberOfPaymentsDetailsLabel.numberOfLines = 0
        numberOfPaymentsDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        numberOfPaymentsDetailsLabel.text = NSLocalizedString("After your selected number of payments have been created, AutoPay will automatically stop and you will be responsible for restarting AutoPay or resuming manual payments on your accounts.", comment: "")
        
        numberOfPaymentsStackView.addArrangedSubview(numberOfPaymentsDetailsLabel)
        
        let separator2 = SeparatorLineView.create(leadingSpace: 34)
        numberOfPaymentsStackView.addArrangedSubview(separator2)
        
        untilDateRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        numberOfPaymentsStackView.addArrangedSubview(untilDateRadioControl)
        numberOfPaymentsRadioControlsSet.append(untilDateRadioControl)
        
        untilDateButton.addTarget(self, action: #selector(onDateButtonSelected), for: .touchUpInside)
        
        numberOfPaymentsStackView.addArrangedSubview(untilDateButton)
        
        untilDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        untilDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        untilDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        untilDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        untilDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        untilDateDetailsLabel.numberOfLines = 0
        untilDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        untilDateDetailsLabel.text = NSLocalizedString("AutoPay will schedule each month's payment until the date you choose, after which AutoPay will automatically stop and you will be responsible for restarting AutoPay or manual payments on your account.", comment: "")
        
        numberOfPaymentsStackView.addArrangedSubview(untilDateDetailsLabel)
        
        let separator3 = SeparatorLineView.create(leadingSpace: 34)
        numberOfPaymentsStackView.addArrangedSubview(separator3)
        
        for control in numberOfPaymentsRadioControlsSet {
            control.addTarget(self, action: #selector(radioControlSet3Pressed(control:)), for: .touchUpInside)
        }

        return numberOfPaymentsStackView
    }
    
    func modifyBeforeDueDateDetailsLabel() {
        var numDays = viewModel.numberOfDaysBeforeDueDate.value
        
        if numDays == "0" {
            numDays = "1"
        }
        
        let numDaysPlural = numDays > "1" ? "s" : ""
        
        beforeDueDateDetailsLabel.text = NSLocalizedString("Your payment will process \(numDays) day\(numDaysPlural) before each bill's due date. A pending payment will be created several days before it is processed to give you the opportunity to edit or cancel the payment if necessary\n\nBGE recommends paying a few days before the due date to ensure adequate processing time.", comment: "")
    }
    
    func beforeDueDateButtonPressed() {
        showPickerView(true)
    }
    
    func onDateButtonSelected() {
        let calendarVC = PDTSimpleCalendarViewController()
        
        calendarVC.delegate = self
        calendarVC.title = NSLocalizedString("Select Date", comment: "")
        calendarVC.firstDate = now
        calendarVC.lastDate = lastDate
        
        var selectedDate = now
        
        if viewModel.autoPayUntilDate.value != "" {
            selectedDate = viewModel.autoPayUntilDate.value.mmDdYyyyDate
        }
        
        calendarVC.selectedDate = selectedDate
        
        navigationController?.pushViewController(calendarVC, animated: true)
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func radioControlSet1Pressed(control: UIControl) {
        control.isSelected = true
        
        amountDueRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }

        hideAmountNotToExceedControlViews(control != amountNotToExceedRadioControl)
    }
    
    func radioControlSet2Pressed(control: UIControl) {
        control.isSelected = true
        
        dueDateRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }
        
        hideBeforeDueDateControlViews(control != onDueDateRadioControl)
    }
    
    func radioControlSet3Pressed(control: UIControl) {
        control.isSelected = true
        
        numberOfPaymentsRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }
        
        hideUntilCanceled(control != untilCanceledRadioControl)
        hideNumberOfPayments(control != numberOfPaymentsRadioControl)
        hideUntilDate(control != untilDateRadioControl)
    }
    
    func onBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func pickerCancelButtonPressed(_ sender: Any) {
        showPickerView(false)
    }
    
    @IBAction func pickerDoneButtonPressed(_ sender: Any) {
        showPickerView(false)
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension BGEAutoPaySettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == amountNotToExceedTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            
            let numDec = newString.components(separatedBy:".")
            
            if numDec.count > 2 {
                return false
            } else if numDec.count == 2 && numDec[1].characters.count > 2 {
                return false
            }
            
            let containsDecimal = newString.contains(".")
            
            return (CharacterSet.decimalDigits.isSuperset(of: characterSet) || containsDecimal) && newString.characters.count <= 10
            
        } else if textField == numberOfPaymentsTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 3
        }
        
        return true
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension BGEAutoPaySettingsViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        if let selectedDate = date {
            return selectedDate >= now && selectedDate <= lastDate!
        } else {
            return false
        }
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        print("Selected date ", date)
        selectedUntilDate = date
        
        if let selectedUntilDate = selectedUntilDate {
            viewModel.autoPayUntilDate.value = selectedUntilDate.mmDdYyyyString
            untilDateButton.selectedDateLabel.text = selectedUntilDate.mmDdYyyyString
        }
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension BGEAutoPaySettingsViewController: DayPickerDelegate {
    func cancelPressed() {
        showPickerView(false)
    }
    
    func donePressed(selectedDay: Int) {
        DispatchQueue.main.async {
            self.viewModel.numberOfDaysBeforeDueDate.value = "\(selectedDay)"

//            self.modifyBeforeDueDateDetailsLabel()

            self.showPickerView(false, completion: self.modifyBeforeDueDateDetailsLabel)
}
    }
}

