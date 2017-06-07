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
    
    @IBOutlet weak var enrollInEbillSwitch: UISwitch!
    
    let viewModel = RegistrationViewModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationButtons()

        title = NSLocalizedString("Security Questions", comment: "")
        
        setupNavigationButtons()
        
        populateHelperLabels()
        
        setupValidation()
        
        prepareQuestions()
        
        prepareTextFieldsForInput()
    }

    /// Helpers
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        
        viewModel.nextButtonEnabled().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please select your security questions and enter each corresponding answer. All security answers are strictly case sensitive.", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
    }
    
    func prepareQuestions() {
        question1Label.text = NSLocalizedString("Security Question 1*", comment: "")
        question1Label.font = SystemFont.regular.of(textStyle: .title1)
        question1ContentLabel.isHidden = true
        question1ContentLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        question1ViewWrapper.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)

        question2Label.text = NSLocalizedString("Security Question 2*", comment: "")
        question2Label.font = SystemFont.regular.of(textStyle: .title1)
        question2ContentLabel.isHidden = true
        question2ContentLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        question2ViewWrapper.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)

        let opCo = Environment.sharedInstance.opco
        
        // if opco is not BGE, then format it and ready it for usage; else hide it.
        if opCo != .bge {
            question3Label.text = NSLocalizedString("Security Question 3*", comment: "")
            question3Label.font = SystemFont.regular.of(textStyle: .title1)
            question3ContentLabel.isHidden = true
            question3ContentLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            question3ViewWrapper.addShadow(color: .black, opacity: 0.1, offset: .zero, radius: 2)
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

        let opCo = Environment.sharedInstance.opco
        
        if opCo != .bge {
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
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func onCancelPress() {
        // We do this to cover the case where we push RegistrationViewController from LandingViewController.
        // When that happens, we want the cancel action to go straight back to LandingViewController.
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: {
            LoadingView.hide()
            
            self.performSegue(withIdentifier: "createUsernamePasswordSegue", sender: self)
        }, onMultipleAccounts:  {
            LoadingView.hide()
            
            self.performSegue(withIdentifier: "loadChooseAccountSegue", sender: self)
        }, onError: { (title, message) in
            LoadingView.hide()
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        })
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
