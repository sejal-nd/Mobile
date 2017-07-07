//
//  MakePaymentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/29/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class MakePaymentViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var bankAccountsUnavailableLabel: UILabel!
    
    @IBOutlet weak var paymentAccountView: UIView! // Contains paymentAccountLabel and paymentAccountButton
    @IBOutlet weak var paymentAccountLabel: UILabel! // Label that says "Payment Account" above the button
    @IBOutlet weak var paymentAccountButton: ButtonControl!
    @IBOutlet weak var paymentAccountImageView: UIImageView!
    @IBOutlet weak var paymentAccountAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentAccountNicknameLabel: UILabel!
    
    @IBOutlet weak var amountDueView: UIView! // Contains amountDueTextLabel and amountDueValueLabel
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    
    @IBOutlet weak var paymentAmountView: UIView! // Contains paymentAmountFeeLabel and paymentAmountTextField
    @IBOutlet weak var paymentAmountFeeLabel: UILabel!
    @IBOutlet weak var paymentAmountTextField: FloatLabelTextField!
    
    @IBOutlet weak var dueDateView: UIView!
    @IBOutlet weak var dueDateTextLabel: UILabel!
    @IBOutlet weak var dueDateDateLabel: UILabel!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateButtonView: UIView!
    @IBOutlet weak var paymentDateButton: DisclosureButton!
    @IBOutlet weak var paymentDateFixedDateLabel: UILabel!
    @IBOutlet weak var paymentDateFixedDatePastDueLabel: UILabel!
    
    @IBOutlet weak var addBankAccountView: UIView!
    @IBOutlet weak var addBankAccountFeeLabel: UILabel!
    @IBOutlet weak var addBankAccountButton: ButtonControl!
    
    @IBOutlet weak var addCreditCardView: UIView!
    @IBOutlet weak var addCreditCardFeeLabel: UILabel!
    @IBOutlet weak var addCreditCardButton: ButtonControl!
    
    @IBOutlet weak var billMatrixView: UIView!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    @IBOutlet weak var walletFooterSpacerView: UIView! // Only used for spacing when footerView is hidden
    @IBOutlet weak var walletFooterView: UIView!
    @IBOutlet weak var walletFooterLabel: UILabel!
    
    @IBOutlet weak var stickyPaymentFooterHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stickyPaymentFooterView: UIView!
    @IBOutlet weak var stickyPaymentFooterPaymentLabel: UILabel!
    @IBOutlet weak var stickyPaymentFooterFeeLabel: UILabel!

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    var accountDetail: AccountDetail! // Passed from BillViewController
    lazy var viewModel: PaymentViewModel = {
        PaymentViewModel(walletService: ServiceFactory.createWalletService(), paymentService: ServiceFactory.createPaymentService(), oneTouchPayService: ServiceFactory.createOneTouchPayService(), accountDetail: self.accountDetail)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Make a Payment", comment: "")
        
        let nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        navigationItem.rightBarButtonItem = nextButton
        viewModel.makePaymentNextButtonEnabled.drive(nextButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        bankAccountsUnavailableLabel.textColor = .blackText
        bankAccountsUnavailableLabel.font = SystemFont.semibold.of(textStyle: .headline)
        bankAccountsUnavailableLabel.text = NSLocalizedString("Bank account payments are not available for this account.", comment: "")

        paymentAccountLabel.text = NSLocalizedString("Payment Account", comment: "")
        paymentAccountLabel.textColor = .deepGray
        paymentAccountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentAccountButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        paymentAccountButton.backgroundColorOnPress = .softGray
        paymentAccountAccountNumberLabel.textColor = .blackText
        paymentAccountNicknameLabel.textColor = .middleGray
        
        amountDueTextLabel.text = NSLocalizedString("Amount Due", comment: "")
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueValueLabel.textColor = .blackText
        amountDueValueLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        paymentAmountFeeLabel.textColor = .blackText
        paymentAmountFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        paymentAmountTextField.textField.placeholder = NSLocalizedString("Payment Amount*", comment: "")
        paymentAmountTextField.textField.keyboardType = .decimalPad
        paymentAmountTextField.textField.delegate = self
        paymentAmountTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.viewModel.paymentAmountErrorMessage.asObservable().single().subscribe(onNext: { errorMessage in
                self.paymentAmountTextField.setError(errorMessage)
            }).addDisposableTo(self.disposeBag)
        }).addDisposableTo(disposeBag)
        paymentAmountTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: {
            self.paymentAmountTextField.setError(nil)
        }).addDisposableTo(disposeBag)
        
        dueDateTextLabel.text = NSLocalizedString("Due Date", comment: "")
        dueDateTextLabel.textColor = .deepGray
        dueDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateDateLabel.textColor = .blackText
        dueDateDateLabel.font = SystemFont.semibold.of(textStyle: .title1)
        
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateTextLabel.textColor = .deepGray
        paymentDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        paymentDateButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        paymentDateFixedDateLabel.textColor = .blackText
        paymentDateFixedDateLabel.font = SystemFont.semibold.of(textStyle: .title1)
        paymentDateFixedDatePastDueLabel.textColor = .blackText
        paymentDateFixedDatePastDueLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        addBankAccountFeeLabel.textColor = .blackText
        addBankAccountFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        addBankAccountFeeLabel.text = NSLocalizedString("No convenience fee will be applied.", comment: "")
        addBankAccountButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        addCreditCardFeeLabel.textColor = .blackText
        addCreditCardFeeLabel.font = SystemFont.regular.of(textStyle: .footnote)
        addCreditCardFeeLabel.text = NSLocalizedString("A $2.35 convenience fee will be applied by Bill Matrix, our payment partner.", comment: "")
        addCreditCardButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        privacyPolicyButton.setTitleColor(.actionBlue, for: .normal)
        privacyPolicyButton.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
        
        walletFooterView.backgroundColor = .softGray
        walletFooterLabel.textColor = .deepGray
        walletFooterLabel.font = OpenSans.regular.of(textStyle: .footnote)
        walletFooterLabel.text = viewModel.walletFooterLabelText
        
        stickyPaymentFooterView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        stickyPaymentFooterPaymentLabel.textColor = .blackText
        stickyPaymentFooterFeeLabel.textColor = .deepGray
        
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()
        addDoneButtonOnKeyboard()

        viewModel.formatPaymentAmount() // Initial formatting
        viewModel.fetchWalletItems(onSuccess: nil, onError: nil)
        
        // TODO - Enable these in sprint 14
        addBankAccountButton.isEnabled = false
        addCreditCardButton.isEnabled = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: self, action: #selector(doneButtonAction))
        done.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.actionBlue], for: .normal)
        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()
        paymentAmountTextField.textField.inputAccessoryView = doneToolbar
    }
    
    func doneButtonAction() {
        paymentAmountTextField.textField.resignFirstResponder()
    }
    
    func bindViewHiding() {
        // Loading
        viewModel.isFetchingWalletItems.asDriver().map(!).drive(loadingIndicator.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowContent.map(!).drive(scrollView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowContent.map(!).drive(stickyPaymentFooterView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Cash Only Bank Accounts Unavailable Label
        viewModel.isCashOnlyUser.map(!).drive(bankAccountsUnavailableLabel.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Account
        viewModel.shouldShowPaymentAccountView.map(!).drive(paymentAccountView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Amount Text Field
        viewModel.shouldShowPaymentAmountTextField.map(!).drive(paymentAmountView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.shouldShowPaymentDateView.map(!).drive(paymentDateView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDate.drive(paymentDateButtonView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDate.map(!).drive(paymentDateFixedDateLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDatePastDue.map(!).drive(paymentDateFixedDatePastDueLabel.rx.isHidden).addDisposableTo(disposeBag)
        
        // Add bank/credit card empty wallet state
        viewModel.shouldShowAddBankAccount.map(!).drive(addBankAccountView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowAddCreditCard.map(!).drive(addCreditCardView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Bill Matrix
        viewModel.shouldShowBillMatrixView.map(!).drive(billMatrixView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Wallet empty state info footer
        viewModel.shouldShowWalletFooterView.map(!).drive(walletFooterView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowWalletFooterView.drive(walletFooterSpacerView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Sticky Footer
        viewModel.shouldShowStickyFooterView.drive(onNext: { shouldShow in
            self.stickyPaymentFooterHeightConstraint.constant = shouldShow ? 80 : 0
            self.stickyPaymentFooterView.isHidden = !shouldShow
        }).addDisposableTo(disposeBag)
    }
    
    func bindViewContent() {
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountAccountNumberLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).addDisposableTo(disposeBag)
        
        // Amount Due
        viewModel.amountDueCurrencyString.asDriver().drive(amountDueValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Amount Text Field
        viewModel.paymentAmountFeeLabelText.asDriver().drive(paymentAmountFeeLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.paymentAmount.asDriver().drive(paymentAmountTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
        paymentAmountTextField.textField.rx.text.orEmpty.bind(to: viewModel.paymentAmount).addDisposableTo(disposeBag)
        paymentAmountTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.viewModel.formatPaymentAmount()
        }).addDisposableTo(disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateDateLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateButton.label.rx.text).addDisposableTo(disposeBag)
        viewModel.paymentDateString.asDriver().drive(paymentDateFixedDateLabel.rx.text).addDisposableTo(disposeBag)
        
        viewModel.totalPaymentDisplayString.map { String(format: NSLocalizedString("Total Payment: %@", comment: ""), $0) }.drive(stickyPaymentFooterPaymentLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.paymentAmountFeeFooterLabelText.drive(stickyPaymentFooterFeeLabel.rx.text).addDisposableTo(disposeBag)
    }
    
    func bindButtonTaps() {
        paymentAccountButton.rx.touchUpInside.subscribe(onNext: {
            self.view.endEditing(true)
            let miniWalletVC = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "miniWallet") as! MiniWalletViewController
            miniWalletVC.viewModel.walletItems.value = self.viewModel.walletItems.value
            miniWalletVC.viewModel.selectedItem.value = self.viewModel.selectedWalletItem.value
            miniWalletVC.accountDetail = self.viewModel.accountDetail.value
            miniWalletVC.delegate = self
            self.navigationController?.pushViewController(miniWalletVC, animated: true)
        }).addDisposableTo(disposeBag)
        
        paymentDateButton.rx.touchUpInside.subscribe(onNext: {
            self.view.endEditing(true)
            
            let calendarVC = PDTSimpleCalendarViewController()
            calendarVC.delegate = self
            calendarVC.title = NSLocalizedString("Select Payment Date", comment: "")
            calendarVC.selectedDate = self.viewModel.paymentDate.value
            
            self.navigationController?.pushViewController(calendarVC, animated: true)
        }).addDisposableTo(disposeBag)
        
        privacyPolicyButton.rx.touchUpInside.asDriver().drive(onNext: onPrivacyPolicyPress).addDisposableTo(disposeBag)
    }
    
    func onNextPress() {
        self.view.endEditing(true)
        performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
    }
    
    func onPrivacyPolicyPress() {
        let tacModal = WebViewController(title: NSLocalizedString("Privacy Policy", comment: ""),
                                         url: URL(string:"https://webpayments.billmatrix.com/HTML/privacy_notice_en-us.html")!)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height - stickyPaymentFooterHeightConstraint.constant, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReviewPaymentViewController {
            vc.viewModel = viewModel
        }
    }

}

extension MakePaymentViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.characters.count == 0 { // Allow backspace
            return true
        }
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == paymentAmountTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            
            let numDec = newString.components(separatedBy:".")
            
            if numDec.count > 2 {
                return false
            } else if numDec.count == 2 && numDec[1].characters.count > 2 {
                return false
            }
            
            let containsDecimal = newString.contains(".")
            let containsBackslash = newString.contains("\\")
            
            return (CharacterSet.decimalDigits.isSuperset(of: characterSet) || containsDecimal) && newString.characters.count <= 7 && !containsBackslash
        }
        return true
    }
}

extension MakePaymentViewController: MiniWalletViewControllerDelegate {
    
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem) {
        viewModel.selectedWalletItem.value = walletItem
    }
}

extension MakePaymentViewController: PDTSimpleCalendarViewDelegate {
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, isEnabledDate date: Date!) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        if let dueDate = viewModel.accountDetail.value.billingInfo.dueByDate {
            let startOfDueDate = Calendar.current.startOfDay(for: dueDate)
            return date >= today && date <= startOfDueDate
        } else { // Should never come into play?
            return date >= today
        }
    }
    
    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        viewModel.paymentDate.value = date
    }
}
