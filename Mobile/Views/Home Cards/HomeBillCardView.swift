//
//  BillHomeCard.swift
//  Mobile
//
//  Created by Sam Francis on 7/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

class HomeBillCardView: UIView {
    
    var bag = DisposeBag()
    
    @IBOutlet weak var infoStack: UIStackView!
    
    @IBOutlet weak var alertContainer: UIView!
    @IBOutlet weak var alertImageView: UIImageView!
    
    @IBOutlet weak var paymentPendingContainer: UIView!
    @IBOutlet weak var paymentPendingImageView: UIImageView!
    
    @IBOutlet weak var paymentConfirmationContainer: UIView!
    @IBOutlet weak var paymentConfirmationImageView: UIImageView!
    
    @IBOutlet weak var titleContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var dueDateStack: UIStackView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dueDateTooltip: UIButton!
    
    @IBOutlet weak var dueAmountAndDateContainer: UIView!
    @IBOutlet weak var dueAmountAndDateStack: UIStackView!
    @IBOutlet weak var dueAmountAndDateLabel: UILabel!
    @IBOutlet weak var dueAmountAndDateTooltip: UIButton!
    
    @IBOutlet weak var bankCreditNumberContainer: UIView!
    @IBOutlet weak var bankCreditNumberButton: ButtonControl!
    @IBOutlet weak var bankCreditCardImageView: UIImageView!
    @IBOutlet weak var bankCreditCardNumberLabel: UILabel!
    
    @IBOutlet weak var saveAPaymentAccountContainer: UIView!
    @IBOutlet weak var saveAPaymentAccountButton: ButtonControl!
    @IBOutlet weak var saveAPaymentAccountLabel: UILabel!
    
    @IBOutlet weak var minimumPaymentContainer: UIView!
    @IBOutlet weak var minimumPaymentLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeContainer: UIView!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet weak var oneTouchSlider: OneTouchSlider!
    @IBOutlet weak var commercialBgeOtpVisaLabelContainer: UIView!
    @IBOutlet weak var commericalBgeOtpVisaLabel: UILabel!
    
    @IBOutlet weak var scheduledImageContainer: UIView!
    @IBOutlet weak var scheduledImageView: UIImageView!
    
    @IBOutlet weak var autoPayImageContainer: UIView!
    @IBOutlet weak var autoPayImageView: UIImageView!
    
    @IBOutlet weak var automaticPaymentInfoButton: ButtonControl!
    @IBOutlet weak var automaticPaymentInfoButtonLabel: UILabel!
    @IBOutlet weak var thankYouForSchedulingButton: ButtonControl!
    @IBOutlet weak var thankYouForSchedulingButtonLabel: UILabel!
    @IBOutlet weak var oneTouchPayTCButton: ButtonControl!
    @IBOutlet weak var oneTouchPayTCButtonLabel: UILabel!
    
    @IBOutlet weak var viewBillContainer: UIView!
    @IBOutlet weak var viewBillButton: UIButton!
    
