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
import ToastSwiftFramework
import Mapper


class SelectSecurityQuestionsViewController: UIViewController {

    let disposeBag = DisposeBag()
    
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
    
    var viewModel: RegistrationViewModel!// = RegistrationViewModel(registrationService: ServiceFactory.createRegistrationService())
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSecurityQuestionsAndAccounts()
        
        setupNavigationButtons()

        title = NSLocalizedString("Security Questions", comment: "")
        
        setupNavigationButtons()
        
        populateHelperLabels()
        
        populateAccountListingLabels()
        
        setupValidation()
        
        prepareQuestions()
        
        prepareTextFieldsForInput()
        
        createTestAccounts()
        
        viewModel.paperlessEbill.value = true
        
        if viewModel.accounts.value.count > 1 {
            displayAccountListing()
        }
    }
    
    func createTestAccounts() {
        var account1: AccountLookupResult
        var account2: AccountLookupResult
        
        let acct1 = ["AccountNumber": "0123", "StreetNumber": "456", "ApartmentUnitNumber": "789"]
        let acct2 = ["AccountNumber": "3210", "StreetNumber": "654", "ApartmentUnitNumber": "987"]
        
        let map1 = Mapper(JSON: acct1 as NSDictionary)
        let map2 = Mapper(JSON: acct2 as NSDictionary)
        
        do {
            try account1 = AccountLookupResult(map: map1)
            try account2 = AccountLookupResult(map: map2)
            
            viewModel.accounts.value.removeAll()
            
            viewModel.accounts.value.append(account1)
            viewModel.accounts.value.append(account2)
        } catch {
            
        }
    }
    
    func loadSecurityQuestionsAndAccounts() {
        LoadingView.show()
        
//        Driver.merge(viewModel.loadSecurityQuestionsError/*, viewModel.loadAccountsError*/)
//            .drive(onNext: { errorMessage in
//                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .default) { _ in
//                    LoadingView.show()
//                    
//                    self.viewModel.loadSecurityQuestionsData.onNext(())
//                })
//                
//                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
//                
//                self.present(alert, animated: true, completion: nil)
//            })
//            .addDisposableTo(disposeBag)
//        
//        viewModel.securityQuestionsDataFinishedLoading.drive(onNext: {
//            LoadingView.hide()
//        })
//        .addDisposableTo(disposeBag)

        viewModel.loadSecurityQuestionsData.onNext(())
    }

    /// Helpers
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupNavigationButtons() {
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        
        viewModel.allQuestionsAnswered().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please select your security questions and enter each corresponding answer. All security answers are strictly case sensitive.", comment: "")
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
        if Environment.sharedInstance.opco != .bge {
            question3Label.text = NSLocalizedString("Security Question 3*", comment: "")
            question3Label.font = SystemFont.regular.of(textStyle: .title1)
            question3ContentLabel.isHidden = true
            question3ContentLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            question3ViewWrapper.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
            
            let tap3 = UITapGestureRecognizer(target: self, action: #selector(question3Tapped))
            question3ViewWrapper.isUserInteractionEnabled = true
            question3ViewWrapper.addGestureRecognizer(tap3)
        } else {
            question3Label.isHidden = true
            question3ContentLabel.isHidden = true
        }
}
    
    func prepareTextFieldsForInput() {
        question1AnswerTextField.textField.placeholder = NSLocalizedString("Security Answer 1*", comment: "")
        question1AnswerTextField.textField.autocorrectionType = .no
        question1AnswerTextField.textField.returnKeyType = .next
//        question1AnswerTextField.textField.delegate = self
        question1AnswerTextField.textField.isShowingAccessory = true
        question1AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
        question1AnswerTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        question1AnswerTextField.setEnabled(false)
        
        question2AnswerTextField.textField.placeholder = NSLocalizedString("Security Answer 1*", comment: "")
        question2AnswerTextField.textField.autocorrectionType = .no
        question2AnswerTextField.textField.returnKeyType = .next
//        question2AnswerTextField.textField.delegate = self
        question2AnswerTextField.textField.isShowingAccessory = true
        question2AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
        question2AnswerTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        question2AnswerTextField.setEnabled(false)

        if Environment.sharedInstance.opco != .bge {
            question3AnswerTextField.textField.placeholder = NSLocalizedString("Security Answer 1*", comment: "")
            question3AnswerTextField.textField.autocorrectionType = .no
            question3AnswerTextField.textField.returnKeyType = .next
//            question3AnswerTextField.textField.delegate = self
            question3AnswerTextField.textField.isShowingAccessory = true
            question3AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
            question3AnswerTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            question3AnswerTextField.setEnabled(false)
        } else {
            question3AnswerTextField.isHidden = true
        }
    }
    
    func setupValidation() {
        viewModel.question1Selected().asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
                self.question1ContentLabel.isHidden = !valid
                self.question1ContentLabel.text = self.viewModel.securityQuestion1.value
                
                self.question1AnswerTextField.setEnabled(valid)
            }).addDisposableTo(disposeBag)

        viewModel.question2Selected().asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
                self.question2ContentLabel.isHidden = !valid
                self.question2ContentLabel.text = self.viewModel.securityQuestion2.value
                
                self.question2AnswerTextField.setEnabled(valid)
            }).addDisposableTo(disposeBag)
        
        viewModel.question3Selected().asDriver(onErrorJustReturn: false)
            .drive(onNext: { valid in
                self.question3ContentLabel.isHidden = !valid
                self.question3ContentLabel.text = self.viewModel.securityQuestion3.value
                
                self.question3AnswerTextField.setEnabled(valid)
            }).addDisposableTo(disposeBag)

        // Bind to the view model
        question1AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer1).addDisposableTo(disposeBag)
        question2AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer2).addDisposableTo(disposeBag)
        question3AnswerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityAnswer3).addDisposableTo(disposeBag)
    }
    
    func displayAccountListing() {
        accountListView.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
        
        var accountDetailViews = [AccountDetailsView]()
        
        for account in viewModel.accounts.value {
            let detail = AccountDetailsView.create(withAccount: account)
            accountDetailViews.append(detail)
        }
        
        for detailView in accountDetailViews {
            self.accountDataStackView.addArrangedSubview(detailView)
        }
        
        enrollIneBillSwitch.rx.isOn.bind(to: viewModel.paperlessEbill).addDisposableTo(disposeBag)
    }
    
    func onCancelPress() {
        // We do this to cover the case where we push RegistrationViewController from LandingViewController.
        // When that happens, we want the cancel action to go straight back to LandingViewController.
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onNextPress() {
        view.endEditing(true)
        
//        LoadingView.show()
        
//        LoadingView.hide()
        
        self.performSegue(withIdentifier: "loadRegistrationConfirmationSegue", sender: self)
//        viewModel.validateAccount(onSuccess: {
//            LoadingView.hide()
//            
//            self.performSegue(withIdentifier: "createUsernamePasswordSegue", sender: self)
//        }, onMultipleAccounts:  {
//            LoadingView.hide()
//            
//            self.performSegue(withIdentifier: "loadChooseAccountSegue", sender: self)
//        }, onError: { (title, message) in
//            LoadingView.hide()
//            
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
//            
//            self.present(alertController, animated: true, completion: nil)
//        })
    }
    
    @IBAction func enrollIneBillToggle(_ sender: Any) {
        viewModel.paperlessEbill.value = !viewModel.paperlessEbill.value
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SecurityQuestionListViewController {
            vc.viewModel = viewModel
        }
    }

    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    func question1Tapped() {
        viewModel.selectedQuestionRow = 1
        viewModel.selectedQuestion = viewModel.securityQuestion1.value
        
        self.performSegue(withIdentifier: "loadSecretQuestionListSegue", sender: self)
    }

    func question2Tapped() {
        viewModel.selectedQuestionRow = 2
        viewModel.selectedQuestion = viewModel.securityQuestion2.value

        self.performSegue(withIdentifier: "loadSecretQuestionListSegue", sender: self)
    }

    func question3Tapped() {
        viewModel.selectedQuestionRow = 3
        viewModel.selectedQuestion = viewModel.securityQuestion3.value

        self.performSegue(withIdentifier: "loadSecretQuestionListSegue", sender: self)
    }
}
