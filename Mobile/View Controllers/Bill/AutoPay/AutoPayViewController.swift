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

protocol AutoPayViewControllerDelegate: class {
    func autoPayViewController(_ autoPayViewController: AutoPayViewController, enrolled: Bool)
}

class AutoPayViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var learnMoreButton: ButtonControl!
    @IBOutlet weak var learnMoreLabel: UILabel!
    
    // Not Enrolled
    @IBOutlet weak var enrollStackView: UIStackView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var checkingSavingsSegmentedControl: SegmentedControl!
    @IBOutlet weak var nameTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTextField: FloatLabelTextField!
    @IBOutlet weak var routingNumberTooltipButton: UIButton!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    @IBOutlet weak var confirmAccountNumberTextField: FloatLabelTextField!
    
    @IBOutlet weak var tacStackView: UIStackView!
    @IBOutlet weak var tacSwitch: Switch!
    @IBOutlet weak var tacLabel: UILabel!
    @IBOutlet weak var tacButton: UIButton!
    
    // Enrolled
    @IBOutlet weak var enrolledStackView: UIStackView!
    @IBOutlet weak var enrollSwitch: Switch!
    @IBOutlet weak var enrollmentStatusLabel: UILabel!
    @IBOutlet weak var enrolledContentView: UIView!
    @IBOutlet weak var enrolledTopLabel: UILabel!
    
    // Unenrolling
    @IBOutlet weak var reasonForStoppingContainerView: UIView!
    @IBOutlet weak var reasonForStoppingTableView: IntrinsicHeightTableView!
    @IBOutlet weak var reasonForStoppingLabel: UILabel!
	
    @IBOutlet weak var footerLabel: UILabel!
    
    weak var delegate: AutoPayViewControllerDelegate?
    
    let bag = DisposeBag()
    
    var accountDetail: AccountDetail!
    lazy var viewModel: AutoPayViewModel = { AutoPayViewModel(withPaymentService: ServiceFactory.createPaymentService(), walletService: ServiceFactory.createWalletService(), accountDetail: self.accountDetail) }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("AutoPay", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        
        NotificationCenter.default.rx.notification(.UIKeyboardWillShow, object: nil)
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: keyboardWillShow)
            .addDisposableTo(bag)
        
        NotificationCenter.default.rx.notification(.UIKeyboardWillHide, object: nil)
            .asDriver(onErrorDriveWith: Driver.empty())
            .drive(onNext: keyboardWillHide)
            .addDisposableTo(bag)
        
        style()
        textFieldSetup()
        bindEnrollingState()
        bindEnrolledState()
        
        viewModel.footerText.drive(footerLabel.rx.text).addDisposableTo(bag)
        viewModel.canSubmit.drive(submitButton.rx.isEnabled).addDisposableTo(bag)
        
        learnMoreButton.rx.touchUpInside.asDriver()
            .drive(onNext: onLearnMorePress)
            .addDisposableTo(bag)
        
        
        // background color hackery
        let isScrollOffsetLessThanZero = scrollView.rx.contentOffset.asDriver()
            .map { $0.y < 0 }
            .distinctUntilChanged()
        
        Driver.combineLatest(viewModel.enrollmentStatus.asDriver(), isScrollOffsetLessThanZero)
            .map { $0 == .unenrolling || $1 }
            .map { $0 ? UIColor.softGray: UIColor.white }
            .drive(onNext: { [weak self] color in
                self?.view.backgroundColor = color
            })
            .addDisposableTo(bag)
        
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
        gLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height/2)
        gLayer.colors = [UIColor.softGray.cgColor, UIColor.white.cgColor]
        
        gradientLayer = gLayer
        gradientView.layer.addSublayer(gLayer)
        
        // Dynamic sizing for the table header view
        if let headerView = reasonForStoppingTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                reasonForStoppingTableView.tableHeaderView = headerView
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height/2)
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.submit()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] enrolled in
                    LoadingView.hide()
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.autoPayViewController(strongSelf, enrolled: enrolled)
                    strongSelf.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] error in
                    LoadingView.hide()
                    guard let strongSelf = self else { return }
                    let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                            message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    strongSelf.present(alertController, animated: true, completion: nil)
            })
            .addDisposableTo(bag)
    }
    
    private func style() {
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
        
        styleNotEnrolled()
        styleEnrolled()
        
        footerLabel.font = OpenSans.regular.of(textStyle: .footnote)
        footerLabel.setLineHeight(lineHeight: 16)
    }
    
    private func styleNotEnrolled() {
        topLabel.font = OpenSans.semibold.of(textStyle: .headline)
        topLabel.setLineHeight(lineHeight: 24)
        
        tacLabel.text = NSLocalizedString("Yes, I have read, understand and agree to the terms and conditions below, and by checking this box, I authorize ComEd to regularly debit the bank account provided.\nI understand that my bank account will be automatically debited each billing period for the total amount due, that these are variable charges, and that my bill being posted in the ComEd mobile app acts as my notification.\nCustomers can see their bill monthly through the ComEd mobile app. Bills are delivered online during each billing cycle. Please note that this will not change your preferred bill delivery method.", comment: "")
        tacLabel.font = SystemFont.regular.of(textStyle: .headline)
        tacLabel.setLineHeight(lineHeight: 25)
        tacButton.titleLabel?.font = SystemFont.bold.of(textStyle: .headline)
    }
    
    private func styleEnrolled() {
        enrollmentStatusLabel.font = OpenSans.regular.of(textStyle: .headline)
        enrolledTopLabel.font = OpenSans.regular.of(textStyle: .body)
        enrolledTopLabel.setLineHeight(lineHeight: 16)
        
        reasonForStoppingLabel.textColor = .blackText
        reasonForStoppingLabel.font = SystemFont.bold.of(textStyle: .subheadline)
    }
    
    private func textFieldSetup() {
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
        confirmAccountNumberTextField.textField.returnKeyType = .done
    }
    
    private func bindEnrolledState() {
        if accountDetail.isAutoPay {
            enrollSwitch.rx.isOn
                .map { isOn -> AutoPayViewModel.AutoPayEnrollmentStatus in
                    isOn ? .isEnrolled: .unenrolling
                }
                .bind(to: viewModel.enrollmentStatus)
                .addDisposableTo(bag)
        }
        
        enrollSwitch.rx.isOn.filter { $0 }.map { _ in nil }.bind(to: viewModel.selectedUnenrollmentReason).addDisposableTo(bag)
        viewModel.selectedUnenrollmentReason.asDriver()
            .filter { $0 == nil }
            .drive(onNext: { [weak self] _ in
                guard let tableView = self?.reasonForStoppingTableView,
                let selectedIndexPath = tableView.indexPathForSelectedRow
                    else { return }
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            })
            .addDisposableTo(bag)
        
        viewModel.enrollmentStatus.asDriver().map { $0 == .enrolling }.drive(enrolledStackView.rx.isHidden).addDisposableTo(bag)
        reasonForStoppingLabel.text = NSLocalizedString("Reason for stopping (pick one)", comment: "")
        reasonForStoppingTableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ReasonForStoppingCell")
        reasonForStoppingTableView.estimatedRowHeight = 51
        reasonForStoppingContainerView.isHidden = true
        viewModel.enrollmentStatus.asDriver()
            .map { $0 == .unenrolling }
            .drive(onNext: { [weak self] unenrolling in
                
                self?.view.backgroundColor = unenrolling ? .softGray: .white
                UIView.animate(withDuration: 0.3) {
                    self?.reasonForStoppingContainerView.isHidden = !unenrolling
                    self?.enrolledContentView.alpha = unenrolling ? 0:1
                    self?.enrolledContentView.isHidden = unenrolling
                }
            })
            .addDisposableTo(bag)
    }
    
    private func bindEnrollingState() {
        
        viewModel.enrollmentStatus.asDriver().map { $0 != .enrolling }.drive(enrollStackView.rx.isHidden).addDisposableTo(bag)
        
        checkingSavingsSegmentedControl.items = [NSLocalizedString("Checking", comment: ""), NSLocalizedString("Savings", comment: "")]
        
        checkingSavingsSegmentedControl.selectedIndex.asObservable()
            .map { selectedIndex -> BankAccountType in
                selectedIndex == 0 ? .checking: .savings
            }
            .bind(to: viewModel.bankAccountType)
            .addDisposableTo(bag)
        
        tacButton.rx.tap.asDriver()
            .drive(onNext: onTermsAndConditionsPress)
            .addDisposableTo(bag)
        
        nameTextField.textField.rx.text.orEmpty.bind(to: viewModel.nameOnAccount).addDisposableTo(bag)
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(bag)
        routingNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.routingNumber).addDisposableTo(bag)
        confirmAccountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.confirmAccountNumber).addDisposableTo(bag)
        tacSwitch.rx.isOn.bind(to: viewModel.termsAndConditionsCheck).addDisposableTo(bag)
        tacStackView.isHidden = !viewModel.shouldShowTermsAndConditionsCheck
        
        // Name on Account
        viewModel.nameOnAccountErrorText
            .drive(onNext: { [weak self] errorText in
                self?.nameTextField.setError(errorText)
            })
            .addDisposableTo(bag)
        
        // Routing Number
        let routingNumberErrorTextFocused: Driver<String?> = routingNumberTextField.textField.rx
            .controlEvent(.editingDidBegin).asDriver()
            .map{ nil }
        routingNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.routingNumberTextField.setError(nil)
        }).addDisposableTo(bag)
        
        let routingNumberErrorTextUnfocused: Driver<String?> = routingNumberTextField.textField.rx
            .controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(viewModel.routingNumberErrorText)
        routingNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            if self.viewModel.routingNumber.value.characters.count == 9 {
                self.viewModel.getBankName(onSuccess: {
                    self.routingNumberTextField.setInfoMessage(self.viewModel.bankName)
                }, onError: {
                    self.routingNumberTextField.setInfoMessage(nil)
                })
            }
        }).addDisposableTo(bag)

        Driver.merge(routingNumberErrorTextFocused, routingNumberErrorTextUnfocused)
            .distinctUntilChanged(==)
            .drive(onNext: { [weak self] errorText in
                self?.routingNumberTextField.setError(errorText)
            })
            .addDisposableTo(bag)
        
        // Account Number
        let accountNumberErrorTextFocused: Driver<String?> = accountNumberTextField.textField.rx
            .controlEvent(.editingDidBegin).asDriver()
            .map{ nil }
        
        let accountNumberErrorTextUnfocused: Driver<String?> = accountNumberTextField.textField.rx
            .controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(viewModel.accountNumberErrorText)
        
        Driver.merge(accountNumberErrorTextFocused, accountNumberErrorTextUnfocused)
            .distinctUntilChanged(==)
            .drive(onNext: { [weak self] errorText in
                self?.accountNumberTextField.setError(errorText)
            })
            .addDisposableTo(bag)
        
        // Confirm Account Number
        viewModel.confirmAccountNumberErrorText
            .drive(onNext: { [weak self] errorText in
                self?.confirmAccountNumberTextField.setError(errorText)
            })
            .addDisposableTo(bag)
        
        viewModel.confirmAccountNumberIsValid
            .drive(onNext: { [weak self] validated in
                self?.confirmAccountNumberTextField.setValidated(validated, accessibilityLabel: NSLocalizedString("Fields match", comment: ""))
            })
            .addDisposableTo(bag)
        
        viewModel.confirmAccountNumberIsEnabled
            .drive(onNext: { [weak self] enabled in
                self?.confirmAccountNumberTextField.setEnabled(enabled)
            })
            .addDisposableTo(bag)
        
        
        routingNumberTooltipButton.rx.tap.asDriver()
            .drive(onNext: onRoutingNumberQuestionMarkPress)
            .addDisposableTo(bag)
        
        accountNumberTooltipButton.rx.tap.asDriver()
            .drive(onNext: onAccountNumberQuestionMarkPress)
            .addDisposableTo(bag)
    }
    
    
    func onTermsAndConditionsPress() {
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""),
                                      url: URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    func onLearnMorePress() {
        let modalDescription = NSLocalizedString("Sign up for AutoPay and you will never have to write another check to pay your bill. With AutoPay, your payment is automatically deducted from your bank account. You will receive a monthly statement notifying you when your payment will be deducted.", comment: "")
        
        let infoModal = InfoModalViewController(title: NSLocalizedString("What is AutoPay?", comment: ""), image: #imageLiteral(resourceName: "img_autopaymodal"), description: modalDescription)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    func onRoutingNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Routing Number", comment: ""), image: #imageLiteral(resourceName: "routing_number_info"), description: NSLocalizedString("This number is used to identify your banking institution. You can find your bank’s nine-digit routing number on the bottom of your paper check.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    func onAccountNumberQuestionMarkPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Account Number", comment: ""), image: #imageLiteral(resourceName: "account_number_info"), description: NSLocalizedString("This number is used to identify your bank account. You can find your checking account number on the bottom of your paper check following the routing number.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
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
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? AutoPayChangeBankViewController {
			vc.viewModel = viewModel
			vc.delegate = self
		}
	}
    
}

extension AutoPayViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        if textField == routingNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 9
        } else if textField == accountNumberTextField.textField || textField == confirmAccountNumberTextField.textField {
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 17
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
        } else if textField == confirmAccountNumberTextField.textField {
            textField.resignFirstResponder()
        }
        return false
    }
}

extension AutoPayViewController: AutoPayChangeBankViewControllerDelegate {
	func changedBank() {
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
			self.view.showToast(NSLocalizedString("AutoPay bank account updated", comment: ""))
		})
	}
}


extension AutoPayViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension AutoPayViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonForStoppingCell", for: indexPath) as! RadioSelectionTableViewCell
        
        cell.label.text = viewModel.reasonStrings[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUnenrollmentReason.value = viewModel.reasonStrings[indexPath.row]
    }
    
}