    @IBOutlet weak var billNotReadyStack: UIStackView!
    @IBOutlet weak var billNotReadyLabel: UILabel!
    @IBOutlet weak var errorStack: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    
    fileprivate var viewModel: HomeBillCardViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    var cvvValidationDisposable: Disposable?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        styleViews()
    }
    
    static func create(withViewModel viewModel: HomeBillCardViewModel) -> HomeBillCardView {
        let view = Bundle.main.loadViewFromNib() as HomeBillCardView
        view.viewModel = viewModel
        return view
    }
    
    private func styleViews() {
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.cornerRadius = 2
        
        alertImageView.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        
        bankCreditNumberButton.layer.borderColor = UIColor.accentGray.cgColor
        bankCreditNumberButton.layer.borderWidth = 2
        bankCreditNumberButton.layer.cornerRadius = 3
        bankCreditCardNumberLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        saveAPaymentAccountButton.layer.borderColor = UIColor.accentGray.cgColor
        saveAPaymentAccountButton.layer.borderWidth = 2
        saveAPaymentAccountButton.layer.cornerRadius = 3
        saveAPaymentAccountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        saveAPaymentAccountButton.accessibilityLabel = NSLocalizedString("Save a payment account to One Touch Pay", comment: "")
        
        dueDateTooltip.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        dueAmountAndDateTooltip.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        saveAPaymentAccountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        bankCreditCardNumberLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        convenienceFeeLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        commericalBgeOtpVisaLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        automaticPaymentInfoButtonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        thankYouForSchedulingButtonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        oneTouchPayTCButtonLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        viewBillButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)
        
        billNotReadyLabel.font = OpenSans.regular.of(textStyle: .title1)
        billNotReadyLabel.setLineHeight(lineHeight: 26)
        billNotReadyLabel.textAlignment = .center
        errorLabel.font = OpenSans.regular.of(textStyle: .title1)
        errorLabel.setLineHeight(lineHeight: 26)
        errorLabel.textAlignment = .center
        if let errorLabelText = errorLabel.text {
            let localizedAccessibililtyText = NSLocalizedString("Bill OverView, %@", comment: "")
            errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, errorLabelText)
        }
        
        // Accessibility
        alertImageView.isAccessibilityElement = true
        alertImageView.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        bankCreditCardImageView.isAccessibilityElement = true
        
    }
    
    private func bindViewModel() {
        viewModel.paymentTracker.asDriver().drive(onNext: {
            if $0 {
                LoadingView.show(animated: true)
            } else {
                LoadingView.hide(animated: true)
            }
            })
            .disposed(by: bag)
        
        // Show/Hide Subviews
        Driver.combineLatest(viewModel.billNotReady, viewModel.showErrorState)
            .map { $0 && !$1 }
            .not()
            .drive(billNotReadyStack.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.showErrorState
            .filter { $0 }
            .drive(onNext: { _ in Analytics().logScreenView(AnalyticsPageView.CheckBalanceError.rawValue) })
            .disposed(by: bag)
        
        viewModel.showErrorState.not().drive(errorStack.rx.isHidden).disposed(by: bag)
        
        Driver.combineLatest(viewModel.billNotReady, viewModel.showErrorState)
            .map { $0 || $1 }
            .drive(infoStack.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.showAlertIcon.not().drive(alertContainer.rx.isHidden).disposed(by: bag)
        viewModel.showPaymentPendingIcon.not().drive(paymentPendingContainer.rx.isHidden).disposed(by: bag)
        viewModel.showBillPaidIcon.not().drive(paymentConfirmationContainer.rx.isHidden).disposed(by: bag)
        
        Driver.zip(viewModel.showAlertIcon, viewModel.showPaymentPendingIcon, viewModel.showBillPaidIcon)
            .map { $0 || $1 || $2 }
            .map { $0 ? 0: 32 }
            .drive(titleLabelTopConstraint.rx.constant)
            .disposed(by: bag)
        
        viewModel.showAmount.not().drive(amountLabel.rx.isHidden).disposed(by: bag)
        viewModel.showDueDate.not().drive(dueDateStack.rx.isHidden).disposed(by: bag)
        viewModel.showDueDateTooltip.not().drive(dueDateTooltip.rx.isHidden).disposed(by: bag)
        viewModel.showDueAmountAndDate.not().drive(dueAmountAndDateContainer.rx.isHidden).disposed(by: bag)
        dueAmountAndDateTooltip.isHidden = !viewModel.showDueAmountAndDateTooltip
        viewModel.showBankCreditButton.not().drive(bankCreditNumberContainer.rx.isHidden).disposed(by: bag)
        viewModel.showSaveAPaymentAccountButton.not().drive(saveAPaymentAccountContainer.rx.isHidden).disposed(by: bag)
        viewModel.showConvenienceFee.not().drive(convenienceFeeContainer.rx.isHidden).disposed(by: bag)
        viewModel.showMinimumPaymentAllowed.not().drive(minimumPaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showOneTouchPaySlider.not().drive(oneTouchSlider.rx.isHidden).disposed(by: bag)
        viewModel.showCommercialBgeOtpVisaLabel.not().drive(commercialBgeOtpVisaLabelContainer.rx.isHidden).disposed(by: bag)
        viewModel.showScheduledImageView.not().drive(scheduledImageContainer.rx.isHidden).disposed(by: bag)
        viewModel.showAutoPayIcon.not().drive(autoPayImageContainer.rx.isHidden).disposed(by: bag)
        viewModel.showAutomaticPaymentInfoButton.not().drive(automaticPaymentInfoButton.rx.isHidden).disposed(by: bag)
        viewModel.showScheduledPaymentInfoButton.not().drive(thankYouForSchedulingButton.rx.isHidden).disposed(by: bag)
        viewModel.showOneTouchPayTCButton.not().drive(oneTouchPayTCButton.rx.isHidden).disposed(by: bag)
        
        // Subview States
        viewModel.titleText.drive(titleLabel.rx.text).disposed(by: bag)
        viewModel.titleFont.drive(titleLabel.rx.font).disposed(by: bag)
        viewModel.amountFont.drive(amountLabel.rx.font).disposed(by: bag)
        viewModel.amountText.drive(amountLabel.rx.text).disposed(by: bag)
        viewModel.dueDateText.drive(dueDateLabel.rx.attributedText).disposed(by: bag)
        viewModel.dueAmountAndDateText.drive(dueAmountAndDateLabel.rx.text).disposed(by: bag)
        viewModel.bankCreditCardNumberText.drive(bankCreditCardNumberLabel.rx.text).disposed(by: bag)
        viewModel.bankCreditCardImage.drive(bankCreditCardImageView.rx.image).disposed(by: bag)
        viewModel.bankCreditCardButtonAccessibilityLabel.drive(bankCreditNumberButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.minPaymentAllowedText.drive(minimumPaymentLabel.rx.text).disposed(by: bag)
        viewModel.convenienceFeeText.drive(convenienceFeeLabel.rx.text).disposed(by: bag)
        viewModel.enableOneTouchSlider.drive(oneTouchSlider.rx.isEnabled).disposed(by: bag)
        viewModel.automaticPaymentInfoButtonText.drive(automaticPaymentInfoButtonLabel.rx.text).disposed(by: bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButtonLabel.rx.text).disposed(by: bag)
        viewModel.oneTouchPayTCButtonText.drive(oneTouchPayTCButtonLabel.rx.text).disposed(by: bag)
        viewModel.oneTouchPayTCButtonText.drive(oneTouchPayTCButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.enableOneTouchPayTCButton.drive(oneTouchPayTCButton.rx.isEnabled).disposed(by: bag)
        viewModel.oneTouchPayTCButtonTextColor.drive(oneTouchPayTCButtonLabel.rx.textColor).disposed(by: bag)
        
        // Actions
        oneTouchSlider.didFinishSwipe
            .withLatestFrom(Driver.combineLatest(self.viewModel.shouldShowWeekendWarning, self.viewModel.promptForCVV) { $0 || $1 })
            .filter(!)
            .map { _ in () }
            .do(onNext: { LoadingView.show(animated: true) })
            .drive(viewModel.submitOneTouchPay)
            .disposed(by: bag)
        
    }
    
    // Actions
    private(set) lazy var viewBillPressed: Driver<Void> = self.viewBillButton.rx.tap.asDriver()
        .do(onNext: {
            Analytics().logScreenView(AnalyticsPageView.ViewBillBillCard.rawValue)
        })
    private(set) lazy var oneTouchPayFinished: Observable<Void> = self.viewModel.oneTouchPayResult
        .do(onNext: { [weak self] _ in
            LoadingView.hide(animated: true)
            self?.oneTouchSlider.reset(animated: true)
        }).map { _ in () }
    
    // Modal View Controllers
    private lazy var paymentTACModal: Driver<UIViewController> = self.oneTouchPayTCButton.rx.touchUpInside.asObservable()
        .do(onNext: {
            Analytics().logScreenView(AnalyticsPageView.OneTouchTermsView.rawValue)
        })
        .map { [weak self] in self?.viewModel.paymentTACUrl }
        .unwrap()
        .map { (NSLocalizedString("Terms and Conditions", comment: ""), $0) }
        .map(WebViewController.init)
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var oneTouchSliderWeekendAlert: Driver<UIViewController> = self.oneTouchSlider.didFinishSwipe
        .withLatestFrom(self.viewModel.shouldShowWeekendWarning)
        .filter { $0 }
        .map { _ in
            let alertController = UIAlertController(title: NSLocalizedString("Weekend/Holiday Payment", comment: ""),
                                                    message: NSLocalizedString("You are making a payment on a weekend or holiday. Your payment will be scheduled for the next business day.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel){ [weak self] _ in
                self?.oneTouchSlider.reset(animated: true)
            })

            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
                LoadingView.show(animated: true)
                self?.viewModel.submitOneTouchPay.onNext()
            })
            return alertController
    }
    
    private lazy var oneTouchPayErrorAlert: Driver<UIViewController> = self.viewModel.oneTouchPayResult.errors()
        .map { error in
            let errMessage = error.localizedDescription
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString(errMessage, comment: ""), preferredStyle: .alert)
            
            // use regular expression to check the US phone number format: start with 1, then -, then 3 3 4 digits grouped together that separated by dash
            // e.g: 1-111-111-1111 is valid while 1-1111111111 and 111-111-1111 are not
            if let phoneRange = errMessage.range(of:"1-\\d{3}-\\d{3}-\\d{4}", options: .regularExpression) {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default, handler: {
                    action -> Void in
                    if let url = URL(string: "tel://\(errMessage.substring(with: phoneRange))"), UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }))
            } else {
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            }
            
            return alert
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var oneTouchSliderBGEAlert: Driver<UIViewController> = self.oneTouchSlider.didFinishSwipe
        .withLatestFrom(self.viewModel.promptForCVV)
        .asObservable()
        .filter { $0 }
        .flatMap { [weak self] _ -> Observable<UIViewController> in
            Observable<UIViewController>.create { [weak self] observer in
                guard let `self` = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }
                let alertController = UIAlertController(title: NSLocalizedString("Enter CVV2", comment: ""),
                                                        message: NSLocalizedString("Enter your 3-4 digit security code to complete One Touch Pay.", comment: ""),
                                                        preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] _ in
                    self?.cvvValidationDisposable?.dispose()
                    self?.oneTouchSlider.reset(animated: true)
                    observer.onCompleted()
                }
                
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                    self?.cvvValidationDisposable?.dispose()
                    
                    let textField = alertController.textFields![0]
                    let alertController2 = UIAlertController(title: "",
                                                             message: NSLocalizedString("If service is off and your balance was paid after 3pm, or on a Sunday or Holiday, your service will be restored the next business day.\n\nPlease ensure that circuit breakers are off. If applicable, remove any fuses prior to reconnection of the service, remove any flammable materials from heat sources, and unplug any sensitive electronics and large appliances.\n\nIf an electric smart meter is installed at the premise, BGE will first attempt to restore the service remotely. If both gas and electric services are off, or if BGE does not have access to the meters, we may contact you to make arrangements when an adult will be present.", comment: ""), preferredStyle: .alert)
                    alertController2.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { [weak self] _ in
                        self?.oneTouchSlider.reset(animated: true)
                        observer.onCompleted()
                    })
                    alertController2.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
                        LoadingView.show(animated: true)
                        self?.viewModel.submitOneTouchPay.onNext()
                        observer.onCompleted()
                    })
                    observer.onNext(alertController2)
                })
                
                alertController.addTextField { [weak self] in
                    $0.isSecureTextEntry = true
                    $0.keyboardType = .numberPad
                    $0.delegate = self
                }
                
                self.cvvValidationDisposable = self.viewModel.cvvIsValid.drive(okAction.rx.isEnabled)
                
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                
                observer.onNext(alertController)
                
                return Disposables.create()
                }
                .do(onCompleted: { [weak self] _ in
                    self?.viewModel.cvv2.value = nil
                })
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var tooltipModal: Driver<UIViewController> = Driver.merge(self.dueDateTooltip.rx.tap.asDriver(),
                                                                           self.dueAmountAndDateTooltip.rx.tap.asDriver())
        .map {
            let alertController = UIAlertController(title: NSLocalizedString("Your Due Date", comment: ""),
                                                    message: NSLocalizedString("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            return alertController
    }
    
    private(set) lazy var modalViewControllers: Driver<UIViewController> = Driver.merge(self.tooltipModal,
                                                                                        self.oneTouchSliderWeekendAlert,
                                                                                        self.paymentTACModal,
                                                                                        self.oneTouchPayErrorAlert,
                                                                                        self.oneTouchSliderBGEAlert)
    
    // Pushed View Controllers
    private lazy var walletViewController: Driver<UIViewController> = self.bankCreditNumberButton.rx.touchUpInside.asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            let vc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "wallet") as! WalletViewController
            vc.viewModel.accountDetail = accountDetail
            vc.shouldPopToRootOnSave = true
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var addOTPViewController: Driver<UIViewController> = self.saveAPaymentAccountButton.rx.touchUpInside.asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            let vc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "wallet") as! WalletViewController
            vc.viewModel.accountDetail = accountDetail
            vc.shouldPopToRootOnSave = true
            vc.shouldSetOneTouchPayByDefault = true
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var billingHistoryViewController: Driver<UIViewController> = self.thankYouForSchedulingButton.rx.touchUpInside.asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            let vc = UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "billingHistory") as! BillingHistoryViewController
            vc.accountDetail = accountDetail
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var autoPayViewController: Driver<UIViewController> = self.automaticPaymentInfoButton.rx.touchUpInside.asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            switch Environment.sharedInstance.opco {
            case .bge:
                let vc = UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "BGEAutoPay") as! BGEAutoPayViewController
                vc.accountDetail = accountDetail
                return vc
            case .peco, .comEd:
                let vc = UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "AutoPay") as! AutoPayViewController
                vc.accountDetail = accountDetail
                return vc
            }
            
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(self.walletViewController,
                                                                                         self.addOTPViewController,
                                                                                         self.billingHistoryViewController,
                                                                                         self.autoPayViewController)

}

extension HomeBillCardView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        
        if CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 4 {
            viewModel.cvv2.value = newString
            return true
        } else {
            return false
        }
    }
}

