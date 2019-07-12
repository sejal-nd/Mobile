//
//  SelectSecurityQuestionsViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/5/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Toast_Swift
import Mapper


class RegistrationSecurityQuestionsViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var question1ViewWrapper: UIView!
    @IBOutlet weak var question1Label: UILabel!
    @IBOutlet weak var question1ContentLabel: UILabel!
    @IBOutlet weak var question1AnswerTextField: FloatLabelTextField!

    @IBOutlet weak var question2ViewWrapper: UIView!
    @IBOutlet weak var question2Label: UILabel!
    @IBOutlet weak var question2ContentLabel: UILabel!
    @IBOutlet weak var question2AnswerTextField: FloatLabelTextField!
    
    @IBOutlet weak var question3ViewWrapper: UIView!
    @IBOutlet weak var question3Label: UILabel!
    @IBOutlet weak var question3ContentLabel: UILabel!
    @IBOutlet weak var question3AnswerTextField: FloatLabelTextField!
    
    @IBOutlet weak var eBillSwitchView: UIView!
    @IBOutlet weak var enrollIneBillSwitch: Switch!
    @IBOutlet weak var eBillSwitchInstructions: UILabel!
    
    @IBOutlet weak var accountListView: UIView!
    @IBOutlet weak var accountListStackView: UIStackView!
    @IBOutlet weak var accountListInstructionsLabel: UILabel!
    @IBOutlet weak var accountListHeaderView: UIView!
    
    @IBOutlet weak var accountNumColHeaderLabel: UILabel!
    @IBOutlet weak var streetNumColHeaderLabel: UILabel!
    @IBOutlet weak var unitNumColHeaderLabel: UILabel!
    
    @IBOutlet weak var accountDataStackView: UIStackView!
    
    var viewModel: RegistrationViewModel!
    
    var loadAccountsError = false
    
    let displayAccountsIfGreaterThan = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        loadSecurityQuestions()
        
        setupNavigationButtons()

        title = NSLocalizedString("Register", comment: "")
        
        setupNavigationButtons()
        
        populateHelperLabels()
        
        populateAccountListingLabels()
        
        setupValidation()
        
        prepareQuestions()
        
        prepareTextFieldsForInput()
        
        setupAccessibility()
        
        viewModel.paperlessEbill.value = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadSecurityQuestions() {
        loadingIndicator.isHidden = false
        scrollView.isHidden = true
        
        viewModel.loadSecurityQuestions(onSuccess: { [weak self] in
            guard let self = self else { return }
            if self.viewModel.isPaperlessEbillEligible {
                self.loadAccounts()
            } else {
                UIAccessibility.post(notification: .screenChanged, argument: self.scrollView)
                self.scrollView.isHidden = false
                self.loadingIndicator.isHidden = true
                
                self.toggleAccountListing(false)
                self.eBillSwitchView.isHidden = true
            }
        }, onError: { [weak self] (securityTitle, securityMessage) in
            self?.loadErrorMessage(securityTitle, message: securityMessage)
        })
    }
    
    func loadAccounts() {
        viewModel.loadAccounts(onSuccess: { [weak self] in
            guard let self = self else { return }
            let opco = Environment.shared.opco
            
            if (opco == .peco || opco == .comEd) && self.viewModel.accountType.value == "commercial" {
                UIAccessibility.post(notification: .screenChanged, argument: self.scrollView)
                self.scrollView.isHidden = false
                self.loadingIndicator.isHidden = true
                
                self.toggleAccountListing(false)
                self.eBillSwitchView.isHidden = true
                
                return
            }
            
            self.buildAccountListing()
            self.toggleAccountListing(self.viewModel.accounts.value.count > self.displayAccountsIfGreaterThan)
            
            UIAccessibility.post(notification: .screenChanged, argument: self.scrollView)
            self.scrollView.isHidden = false
            self.loadingIndicator.isHidden = true
            
        }, onError: { [weak self] (accountsTitle, accountsMessage) in
            self?.loadErrorMessage(accountsTitle, message: accountsMessage)
        })
    }
    
    func loadErrorMessage(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default) { [weak self] _ in
            self?.loadSecurityQuestions()
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    func setupNavigationButtons() {
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress(submitButton:)))
        
        viewModel.allQuestionsAnswered.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem = submitButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please select your security questions and enter each corresponding answer. All security answers are case insensitive.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        eBillSwitchInstructions.textColor = .blackText
        eBillSwitchInstructions.text = NSLocalizedString("I would like to enroll in Paperless eBill - a fast, easy, and secure way to receive and pay for bills online.", comment: "")
        eBillSwitchInstructions.font = SystemFont.regular.of(textStyle: .headline)
    }
    
    func populateAccountListingLabels() {
        accountListInstructionsLabel.textColor = .blackText
        accountListInstructionsLabel.text = NSLocalizedString("The following accounts will be enrolled for Paperless eBill.", comment:"")
        accountListInstructionsLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        accountNumColHeaderLabel.textColor = .blackText
        accountNumColHeaderLabel.text = NSLocalizedString("Account #", comment: "")
        accountNumColHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        streetNumColHeaderLabel.textColor = .blackText
        streetNumColHeaderLabel.text = NSLocalizedString("Street #", comment: "")
        streetNumColHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        unitNumColHeaderLabel.textColor = .blackText
        unitNumColHeaderLabel.text = NSLocalizedString("Unit #", comment: "")
        unitNumColHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
    }
    
    func prepareQuestions() {
        question1Label.text = NSLocalizedString("Security Question 1*", comment: "")
        question1Label.font = SystemFont.regular.of(textStyle: .title1)
        question1ContentLabel.isHidden = true
        question1ContentLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        question1ViewWrapper.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(question1Tapped))
        question1ViewWrapper.isUserInteractionEnabled = true
        question1ViewWrapper.addGestureRecognizer(tap1)
        
        question2Label.text = NSLocalizedString("Security Question 2*", comment: "")
        question2Label.font = SystemFont.regular.of(textStyle: .title1)
        question2ContentLabel.isHidden = true
        question2ContentLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        question2ViewWrapper.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(question2Tapped))
        question2ViewWrapper.isUserInteractionEnabled = true
        question2ViewWrapper.addGestureRecognizer(tap2)

        // if opco is not BGE, then format it and ready it for usage; else hide it.
        if Environment.shared.opco != .bge {
            question3Label.text = NSLocalizedString("Security Question 3*", comment: "")
            question3Label.font = SystemFont.regular.of(textStyle: .title1)
            question3ContentLabel.isHidden = true
            question3ContentLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            question3ViewWrapper.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
            
            let tap3 = UITapGestureRecognizer(target: self, action: #selector(question3Tapped))
            question3ViewWrapper.isUserInteractionEnabled = true
            question3ViewWrapper.addGestureRecognizer(tap3)
        } else {
            question3ViewWrapper.isHidden = true
        }
}
    
    func prepareTextFieldsForInput() {
        question1AnswerTextField.textField.placeholder = NSLocalizedString("Security Answer 1*", comment: "")
        question1AnswerTextField.textField.autocorrectionType = .no
        question1AnswerTextField.textField.returnKeyType = .next
        question1AnswerTextField.textField.isShowingAccessory = true
        question1AnswerTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        question1AnswerTextField.setEnabled(false)
        
        question2AnswerTextField.textField.placeholder = NSLocalizedString("Security Answer 2*", comment: "")
        question2AnswerTextField.textField.autocorrectionType = .no
        question2AnswerTextField.textField.returnKeyType = .next
        question2AnswerTextField.textField.isShowingAccessory = true
        question2AnswerTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        question2AnswerTextField.setEnabled(false)

        if Environment.shared.opco != .bge {
            question3AnswerTextField.textField.placeholder = NSLocalizedString("Security Answer 3*", comment: "")
            question3AnswerTextField.textField.autocorrectionType = .no
            question3AnswerTextField.textField.returnKeyType = .next
            question3AnswerTextField.textField.isShowingAccessory = true
            question3AnswerTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            question3AnswerTextField.setEnabled(false)
        } else {
            question3AnswerTextField.isHidden = true
        }
    }
    
    func setupValidation() {
        viewModel.question1Selected
            .drive(onNext: { [weak self] valid in
                guard let self = self else { return }
                self.question1ContentLabel.isHidden = !valid
                self.question1ContentLabel.text = self.viewModel.securityQuestion1.value
                
                self.question1AnswerTextField.setEnabled(valid)
            }).disposed(by: disposeBag)

        viewModel.question2Selected
            .drive(onNext: { [weak self] valid in
                guard let self = self else { return }
                self.question2ContentLabel.isHidden = !valid
                self.question2ContentLabel.text = self.viewModel.securityQuestion2.value
                
                self.question2AnswerTextField.setEnabled(valid)
            }).disposed(by: disposeBag)
        
        viewModel.question3Selected
            .drive(onNext: { [weak self] valid in
                guard let self = self else { return }
                self.question3ContentLabel.isHidden = !valid
                self.question3ContentLabel.text = self.viewModel.securityQuestion3.value
                
                self.question3AnswerTextField.setEnabled(valid)
            }).disposed(by: disposeBag)

        // Bind to the view model
        question1AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer1).disposed(by: disposeBag)
        question2AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer2).disposed(by: disposeBag)
        question3AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer3).disposed(by: disposeBag)
        
        viewModel.securityQuestionChanged
            .drive(onNext: { [weak self] valid in
                guard let self = self else { return }
                switch (self.viewModel.selectedQuestionRow) {
                case 1:
                    self.question1AnswerTextField.textField.text = ""
                case 2:
                    self.question2AnswerTextField.textField.text = ""
                case 3:
                    self.question3AnswerTextField.textField.text = ""
                default:
                    break
                }
            }).disposed(by: disposeBag)
    }
    
    func buildAccountListing() {
        accountListView.isHidden = false
        accountListView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        var accountDetailViews = [AccountDetailsView]()
        
        for account in viewModel.accounts.value {
            let detail = AccountDetailsView.create(withAccount: account)
            accountDetailViews.append(detail)
        }
        
        for detailView in accountDetailViews {
            accountDataStackView.addArrangedSubview(detailView)
        }
        
        enrollIneBillSwitch.rx.isOn.bind(to: viewModel.paperlessEbill).disposed(by: disposeBag)
    }
    
    func setupAccessibility() {
        
        eBillSwitchInstructions.isAccessibilityElement = false
        enrollIneBillSwitch.isAccessibilityElement = true
        enrollIneBillSwitch.accessibilityLabel = NSLocalizedString("I would like to enroll in Paperless eBill - a fast, easy, and secure way to receive and pay for bills online.", comment: "")
        question1Label.accessibilityTraits = .button
        question2Label.accessibilityTraits = .button
        
        if Environment.shared.opco == .bge {
           question3Label.accessibilityTraits = .button 
        }
        
    }
    
    func toggleAccountListing(_ isVisible: Bool) {
        accountListView.isHidden = !isVisible
    }
    
    func onCancelPress() {
        // We do this to cover the case where we push RegistrationViewController from LandingViewController.
        // When that happens, we want the cancel action to go straight back to LandingViewController.
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onSubmitPress(submitButton: UIBarButtonItem) {
        guard submitButton.isEnabled else { return }
        
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.registerUser(onSuccess: { [weak self] in
            guard let self = self else { return }
            LoadingView.hide()

            if self.viewModel.hasStrongPassword {
                GoogleAnalytics.log(event: .strongPasswordComplete)
            }
            
            GoogleAnalytics.log(event: .registerAccountSecurityQuestions)
            self.performSegue(withIdentifier: "loadRegistrationConfirmationSegue", sender: self)

        }, onError: { [weak self] (title, message) in
            LoadingView.hide()
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))

            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func enrollIneBillToggle(_ sender: Any) {
        viewModel.paperlessEbill.value = !viewModel.paperlessEbill.value
        
        toggleAccountListing(viewModel.paperlessEbill.value && viewModel.accounts.value.count > displayAccountsIfGreaterThan)
        
        if(enrollIneBillSwitch.isOn) {
            GoogleAnalytics.log(event: .registerEBillEnroll)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    
    // MARK: - ScrollView
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let safeAreaBottomInset = view.safeAreaInsets.bottom
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RegistrationSecurityQuestionListViewController {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationConfirmationViewController {
            vc.registeredUsername = viewModel.username.value
        }
    }

    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    @objc func question1Tapped() {
        loadSecretQuestionList(forRow: 1, question: viewModel.securityQuestion1.value)
    }

    @objc func question2Tapped() {
        loadSecretQuestionList(forRow: 2, question: viewModel.securityQuestion2.value)
    }

    @objc func question3Tapped() {
        loadSecretQuestionList(forRow: 3, question: viewModel.securityQuestion3.value)
    }
    
    func loadSecretQuestionList(forRow row: Int, question: String) {
        viewModel.selectedQuestionRow = row
        viewModel.selectedQuestion = question
        viewModel.selectedQuestionChanged.value = false
        
        self.performSegue(withIdentifier: "loadSecretQuestionListSegue", sender: self)
        
    }
}
