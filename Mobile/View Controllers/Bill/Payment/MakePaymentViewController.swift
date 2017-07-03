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
    
    @IBOutlet weak var billMatrixView: UIView!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
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
        paymentAmountTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: {
            self.paymentAmountTextField.textField.resignFirstResponder()
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
        
        privacyPolicyButton.setTitleColor(.actionBlue, for: .normal)
        privacyPolicyButton.setTitle(NSLocalizedString("Privacy Policy", comment: ""), for: .normal)
        
        stickyPaymentFooterView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: -2), radius: 2.5)
        stickyPaymentFooterPaymentLabel.textColor = .blackText
        stickyPaymentFooterFeeLabel.textColor = .deepGray
        
        bindViewHiding()
        bindViewContent()
        bindButtonTaps()
        addDoneButtonOnKeyboard()
        
        viewModel.fetchWalletItems(onSuccess: nil, onError: nil)
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
        viewModel.isFetchingWalletItems.asDriver().map(!).drive(loadingIndicator.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowContent.map(!).drive(scrollView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowContent.map(!).drive(stickyPaymentFooterView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Account
        viewModel.shouldShowPaymentAccountView.map(!).drive(paymentAccountView.rx.isHidden).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.isFixedPaymentDate.drive(paymentDateButtonView.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDate.map(!).drive(paymentDateFixedDateLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.isFixedPaymentDatePastDue.map(!).drive(paymentDateFixedDatePastDueLabel.rx.isHidden).addDisposableTo(disposeBag)
    }
    
    func bindViewContent() {
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentAccountImageView.rx.image).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentAccountAccountNumberLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.selectedWalletItemNickname.drive(paymentAccountNicknameLabel.rx.text).addDisposableTo(disposeBag)
        
        // Amount Due
        viewModel.amountDueValue.asDriver().drive(amountDueValueLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Amount Text Field
        viewModel.paymentAmount.asDriver().drive(paymentAmountTextField.textField.rx.text.orEmpty).addDisposableTo(disposeBag)
        paymentAmountTextField.textField.rx.text.orEmpty.bind(to: viewModel.paymentAmount).addDisposableTo(disposeBag)
        paymentAmountTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: {
            self.viewModel.formatPaymentAmount()
        }).addDisposableTo(disposeBag)
        
        // Due Date
        viewModel.dueDate.asDriver().drive(dueDateDateLabel.rx.text).addDisposableTo(disposeBag)
        
        // Payment Date
        viewModel.fixedPaymentDateString.asDriver().drive(paymentDateFixedDateLabel.rx.text).addDisposableTo(disposeBag)
    }
    
    func bindButtonTaps() {
        paymentAccountButton.rx.touchUpInside.subscribe(onNext: {
            let miniWalletVC = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "miniWallet") as! MiniWalletViewController
            miniWalletVC.viewModel.walletItems.value = self.viewModel.walletItems.value
            miniWalletVC.viewModel.selectedItem.value = self.viewModel.selectedWalletItem.value
            miniWalletVC.accountDetail = self.viewModel.accountDetail.value
            miniWalletVC.delegate = self
            self.navigationController?.pushViewController(miniWalletVC, animated: true)
        }).addDisposableTo(disposeBag)
    }
    
    func onNextPress() {
        performSegue(withIdentifier: "reviewPaymentSegue", sender: self)
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

extension MakePaymentViewController: MiniWalletViewControllerDelegate {
    
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem) {
        viewModel.selectedWalletItem.value = walletItem
    }
}
