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
    let now = Calendar.current.startOfDay(for: Date())
    let lastDate = Calendar.current.date(byAdding: .year, value: 100, to: Calendar.current.startOfDay(for: Date()))
    
    var dayPickerView: ExelonPickerContainerView!
    
    var numberOfDaysBefore: [String]!

    var viewModel: BGEAutoPayViewModel! // Passed from BGEAutoPayViewController
    
    var zPositionForWindow: CGFloat = 0.0
    
    let separatorInset: CGFloat = 34.0
    let spacerHeight: CGFloat = 20.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        title = NSLocalizedString("AutoPay Settings", comment: "")

        let systemBack = Bundle.main.loadNibNamed("UINavigationBackButton", owner: self, options: nil)![0] as! UINavigationBackButton
        systemBack.addTarget(self, action: #selector(onBackPress), for: .touchUpInside)
        let backButton = UIBarButtonItem(customView: systemBack)
        backButton.isAccessibilityElement = true
        backButton.accessibilityLabel = NSLocalizedString("Back", comment: "")
        let negativeSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -8
        navigationItem.leftBarButtonItems = [negativeSpacer, backButton]
        
        buildStackViews()
        
        loadSettings()
        
        amountNotToExceedTextField.textField.rx.controlEvent(.editingChanged)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if let text = self.amountNotToExceedTextField.textField.text {
                    if !text.isEmpty {
                        self.viewModel.userDidChangeSettings.value = true
                        self.viewModel.formatAmountNotToExceed()
                    }
                }
            }).disposed(by: disposeBag)
        
        numberOfPaymentsTextField.textField.rx.controlEvent(.editingChanged)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if let text = self.numberOfPaymentsTextField.textField.text {
                    if !text.isEmpty {
                        self.viewModel.userDidChangeSettings.value = true
                    }
                }
            }).disposed(by: disposeBag)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        dLog(className)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics().logScreenView(AnalyticsPageView.AutoPayModifySettingsOffer.rawValue)
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            untilDateButton.accessibilityUpdate(dateText: dateFormatter.string(from: date) + ", selected")
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        buildPickerView()
    }
    
    func buildPickerView() {
        
        //build dataArray for picker
        let dataArray = (1...15).map { $0 == 1 ? "\($0) Day" : "\($0) Days" }
        
        guard let currentWindow = UIApplication.shared.keyWindow else {
            fatalError("No keyWindow?")
        }
        
        dayPickerView = ExelonPickerContainerView(frame: currentWindow.frame, dataArray: dataArray)
        
        currentWindow.addSubview(dayPickerView)
        
        dayPickerView.leadingAnchor.constraint(equalTo: currentWindow.leadingAnchor, constant: 0).isActive = true
        dayPickerView.trailingAnchor.constraint(equalTo: currentWindow.trailingAnchor, constant: 0).isActive = true
        dayPickerView.topAnchor.constraint(equalTo: currentWindow.topAnchor, constant: 0).isActive = true

        let height = dayPickerView.containerView.frame.size.height + 8
        dayPickerView.bottomConstraint.constant = height
        
        dayPickerView.delegate = self
        
        zPositionForWindow = currentWindow.layer.zPosition

        dayPickerView.isHidden = true
    }
    
    func showPickerView(_ showPicker: Bool, completion: (() -> ())? = nil) {
        if showPicker {
            let row = viewModel.numberOfDaysBeforeDueDate.value == "0" ? 1 : Int(viewModel.numberOfDaysBeforeDueDate.value)!
            dayPickerView.selectRow(row - 1)
            dayPickerView.isHidden = false
        }
        
        dayPickerView.layer.zPosition = showPicker ? zPositionForWindow : -1
        UIApplication.shared.keyWindow?.layer.zPosition = showPicker ? -1 : zPositionForWindow
        
        var bottomAnchorLength = dayPickerView.containerView.frame.size.height + 8
        var alpha:Float = 0.0
        
        if showPicker {
            alpha = 0.6
            bottomAnchorLength = -8
        }

        dayPickerView.bottomConstraint.constant = bottomAnchorLength
    
        dayPickerView.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, animations: {
            self.dayPickerView.layoutIfNeeded()
            
            self.dayPickerView.backgroundColor =  UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: alpha)
        }, completion: { [weak self] _ in
            guard let `self` = self else { return }
            if !showPicker {
                self.dayPickerView.accessibilityViewIsModal = false
                self.dayPickerView.isHidden = true
            } else {
                self.dayPickerView.accessibilityViewIsModal = true
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.dayPickerView)
            }
            
            completion?()
        })
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
        amountDueHeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        amountDueHeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        amountDueHeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        amountDueHeaderLabel.setContentHuggingPriority(999, for: .vertical)
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
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        amountNotToExceedDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        amountNotToExceedDetailsLabel.setContentHuggingPriority(999, for: .vertical)
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
        dueDateHeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        dueDateHeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        dueDateHeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        dueDateHeaderLabel.setContentHuggingPriority(999, for: .vertical)
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
        onDueDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        onDueDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        onDueDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        onDueDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
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
        beforeDueDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        beforeDueDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        beforeDueDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        beforeDueDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
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
        numberOfPaymentsHeaderLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        numberOfPaymentsHeaderLabel.setContentCompressionResistancePriority(999, for: .vertical)
        numberOfPaymentsHeaderLabel.setContentHuggingPriority(751, for: .horizontal)
        numberOfPaymentsHeaderLabel.setContentHuggingPriority(999, for: .vertical)
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
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        untilCanceledDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        untilCanceledDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        untilCanceledDetailsLabel.setContentHuggingPriority(999, for: .vertical)
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
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        numberOfPaymentsDetailsLabel.setContentHuggingPriority(999, for: .vertical)
        numberOfPaymentsDetailsLabel.numberOfLines = 0
        numberOfPaymentsDetailsLabel.font = SystemFont.regular.of(textStyle: .footnote)
        numberOfPaymentsDetailsLabel.text = NSLocalizedString("After your selected number of payments have been created, AutoPay will automatically stop and you will be responsible for restarting AutoPay or resuming manual payments on your accounts.", comment: "")
        
        
        
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
        untilDateButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        untilDateButton.backgroundColorOnPress = .softGray
        
        untilDateButtonStackView.addArrangedSubview(untilDateButton)
        
        untilDateSpacerView1 = SeparatorSpaceView.create(withHeight: spacerHeight)
        untilDateButtonStackView.addArrangedSubview(untilDateSpacerView1)
        
        untilDateDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        untilDateDetailsLabel.setContentCompressionResistancePriority(751, for: .horizontal)
        untilDateDetailsLabel.setContentCompressionResistancePriority(999, for: .vertical)
        untilDateDetailsLabel.setContentHuggingPriority(751, for: .horizontal)
        untilDateDetailsLabel.setContentHuggingPriority(999, for: .vertical)
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
    
    func beforeDueDateButtonPressed() {
        view.endEditing(true)
        // Delay here fixes a bug when button is tapped with keyboard up
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: { [weak self] in
            guard let `self` = self else { return }
            self.showPickerView(true)
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, NSLocalizedString("Please select number of days", comment: ""))
        })
    }

    
    func onDateButtonSelected() {
        view.endEditing(true)
        
        let calendarVC = PDTSimpleCalendarViewController()
        
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
    func radioControlSet1Pressed(control: UIControl) {
        viewModel.userDidChangeSettings.value = true
        control.isSelected = true
        
        amountDueRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }

        hideAmountNotToExceedControlViews(control != amountNotToExceedRadioControl)
    }
    
    func radioControlSet2Pressed(control: UIControl) {
        viewModel.userDidChangeSettings.value = true
        control.isSelected = true
        
        dueDateRadioControlsSet
            .filter { $0 != control }
            .forEach {
                $0.isSelected = false
            }
        
        hideBeforeDueDateControlViews(control != onDueDateRadioControl)
    }
    
    func radioControlSet3Pressed(control: UIControl) {
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
    
    func onBackPress() {
        if let errorMessage = viewModel.getInvalidSettingsMessage() {
            let alertVc = UIAlertController(title: NSLocalizedString("Missing Required Fields", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func pickerCancelButtonPressed(_ sender: Any) {
        showPickerView(false)
    }
    
    @IBAction func pickerDoneButtonPressed(_ sender: Any) {
        showPickerView(false)
    }
    
    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension BGEAutoPaySettingsViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == numberOfPaymentsTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 4
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        untilDateButton.accessibilityUpdate(dateText: dateFormatter.string(from: date) + ", selected")
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension BGEAutoPaySettingsViewController: ExelonPickerDelegate {
    func cancelPressed() {
        showPickerView(false)
    }
    
    func donePressed(selectedIndex: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let day = selectedIndex + 1
            self.viewModel.userDidChangeSettings.value = true
            self.viewModel.numberOfDaysBeforeDueDate.value = "\(day)"
            self.showPickerView(false, completion: self.modifyBeforeDueDateDetailsLabel)
            Analytics().logScreenView(AnalyticsPageView.AutoPayModifySettingsSubmit.rawValue)
        }
    }
}

