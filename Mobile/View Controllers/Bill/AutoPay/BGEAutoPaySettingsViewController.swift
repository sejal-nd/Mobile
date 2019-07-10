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
import PDTSimpleCalendar

protocol BGEAutoPaySettingsViewControllerDelegate: class {
    func didUpdateSettings(amountToPay: AmountType,
                           amountNotToExceed: Double,
                           whenToPay: BGEAutoPayViewModel.PaymentDateType,
                           numberOfDaysBeforeDueDate: Int)
}

class BGEAutoPaySettingsViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    // grand master stackview
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!                          // 1

    // Group 1
    @IBOutlet weak var amountDueStackView: UIStackView!                 //1.1
    
    @IBOutlet weak var amountDueHeaderLabel: UILabel!
    @IBOutlet weak var totalAmountDueButtonStackView: UIStackView!      //1.1.1
    let totalAmountDueRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Total Amount Billed", comment: ""))
    
    @IBOutlet weak var amountNotToExceedButtonStackView: UIStackView!   //1.1.2
    let amountNotToExceedRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Amount Not To Exceed", comment: ""))
    let amountNotToExceedTextField = FloatLabelTextField(frame: .zero)
    var amountNotToExceedSpacerView1 = SeparatorSpaceView(frame: .zero)
    let amountNotToExceedDetailsLabel = UILabel(frame: .zero)
    var amountNotToExceedSpacerView2 = SeparatorSpaceView(frame: .zero)
    var amountNotToExceedHairline = UIView(frame: .zero)

    @IBOutlet var amountDueRadioControlsSet = [UIControl]()

    // Group 2
    @IBOutlet weak var dueDateStackView: UIStackView!                   //1.2
    
    @IBOutlet weak var dueDateHeaderLabel: UILabel!
    @IBOutlet weak var onDueDateButtonStackView: UIStackView!           //1.2.1
    let onDueDateRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("On Due Date", comment: ""))
    let onDueDateDetailsLabel = UILabel(frame: .zero)
    var onDueDateSpacerView1 = SeparatorSpaceView(frame: .zero)
    var onDueDateHairline = UIView(frame: .zero)
    
    @IBOutlet weak var beforeDueDateButtonStackView: UIStackView!       //1.2.2
    let beforeDueDateRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Before Due Date", comment: ""))
    let beforeDueDateDetailsLabel = UILabel(frame: .zero)
    var beforeDateSpacerView1 = SeparatorSpaceView(frame: .zero)
    let beforeDueDateHairline = UIView(frame: .zero)

    @IBOutlet var dueDateRadioControlsSet = [UIControl]()

    //
    let now = Calendar.current.startOfDay(for: .now)
    let lastDate = Calendar.current.date(byAdding: .year, value: 100, to: Calendar.current.startOfDay(for: .now))

    var viewModel: BGEAutoPaySettingsViewModel! // Passed from BGEAutoPayViewController
    weak var delegate: BGEAutoPaySettingsViewControllerDelegate?
    
    let separatorInset: CGFloat = 34.0
    let spacerHeight: CGFloat = 20.0
    
    var doneButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        title = NSLocalizedString("AutoPay Settings", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        cancelButton.isAccessibilityElement = true
        cancelButton.accessibilityLabel = NSLocalizedString("Cancel", comment: "")
        navigationItem.leftBarButtonItems = [cancelButton]
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneButton.isAccessibilityElement = true
        doneButton.accessibilityLabel = NSLocalizedString("Done", comment: "")
        navigationItem.rightBarButtonItems = [doneButton]
        viewModel.enableDone.drive(doneButton.rx.isEnabled).disposed(by: disposeBag)
        doneButton.rx.tap.asDriver()
            .withLatestFrom(viewModel.amountNotToExceedDouble)
            .drive(onNext: { [weak self] in
                self?.onDonePress(amountNotToExceed: $0)
            })
            .disposed(by: disposeBag)
        
        buildStackViews()
        
        loadSettings()
        
        amountNotToExceedTextField.textField.rx.controlEvent(.editingChanged)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let text = self.amountNotToExceedTextField.textField.text {
                    if !text.isEmpty {
                        self.viewModel.formatAmountNotToExceed()
                    }
                }
            }).disposed(by: disposeBag)
        
        viewModel.amountToPayErrorMessage
            .drive(onNext: { [weak self] errorMessage in
                self?.amountNotToExceedTextField.setError(errorMessage)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if viewModel.initialEnrollmentStatus == .enrolled {
            Analytics.log(event: .autoPayModifySettingOffer)
        } else {
            Analytics.log(event: .autoPayModifySettingOfferNew)
        }
    }
    
    func loadSettings() {
        switch viewModel.amountToPay.value {
        case .amountDue:
            totalAmountDueRadioControl.isSelected = true
            amountNotToExceedRadioControl.isSelected = false
        
        case .upToAmount:
            totalAmountDueRadioControl.isSelected = false
            amountNotToExceedRadioControl.isSelected = true
        }
        
        switch viewModel.whenToPay.value {
        case .onDueDate:
            onDueDateRadioControl.isSelected = true
            beforeDueDateRadioControl.isSelected = false
       
        case .beforeDueDate:
            onDueDateRadioControl.isSelected = false
            beforeDueDateRadioControl.isSelected = true
        }
    
        hideAmountNotToExceedControlViews(viewModel.amountToPay.value == .amountDue)
        hideBeforeDueDateControlViews(viewModel.whenToPay.value != .onDueDate)
    }
    
    // manipulate Group 1
    func hideAmountNotToExceedControlViews(_ isHidden: Bool) {
        amountNotToExceedTextField.isHidden = isHidden
        amountNotToExceedDetailsLabel.isHidden = isHidden
        
        viewModel.amountToPay.value = isHidden ? .amountDue : .upToAmount
        amountNotToExceedSpacerView1.isHidden = isHidden
        
        amountNotToExceedSpacerView1.isHidden = isHidden
        amountNotToExceedSpacerView2.isHidden = isHidden
    }
    
    func hideBeforeDueDateControlViews(_ isHidden: Bool) {
        onDueDateDetailsLabel.isHidden = isHidden
        beforeDueDateDetailsLabel.isHidden = !isHidden
        
        onDueDateSpacerView1.isHidden = isHidden
        beforeDateSpacerView1.isHidden = !isHidden
        
        viewModel.whenToPay.value = isHidden ? .beforeDueDate : .onDueDate
    }
    
    func buildStackViews() {
        
        let stackView1 = buildAmountToPayGroup()
        
        stackView.addArrangedSubview(stackView1)
        
        let stackView2 = buildWhenToPayGroup()
        
        stackView.addArrangedSubview(stackView2)

        let bottomSpace = UIView()
        
        stackView.addArrangedSubview(bottomSpace)
    }
    
    func didTap() {
        amountNotToExceedTextField.resignFirstResponder()
    }
    
    func buildAmountToPayGroup() -> UIStackView {
        // start of first group, header
        amountDueHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        amountDueHeaderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        amountDueHeaderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        amountDueHeaderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        amountDueHeaderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        amountDueHeaderLabel.numberOfLines = 0
        amountDueHeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        amountDueHeaderLabel.text = NSLocalizedString("How much do you want to pay?", comment: "")
        
        //
        let group1Button1StackView = buildGroup1Button1()
        
        // adding first button stack view to first group stack view
        amountDueStackView.addArrangedSubview(group1Button1StackView)
        
        //
        let group1Button2StackView = buildGroup1Button2()
        
        // adding second button stack view to first group stack view
        amountDueStackView.addArrangedSubview(group1Button2StackView)
        
        for control in amountDueRadioControlsSet {
            control.addTarget(self, action: #selector(radioControlSet1Pressed(control:)), for: .touchUpInside)
        }
        
        return amountDueStackView
    }
    
    func buildGroup1Button1() -> UIStackView {
        // start of first group, first button
        totalAmountDueRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        // add button to button stack view
        totalAmountDueButtonStackView.addArrangedSubview(totalAmountDueRadioControl)
        
        amountDueRadioControlsSet.append(totalAmountDueRadioControl)
        
        // adding divider to first button
        let separator1 = SeparatorLineView.create(leadingSpace: separatorInset)
        
        totalAmountDueButtonStackView.addArrangedSubview(separator1)

        return totalAmountDueButtonStackView
    }
    
    func buildGroup1Button2() -> UIStackView {
        // start of first group, second button
        amountNotToExceedRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        // adding button to button stack view
        amountNotToExceedButtonStackView.addArrangedSubview(amountNotToExceedRadioControl)
        
        amountDueRadioControlsSet.append(amountNotToExceedRadioControl)
        
        // creating text field for second button
        amountNotToExceedTextField.textField.placeholder = NSLocalizedString("Amount Not To Exceed*", comment: "")
        amountNotToExceedTextField.textField.autocorrectionType = .no
        amountNotToExceedTextField.textField.delegate = self
        amountNotToExceedTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        amountNotToExceedTextField.setKeyboardType(.decimalPad)
        
        // adding textfield for second button stack view
        amountNotToExceedButtonStackView.addArrangedSubview(amountNotToExceedTextField)
        
        // adding spacer between text field and details label (currently 10 px tall)
        amountNotToExceedSpacerView1 = SeparatorSpaceView.create()
        amountNotToExceedButtonStackView.addArrangedSubview(amountNotToExceedSpacerView1)
        
        viewModel.amountNotToExceed.asDriver().drive(amountNotToExceedTextField.textField.rx.text.orEmpty).disposed(by: disposeBag)
        amountNotToExceedTextField.textField.rx.text.orEmpty.bind(to: viewModel.amountNotToExceed).disposed(by: disposeBag)
        
        // creating details label for second button
        amountNotToExceedDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        amountNotToExceedDetailsLabel.numberOfLines = 0
        amountNotToExceedDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        amountNotToExceedDetailsLabel.text = NSLocalizedString("If your bill amount exceeds this threshold you will receive an email alert at the time the automatic payment is created, and you will be responsible for submitting another one-time payment for the remaining amount.\n\nPlease note that any payments made for less than the total amount due or after the indicated due date may result in collection activity up to and including disconnection of service.", comment: "")
        
        // adding details for second button to second button stack view
        amountNotToExceedButtonStackView.addArrangedSubview(amountNotToExceedDetailsLabel)
        
        // adding spacer between details label and separator
        amountNotToExceedSpacerView2 = SeparatorSpaceView.create(withHeight: spacerHeight)

        amountNotToExceedButtonStackView.addArrangedSubview(amountNotToExceedSpacerView2)
        
        // adding separator to end of second button stack view
        let separator2 = SeparatorLineView.create(leadingSpace: separatorInset)
        amountNotToExceedButtonStackView.addArrangedSubview(separator2)

        return amountNotToExceedButtonStackView
    }
    
    func buildWhenToPayGroup() -> UIStackView {
        //
        dueDateHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateHeaderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        dueDateHeaderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        dueDateHeaderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        dueDateHeaderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        dueDateHeaderLabel.numberOfLines = 0
        dueDateHeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        dueDateHeaderLabel.text = NSLocalizedString("When do you want to pay?", comment: "")
        
        //
        let group2Button1 = buildGroup2Button1()
        
        dueDateStackView.addArrangedSubview(group2Button1)
        
        //
        let group2Button2 = buildGroup2Button2()
        
        dueDateStackView.addArrangedSubview(group2Button2)
        
        for control in dueDateRadioControlsSet {
            control.addTarget(self, action: #selector(radioControlSet2Pressed(control:)), for: .touchUpInside)
        }

        return dueDateStackView
    }
    
    func buildGroup2Button1() -> UIStackView {
        onDueDateRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        onDueDateButtonStackView.addArrangedSubview(onDueDateRadioControl)
        
        dueDateRadioControlsSet.append(onDueDateRadioControl)
        
        onDueDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        onDueDateDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        onDueDateDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        onDueDateDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        onDueDateDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        onDueDateDetailsLabel.numberOfLines = 0
        onDueDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        onDueDateDetailsLabel.text = NSLocalizedString("Your payments will process on each bill's due date. An upcoming automatic payment will be created each time a bill is generated to give you the opportunity to view and cancel the payment on the Bill & Payment Activity page, if necessary.", comment: "")
        
        onDueDateButtonStackView.addArrangedSubview(onDueDateDetailsLabel)
        
        onDueDateSpacerView1 = SeparatorSpaceView.create(withHeight: spacerHeight)
        onDueDateButtonStackView.addArrangedSubview(onDueDateSpacerView1)
        
        let separator1 = SeparatorLineView.create(leadingSpace: separatorInset)
        onDueDateButtonStackView.addArrangedSubview(separator1)

        return onDueDateButtonStackView
    }
    
    func buildGroup2Button2() -> UIStackView {
        beforeDueDateRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        beforeDueDateRadioControl.detailButtonTitle = NSLocalizedString("Select Number", comment: "")
        
        beforeDueDateButtonStackView.addArrangedSubview(beforeDueDateRadioControl)
        
        dueDateRadioControlsSet.append(beforeDueDateRadioControl)
        
        beforeDueDateRadioControl.detailButton.addTarget(self, action: #selector(beforeDueDateButtonPressed), for: .touchUpInside)
        
        beforeDueDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        beforeDueDateDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        beforeDueDateDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        beforeDueDateDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        beforeDueDateDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        beforeDueDateDetailsLabel.numberOfLines = 0
        beforeDueDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        modifyBeforeDueDateDetailsLabel()
        
        beforeDueDateButtonStackView.addArrangedSubview(beforeDueDateDetailsLabel)
        
        beforeDateSpacerView1 = SeparatorSpaceView.create(withHeight: spacerHeight)
        beforeDueDateButtonStackView.addArrangedSubview(beforeDateSpacerView1)
        
        let separator2 = SeparatorLineView.create(leadingSpace: separatorInset)
        beforeDueDateButtonStackView.addArrangedSubview(separator2)

        return beforeDueDateButtonStackView
    }
    
    func modifyBeforeDueDateDetailsLabel() {
        let numDays = viewModel.numberOfDaysBeforeDueDate.value
        let numDaysPlural = numDays == 1 ? "" : "s"
        
        beforeDueDateDetailsLabel.text = "Your payment will be processed on your selected number of days before each bill's due date or the next business day. An upcoming automatic payment will be created each time a bill is generated to give you the opportunity to view and cancel the payment on the Bill & Payment Activity page, if necessary."
        if numDays == 0 {
            beforeDueDateRadioControl.detailButtonTitle = NSLocalizedString("Select Number", comment: "")
        } else {
            beforeDueDateRadioControl.detailButtonTitle = String.localizedStringWithFormat("%@ Day%@", String(numDays), numDaysPlural)
        }
    }
    
    @objc func beforeDueDateButtonPressed() {
        showBeforeDueDatePicker()
    }
    
    private func showBeforeDueDatePicker() {
        view.endEditing(true)
        // Delay here fixes a bug when button is tapped with keyboard up
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: { [weak self] in
            guard let self = self else { return }
            let selectedIndex = self.viewModel.numberOfDaysBeforeDueDate.value == 0 ?
                0 : (self.viewModel.numberOfDaysBeforeDueDate.value - 1)
            PickerView.showStringPicker(withTitle: NSLocalizedString("Select Number", comment: ""),
                                        data: (1...10).map { $0 == 1 ? "\($0) Day" : "\($0) Days" },
                                        selectedIndex: selectedIndex,
                                        onDone: { [weak self] value, index in
                                            DispatchQueue.main.async { [weak self] in
                                                guard let self = self else { return }
                                                let day = index + 1
                                                self.viewModel.numberOfDaysBeforeDueDate.value = day
                                                self.modifyBeforeDueDateDetailsLabel()
                                            }
                },
                                        onCancel: nil)
            UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select number of days", comment: ""))
        })
    }
    
    @objc func radioControlSet1Pressed(control: UIControl) {
        control.isSelected = true
        
        amountDueRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }

        hideAmountNotToExceedControlViews(control != amountNotToExceedRadioControl)
    }
    
    @objc func radioControlSet2Pressed(control: UIControl) {
        control.isSelected = true
        
        dueDateRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }
        
        hideBeforeDueDateControlViews(control != onDueDateRadioControl)
        
        // Show the picker immediately upon "Before Due Date" selection
        // if no value has already been selected
        if control == beforeDueDateRadioControl && viewModel.numberOfDaysBeforeDueDate.value == 0 {
            showBeforeDueDatePicker()
        }
    }
    
    @objc func onCancelPress() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func onDonePress(amountNotToExceed: Double) {
        guard doneButton.isEnabled else { return }
        
        delegate?.didUpdateSettings(amountToPay: viewModel.amountToPay.value,
                                    amountNotToExceed: amountNotToExceed,
                                    whenToPay: viewModel.whenToPay.value,
                                    numberOfDaysBeforeDueDate: viewModel.numberOfDaysBeforeDueDate.value)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - ScrollView
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        var safeAreaBottomInset: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeAreaBottomInset = self.view.safeAreaInsets.bottom
        }
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - Text Field Delegate

extension BGEAutoPaySettingsViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == amountNotToExceedTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
        }
        
        return true
    }
}
