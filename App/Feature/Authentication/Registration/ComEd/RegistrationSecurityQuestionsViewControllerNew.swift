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

class RegistrationSecurityQuestionsViewControllerNew: KeyboardAvoidingStickyFooterViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var instructionLabel: UILabel!

    @IBOutlet weak var question1QuestionButton: DisclosureButton!
    @IBOutlet weak var question1AnswerTextField: FloatLabelTextField!

    @IBOutlet weak var question2QuestionButton: DisclosureButton!
    @IBOutlet weak var question2AnswerTextField: FloatLabelTextField!
    
    @IBOutlet weak var question3QuestionButton: DisclosureButton!
    @IBOutlet weak var question3AnswerTextField: FloatLabelTextField!
    
    @IBOutlet weak var eBillAutoEnrollView: UIView!
    @IBOutlet weak var eBillAutoEnrollDescriptionTextField: UILabel!
    @IBOutlet weak var eBillUnEnrollTextField: UILabel!
    @IBOutlet weak var eBillAutoEnrollSeparator: UIView!
    
    @IBOutlet weak var accountListView: UIView!
    @IBOutlet weak var accountListStackView: UIStackView!
    @IBOutlet weak var accountListInstructionsLabel: UILabel!
    @IBOutlet weak var accountListHeaderView: UIView!
    
    @IBOutlet weak var accountNumColHeaderLabel: UILabel!
    @IBOutlet weak var streetNumColHeaderLabel: UILabel!
    @IBOutlet weak var unitNumColHeaderLabel: UILabel!
    
    @IBOutlet weak var accountDataStackView: UIStackView!
    
    @IBOutlet weak var registerButton: PrimaryButton!
    
    var viewModel: RegistrationViewModel!
    
    var loadAccountsError = false
    
    let displayAccountsIfGreaterThan = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("Next, select your security questions.\n\nIf you forget your sign in credentials, you’ll be able to recover them by providing the answers to the security questions you choose in this step.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        instructionLabel.setLineHeight(lineHeight: 24)
        
        populateAccountListingLabels()
        
        bindViewModel()
        
        if Environment.shared.opco == .bge || Environment.shared.opco == .comEd {
            // BGE users only need to answer 2 questions
            question3QuestionButton.isHidden = true
            question3AnswerTextField.isHidden = true
        }
        
        question1AnswerTextField.placeholder = NSLocalizedString("Security Answer 1*", comment: "")
        question1AnswerTextField.textField.autocorrectionType = .no
        
        question2AnswerTextField.placeholder = NSLocalizedString("Security Answer 2*", comment: "")
        question2AnswerTextField.textField.autocorrectionType = .no
        
        question3AnswerTextField.placeholder = NSLocalizedString("Security Answer 3*", comment: "")
        question3AnswerTextField.textField.autocorrectionType = .no
        
        viewModel.allQuestionsAnswered.drive(registerButton.rx.isEnabled).disposed(by: disposeBag)
        
        self.eBillAutoEnrollView.isHidden = true
        loadSecurityQuestions()
    }
    
    func loadSecurityQuestions() {
        loadingIndicator.isHidden = false
        scrollView.isHidden = true
        
        viewModel.loadSecurityQuestions(onSuccess: { [weak self] in
            guard let self = self else { return }
            if self.viewModel.isPaperlessEbillEligible {
                self.loadAccounts()
                let opco = Environment.shared.opco
                if opco == .bge {
                    self.eBillAutoEnrollView.isHidden = false
                    self.eBillAutoEnrollDescriptionTextField.font = SystemFont.regular.of(textStyle: .callout)
                    self.eBillAutoEnrollDescriptionTextField.textColor = .deepGray
                    self.eBillAutoEnrollDescriptionTextField.setLineHeight(lineHeight: 16)
                    self.eBillAutoEnrollDescriptionTextField.text = NSLocalizedString("By creating a My Account, you'll be automatically enrolled in Paperless eBill. When your bill is ready, you'll receive an email notification rather than a paper bill.", comment: "")
                    
                    self.eBillUnEnrollTextField.font = SystemFont.regular.of(textStyle: .callout)
                    self.eBillUnEnrollTextField.textColor = .deepGray
                    self.eBillUnEnrollTextField.setLineHeight(lineHeight: 16)
                    self.eBillUnEnrollTextField.text = NSLocalizedString("Want to receive a paper bill? Unenroll in Paperless eBill by navigating to the Bill tab and updating your Billing Options.", comment: "")
                    
                    self.eBillAutoEnrollSeparator.backgroundColor = .accentGray
                }
            } else {
                UIAccessibility.post(notification: .screenChanged, argument: self.scrollView)
                self.scrollView.isHidden = false
                self.loadingIndicator.isHidden = true
                
                self.toggleAccountListing(false)
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
    
    func populateAccountListingLabels() {
        accountListInstructionsLabel.textColor = .deepGray
        accountListInstructionsLabel.text = NSLocalizedString("The following accounts will be enrolled for Paperless eBill.", comment:"")
        accountListInstructionsLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        accountNumColHeaderLabel.textColor = .deepGray
        accountNumColHeaderLabel.text = NSLocalizedString("Account #", comment: "")
        accountNumColHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        streetNumColHeaderLabel.textColor = .deepGray
        streetNumColHeaderLabel.text = NSLocalizedString("Street #", comment: "")
        streetNumColHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        unitNumColHeaderLabel.textColor = .deepGray
        unitNumColHeaderLabel.text = NSLocalizedString("Unit #", comment: "")
        unitNumColHeaderLabel.font = SystemFont.regular.of(textStyle: .footnote)
    }

    func bindViewModel() {
        viewModel.securityQuestion1.asDriver().isNil().not().drive(self.question1AnswerTextField.rx.isEnabled).disposed(by: disposeBag)
        viewModel.securityQuestion2.asDriver().isNil().not().drive(self.question2AnswerTextField.rx.isEnabled).disposed(by: disposeBag)
        viewModel.securityQuestion3.asDriver().isNil().not().drive(self.question3AnswerTextField.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.securityQuestion1.asDriver().filter { $0 != nil }.drive(self.question1QuestionButton.rx.valueText).disposed(by: disposeBag)
        viewModel.securityQuestion2.asDriver().filter { $0 != nil }.drive(self.question2QuestionButton.rx.valueText).disposed(by: disposeBag)
        viewModel.securityQuestion3.asDriver().filter { $0 != nil }.drive(self.question3QuestionButton.rx.valueText).disposed(by: disposeBag)

        question1AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer1).disposed(by: disposeBag)
        question2AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer2).disposed(by: disposeBag)
        question3AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer3).disposed(by: disposeBag)
        
        viewModel.securityQuestion1.asDriver().distinctUntilChanged().drive(onNext: { _ in
            DispatchQueue.main.async {
                self.question1AnswerTextField.textField.text = ""
                self.view.endEditing(true)
            }
        }).disposed(by: disposeBag)
        viewModel.securityQuestion2.asDriver().distinctUntilChanged().drive(onNext: { _ in
            DispatchQueue.main.async {
                self.question2AnswerTextField.textField.text = ""
                self.view.endEditing(true)
            }
        }).disposed(by: disposeBag)
        viewModel.securityQuestion3.asDriver().distinctUntilChanged().drive(onNext: { _ in
            DispatchQueue.main.async {
                self.question3AnswerTextField.textField.text = ""
                self.view.endEditing(true)
            }
        }).disposed(by: disposeBag)
    }
    
    func buildAccountListing() {
        accountListView.isHidden = false
        accountListView.layer.borderWidth = 1
        accountListView.layer.borderColor = UIColor.accentGray.cgColor
        
        var accountDetailViews = [AccountDetailsView]()
        
        for account in viewModel.accounts.value {
            let detail = AccountDetailsView.create(withAccount: account)
            accountDetailViews.append(detail)
        }
        
        for detailView in accountDetailViews {
            accountDataStackView.addArrangedSubview(detailView)
        }
    }
    
    func toggleAccountListing(_ isVisible: Bool) {
        accountListView.isHidden = !isVisible
    }
    
    @IBAction func onRegisterPress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        FirebaseUtility.logEvent(.register, parameters: [EventParameter(parameterName: .action, value: .ebill_enroll)])
        
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
    
    @IBAction func onQuestionButtonPress(_ sender: Any) {
        self.performSegue(withIdentifier: "securityQuestionSegue", sender: sender)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? LargeTitleNavigationController,
            let vc = navController.viewControllers.first as? RegistrationSecurityQuestionListViewController {
            vc.viewModel = viewModel
            switch sender as? DisclosureButton {
            case question1QuestionButton?:
                vc.questionNumber = 1
            case question2QuestionButton?:
                vc.questionNumber = 2
            case question3QuestionButton?:
                vc.questionNumber = 3
            default:
                vc.questionNumber = 0
            }
        } else if let vc = segue.destination as? RegistrationConfirmationViewControllerNew {
            vc.registeredUsername = viewModel.username.value
        }
    }

}
