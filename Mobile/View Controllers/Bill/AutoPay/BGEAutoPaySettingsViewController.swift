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

class BGEAutoPaySettingsViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    // grand master stackview
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!                          // 1

    // Group 1
    @IBOutlet weak var amountDueStackView: UIStackView!                 //1.1
    
    @IBOutlet weak var amountDueHeaderLabel: UILabel!
    @IBOutlet weak var totalAmountDueButtonStackView: UIStackView!      //1.1.1
    let totalAmountDueRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Total Amount Due", comment: ""))
    
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

    // Group 3
    @IBOutlet weak var numberOfPaymentsStackView: UIStackView!          //1.3
    
    @IBOutlet weak var numberOfPaymentsHeaderLabel: UILabel!
    @IBOutlet weak var untilCanceledButtonStackView: UIStackView!       //1.3.1
    let untilCanceledRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Until Canceled", comment: ""))
    let untilCanceledDetailsLabel = UILabel(frame: .zero)
    var untilCanceledSpacerView = SeparatorSpaceView(frame: .zero)
    var untilCanceledHairline = UIView(frame: .zero)
    
    @IBOutlet weak var numberOfPaymentsButtonStackView: UIStackView!    //1.3.2
    let numberOfPaymentsRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("For Number of Payments", comment: ""))
    let numberOfPaymentsTextField = FloatLabelTextField(frame: .zero)
    var numberOfPaymentsSpacerView1 = SeparatorSpaceView(frame: .zero)
    let numberOfPaymentsDetailsLabel = UILabel(frame: .zero)
    var numberOfPaymentsSpacerView2 = SeparatorSpaceView(frame: .zero)
    var numberOfPaymentsHairline = UIView(frame: .zero)
    
    @IBOutlet weak var untilDateButtonStackView: UIStackView!           //1.3.3
    let untilDateRadioControl = RadioSelectControl.create(withTitle: NSLocalizedString("Until Date", comment: ""))
    let untilDateButton = DateDisclosureButton.create(withLabel: NSLocalizedString("Until Date*", comment: ""))
    var untilDateSpacerView1 = SeparatorSpaceView(frame: .zero)
    let untilDateDetailsLabel = UILabel(frame: .zero)
    var untilDateSpacerView2 = SeparatorSpaceView(frame: .zero)
    var untilDateHairline = UIView(frame: .zero)

    @IBOutlet var numberOfPaymentsRadioControlsSet = [UIControl]()

    //
    let now = Calendar.current.startOfDay(for: .now)
    let lastDate = Calendar.current.date(byAdding: .year, value: 100, to: Calendar.current.startOfDay(for: .now))
    
    var numberOfDaysBefore: [String]!

    var viewModel: BGEAutoPayViewModel! // Passed from BGEAutoPayViewController
    
    var zPositionForWindow: CGFloat = 0.0
    
    let separatorInset: CGFloat = 34.0
    let spacerHeight: CGFloat = 20.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        title = NSLocalizedString("AutoPay Settings", comment: "")

        let systemBack = Bundle.main.loadNibNamed("UINavigationBackButton", owner: self, options: nil)![0] as! UINavigationBackButton
        systemBack.addTarget(self, action: #selector(onBackPress), for: .touchUpInside)
        let backButton = UIBarButtonItem(customView: systemBack)
        backButton.isAccessibilityElement = true
        backButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        navigationItem.leftBarButtonItems = [backButton]
        
        buildStackViews()
        
        loadSettings()
        
        amountNotToExceedTextField.textField.rx.controlEvent(.editingChanged)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let text = self.amountNotToExceedTextField.textField.text {
                    if !text.isEmpty {
                        self.viewModel.userDidChangeSettings.value = true
                        self.viewModel.formatAmountNotToExceed()
                    }
                }
            }).disposed(by: disposeBag)
        
        numberOfPaymentsTextField.textField.rx.controlEvent(.editingChanged)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let text = self.numberOfPaymentsTextField.textField.text {
                    if !text.isEmpty {
                        self.viewModel.userDidChangeSettings.value = true
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if viewModel.initialEnrollmentStatus.value == .enrolled {
            Analytics.log(event: .autoPayModifySettingOffer)
        } else {
            Analytics.log(event: .autoPayModifySettingOfferNew)
        }
    }
    
    func loadSettings() {
        // placeholder for now
        switch(viewModel.amountToPay.value) {
        case .amountDue:
            totalAmountDueRadioControl.isSelected = true
            amountNotToExceedRadioControl.isSelected = false
        
        case .upToAmount:
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
            
        case .maxPayments:
            untilCanceledRadioControl.isSelected = false
            numberOfPaymentsRadioControl.isSelected = true
            untilDateRadioControl.isSelected = false
            
        case .endDate:
            untilCanceledRadioControl.isSelected = false
            numberOfPaymentsRadioControl.isSelected = false
            untilDateRadioControl.isSelected = true
        }
        
        if let date = viewModel.autoPayUntilDate.value {
            untilDateButton.selectedDateLabel.text = date.mmDdYyyyString
            untilDateButton.accessibilityUpdate(dateText: date.shortMonthDayAndYearString + ", selected")
        }
    
        //
        hideAmountNotToExceedControlViews(viewModel.amountToPay.value == .amountDue)
        hideBeforeDueDateControlViews(viewModel.whenToPay.value != .onDueDate)
        
        hideUntilCanceled(viewModel.howLongForAutoPay.value != .untilCanceled)
        hideNumberOfPayments(viewModel.howLongForAutoPay.value != .maxPayments)
        hideUntilDate(viewModel.howLongForAutoPay.value != .endDate)
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
    
    func hideUntilCanceled(_ isHidden: Bool) {
        untilCanceledDetailsLabel.isHidden = isHidden
        
        untilCanceledSpacerView.isHidden = isHidden
        
        if !isHidden {
            viewModel.howLongForAutoPay.value = .untilCanceled
        }
    }
    
    func hideNumberOfPayments(_ isHidden: Bool) {
        numberOfPaymentsTextField.isHidden = isHidden
        numberOfPaymentsDetailsLabel.isHidden = isHidden
        
        numberOfPaymentsSpacerView1.isHidden = isHidden
        numberOfPaymentsSpacerView2.isHidden = isHidden
        
        if !isHidden {
            viewModel.howLongForAutoPay.value = .maxPayments
        }
    }
    
    func hideUntilDate(_ isHidden: Bool) {
        untilDateButton.isHidden = isHidden
        untilDateDetailsLabel.isHidden = isHidden
        
        untilDateSpacerView1.isHidden = isHidden
        untilDateSpacerView2.isHidden = isHidden

        if !isHidden {
            viewModel.howLongForAutoPay.value = .endDate
        }
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
        amountNotToExceedDetailsLabel.text = NSLocalizedString("If your bill amount exceeds this threshold you will receive an email alert at the time the payment is created, and you will be responsible for manually scheduling a payment of the remaining amount. \n\nPlease note that any payments made for less than the total amount due or after the indicated due date may result in your service being disconnected.", comment: "")
        
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
        onDueDateDetailsLabel.text = NSLocalizedString("Your payments will process on each bill's due date. A pending payment will be created several days before it is processed to give you the opportunity to edit or cancel the payment if necessary.", comment: "")
        
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
        beforeDueDateDetailsLabel.text = NSLocalizedString("Your payment will process on your selected number of days before each bill's due date. A pending payment will be created several days before it is processed to give you the opportunity to edit or cancel the payment if necessary.\n\nBGE recommends paying a few days before the due date to ensure adequate processing time.", comment: "")
        
        if viewModel.numberOfDaysBeforeDueDate.value != "0" {
            modifyBeforeDueDateDetailsLabel()
        }
        
        beforeDueDateButtonStackView.addArrangedSubview(beforeDueDateDetailsLabel)
        
        beforeDateSpacerView1 = SeparatorSpaceView.create(withHeight: spacerHeight)
        beforeDueDateButtonStackView.addArrangedSubview(beforeDateSpacerView1)
        
        let separator2 = SeparatorLineView.create(leadingSpace: separatorInset)
        beforeDueDateButtonStackView.addArrangedSubview(separator2)

        return beforeDueDateButtonStackView
    }
    
    func buildRegularPaymentGroup() -> UIStackView {
        ///
        numberOfPaymentsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        numberOfPaymentsHeaderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        numberOfPaymentsHeaderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        numberOfPaymentsHeaderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        numberOfPaymentsHeaderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        numberOfPaymentsHeaderLabel.numberOfLines = 0
        numberOfPaymentsHeaderLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        numberOfPaymentsHeaderLabel.text = NSLocalizedString("How long do you want to use AutoPay?", comment: "")
        
        //
        let group3Button1 = buildGroup3Button1()
        
        numberOfPaymentsStackView.addArrangedSubview(group3Button1)
        
        //
        let group3Button2 = buildGroup3Button2()
        
        numberOfPaymentsStackView.addArrangedSubview(group3Button2)
        
        //
        let group3Button3 = buildGroup3Button3()
        
        numberOfPaymentsStackView.addArrangedSubview(group3Button3)
        
        for control in numberOfPaymentsRadioControlsSet {
            control.addTarget(self, action: #selector(radioControlSet3Pressed(control:)), for: .touchUpInside)
        }

        return numberOfPaymentsStackView
    }
    
    func buildGroup3Button1() -> UIStackView {
        untilCanceledRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        untilCanceledButtonStackView.addArrangedSubview(untilCanceledRadioControl)
        
        numberOfPaymentsRadioControlsSet.append(untilCanceledRadioControl)
        
        untilCanceledDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        untilCanceledDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        untilCanceledDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        untilCanceledDetailsLabel.numberOfLines = 0
        untilCanceledDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        untilCanceledDetailsLabel.text = NSLocalizedString("AutoPay will schedule each month's payment until you manually unenroll from AutoPay, or your account is issued a final bill. This is the best way to keep your payments ongoing.", comment: "")
        
        untilCanceledButtonStackView.addArrangedSubview(untilCanceledDetailsLabel)
        
        untilCanceledSpacerView = SeparatorSpaceView.create(withHeight: spacerHeight)
        untilCanceledButtonStackView.addArrangedSubview(untilCanceledSpacerView)
        
        let separator1 = SeparatorLineView.create(leadingSpace: separatorInset)
        untilCanceledButtonStackView.addArrangedSubview(separator1)

        return untilCanceledButtonStackView
    }
    
    func buildGroup3Button2() -> UIStackView {
        numberOfPaymentsRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        numberOfPaymentsButtonStackView.addArrangedSubview(numberOfPaymentsRadioControl)
        
        numberOfPaymentsRadioControlsSet.append(numberOfPaymentsRadioControl)
        
        numberOfPaymentsTextField.textField.placeholder = NSLocalizedString("Number of Payments*", comment: "")
        numberOfPaymentsTextField.textField.autocorrectionType = .no
        numberOfPaymentsTextField.setKeyboardType(.numberPad)
        numberOfPaymentsTextField.textField.delegate = self
        numberOfPaymentsTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        viewModel.numberOfPayments.asDriver().drive(numberOfPaymentsTextField.textField.rx.text.orEmpty).disposed(by: disposeBag)
        numberOfPaymentsTextField.textField.rx.text.orEmpty.bind(to: viewModel.numberOfPayments).disposed(by: disposeBag)
        
        numberOfPaymentsButtonStackView.addArrangedSubview(numberOfPaymentsTextField)
        
        numberOfPaymentsSpacerView1 = SeparatorSpaceView.create()
        numberOfPaymentsButtonStackView.addArrangedSubview(numberOfPaymentsSpacerView1)
        
        numberOfPaymentsDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        numberOfPaymentsDetailsLabel.numberOfLines = 0
        numberOfPaymentsDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        numberOfPaymentsDetailsLabel.text = NSLocalizedString("After your selected number of payments have been created, AutoPay will automatically stop and you will be responsible for restarting AutoPay or resuming manual payments on your account.", comment: "")
        
        numberOfPaymentsButtonStackView.addArrangedSubview(numberOfPaymentsDetailsLabel)
        
        numberOfPaymentsSpacerView2 = SeparatorSpaceView.create(withHeight: spacerHeight)
        numberOfPaymentsButtonStackView.addArrangedSubview(numberOfPaymentsSpacerView2)
        
        let separator2 = SeparatorLineView.create(leadingSpace: separatorInset)
        numberOfPaymentsButtonStackView.addArrangedSubview(separator2)

        return numberOfPaymentsButtonStackView
    }
    
    func buildGroup3Button3() -> UIStackView {
        untilDateRadioControl.titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        untilDateButtonStackView.addArrangedSubview(untilDateRadioControl)
        
        numberOfPaymentsRadioControlsSet.append(untilDateRadioControl)
        
        untilDateButton.addTarget(self, action: #selector(onDateButtonSelected), for: .touchUpInside)
        untilDateButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        untilDateButton.backgroundColorOnPress = .softGray
        
        untilDateButtonStackView.addArrangedSubview(untilDateButton)
        
        untilDateSpacerView1 = SeparatorSpaceView.create(withHeight: spacerHeight)
        untilDateButtonStackView.addArrangedSubview(untilDateSpacerView1)
        
        untilDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        untilDateDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        untilDateDetailsLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        untilDateDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        untilDateDetailsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        untilDateDetailsLabel.numberOfLines = 0
        untilDateDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        untilDateDetailsLabel.text = NSLocalizedString("AutoPay will schedule each month’s payment until the date you choose, after which AutoPay will automatically stop and you will be responsible for restarting AutoPay or resuming manual payments on your account.", comment: "")
        
        untilDateButtonStackView.addArrangedSubview(untilDateDetailsLabel)
        
        untilDateSpacerView2 = SeparatorSpaceView.create(withHeight: spacerHeight)
        untilDateButtonStackView.addArrangedSubview(untilDateSpacerView2)
        
        let separator3 = SeparatorLineView.create(leadingSpace: separatorInset)
        untilDateButtonStackView.addArrangedSubview(separator3)

        return untilDateButtonStackView
    }
    
    func modifyBeforeDueDateDetailsLabel() {
        let numDays = viewModel.numberOfDaysBeforeDueDate.value
        
        let numDaysPlural = numDays > "1" ? "s" : ""
        
        beforeDueDateDetailsLabel.text = NSLocalizedString("Your payment will process \(numDays) day\(numDaysPlural) before each bill's due date. A pending payment will be created several days before it is processed to give you the opportunity to edit or cancel the payment if necessary\n\nBGE recommends paying a few days before the due date to ensure adequate processing time.", comment: "")
        
        beforeDueDateRadioControl.detailButtonTitle = NSLocalizedString("\(numDays) Day\(numDaysPlural)", comment: "")

    }
    
    @objc func beforeDueDateButtonPressed() {
        view.endEditing(true)
        // Delay here fixes a bug when button is tapped with keyboard up
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: { [weak self] in
            guard let self = self else { return }
            let selectedIndex = self.viewModel.numberOfDaysBeforeDueDate.value == "0" ?
                0 : (Int(self.viewModel.numberOfDaysBeforeDueDate.value)! - 1)
            PickerView.showStringPicker(withTitle: NSLocalizedString("Select Number", comment: ""),
                            data: (1...15).map { $0 == 1 ? "\($0) Day" : "\($0) Days" },
                            selectedIndex: selectedIndex,
                            onDone: { [weak self] value, index in
                                DispatchQueue.main.async { [weak self] in
                                    guard let self = self else { return }
                                    let day = index + 1
                                    self.viewModel.userDidChangeSettings.value = true
                                    self.viewModel.numberOfDaysBeforeDueDate.value = "\(day)"
                                    self.modifyBeforeDueDateDetailsLabel()
                                }
                },
                            onCancel: nil)
            UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select number of days", comment: ""))
        })
    }

    
    @objc func onDateButtonSelected() {
        view.endEditing(true)
        
        let calendarVC = PDTSimpleCalendarViewController()
        
        calendarVC.calendar = .opCo
        calendarVC.delegate = self
        calendarVC.title = NSLocalizedString("Select Date", comment: "")
        calendarVC.firstDate = now
        calendarVC.lastDate = lastDate
        
        if let date = viewModel.autoPayUntilDate.value {
            calendarVC.selectedDate = date
        }
        
        navigationController?.pushViewController(calendarVC, animated: true)
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    @objc func radioControlSet1Pressed(control: UIControl) {
        viewModel.userDidChangeSettings.value = true
        control.isSelected = true
        
        amountDueRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }

        hideAmountNotToExceedControlViews(control != amountNotToExceedRadioControl)
    }
    
    @objc func radioControlSet2Pressed(control: UIControl) {
        viewModel.userDidChangeSettings.value = true
        control.isSelected = true
        
        dueDateRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }
        
        hideBeforeDueDateControlViews(control != onDueDateRadioControl)
    }
    
    @objc func radioControlSet3Pressed(control: UIControl) {
        viewModel.userDidChangeSettings.value = true
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
    
    @objc func onBackPress() {
        if let errorMessage = viewModel.getInvalidSettingsMessage() {
            let alertVc = UIAlertController(title: NSLocalizedString("Missing Required Fields", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
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
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension BGEAutoPaySettingsViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let isDecimalNumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
        if textField == numberOfPaymentsTextField.textField {
            return isDecimalNumber && newString.count <= 4
        } else if textField == amountNotToExceedTextField.textField {
            return isDecimalNumber// && newString.count <= 15
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
        viewModel.userDidChangeSettings.value = true
        viewModel.autoPayUntilDate.value = date
        untilDateButton.selectedDateLabel.text = date.mmDdYyyyString
        untilDateButton.accessibilityUpdate(dateText: date.shortMonthDayAndYearString + ", selected")
    }
}


