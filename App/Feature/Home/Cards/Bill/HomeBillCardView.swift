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
import Lottie

class HomeBillCardView: UIView {
    
    var bag = DisposeBag()
    
    @IBOutlet private weak var clippingView: UIView!
    
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet private weak var infoStack: UIStackView!
    
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var headerAlertAnimationContainer: UIView! {
        didSet {
            headerAlertAnimationContainer.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        }
    }
    private var alertAnimation = AnimationView(name: "alert_icon")
    
    @IBOutlet private weak var topSpacerHeight: NSLayoutConstraint!
    
    @IBOutlet private weak var paymentPendingContainer: UIView!
    @IBOutlet private weak var paymentPendingImageView: UIImageView!
    
    @IBOutlet private weak var paymentConfirmationContainer: UIView!
    @IBOutlet private weak var paymentConfirmationImageView: UIImageView!
    
    @IBOutlet private weak var paymentDescriptionLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    
    @IBOutlet private weak var dueDateStack: UIStackView!
    @IBOutlet private weak var dueDateLabel: UILabel!
    @IBOutlet private weak var dueDateTooltip: UIButton!
    
    @IBOutlet private weak var reinstatementFeeContainer: UIView!
    @IBOutlet private weak var reinstatementFeeLabel: UILabel!
    
    @IBOutlet private weak var slideToPayConfirmationDetailContainer: UIView!
    @IBOutlet private weak var slideToPayConfirmationDetailLabel: UITextView!
    
    @IBOutlet private weak var walletItemInfoContainer: UIView!
    @IBOutlet private weak var walletItemInfoBox: UIView!
    @IBOutlet private weak var bankCreditNumberButton: ButtonControl!
    @IBOutlet private weak var bankCreditCardImageView: UIImageView!
    @IBOutlet private weak var bankCreditCardNumberLabel: UILabel!
    @IBOutlet private weak var bankCreditCardExpiredContainer: UIView!
    @IBOutlet private weak var expiredLabel: UILabel!
    @IBOutlet private weak var makeAPaymentButton: PrimaryButton!
    
    @IBOutlet private weak var saveAPaymentAccountButton: ButtonControl!
    @IBOutlet private weak var saveAPaymentAccountLabel: UILabel!
    @IBOutlet private weak var tutorialButton: UIButton!
    @IBOutlet private weak var saveAPaymentDescriptionLabel: UILabel!
    
    @IBOutlet private weak var minimumPaymentContainer: UIView!
    @IBOutlet private weak var minimumPaymentLabel: UILabel!
    
    @IBOutlet private weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet private weak var makePaymentContainer: UIView!
    
    @IBOutlet private weak var scheduledPaymentContainer: UIView!
    @IBOutlet private weak var scheduledPaymentBox: UIView!
    @IBOutlet private weak var scheduledImageView: UIImageView!
    @IBOutlet private weak var thankYouForSchedulingButton: UIButton!
    
    @IBOutlet private weak var autoPayContainer: UIView!
    @IBOutlet private weak var autoPayBox: UIView!
    @IBOutlet private weak var autoPayButton: ButtonControl!
    @IBOutlet private weak var autoPayImageView: UIImageView!
    @IBOutlet private weak var autoPayButtonLabel: UILabel!
    
    @IBOutlet private weak var oneTouchPayTCButton: ButtonControl!
    @IBOutlet weak var makeAPaymentSpacerView: UIView!
    
    @IBOutlet private weak var viewBillButton: UIButton!
    
    @IBOutlet private weak var billNotReadyStack: UIStackView!
    @IBOutlet private weak var billNotReadyImageView: UIImageView!
    @IBOutlet private weak var billNotReadyLabel: UILabel!
    @IBOutlet private weak var errorStack: UIStackView!
    @IBOutlet private weak var errorTitleLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var maintenanceModeView: UIView!
    @IBOutlet private weak var maintenanceModeLabel: UILabel!
    
    let shouldPushWallet = PublishSubject<Void>()
    
    private var viewModel: HomeBillCardViewModel! {
        didSet {
            bag = DisposeBag() // Clear all pre-existing bindings
            bindViewModel()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        styleViews()
    }
    
    func superviewDidLayoutSubviews() {
        // Needed due to weird lifetime events... thanks RX Swift
        saveAPaymentAccountButton.layer.cornerRadius = saveAPaymentAccountButton.bounds.height / 2
    }
    
    
    static func create(withViewModel viewModel: HomeBillCardViewModel) -> HomeBillCardView {
        let view = Bundle.main.loadViewFromNib() as HomeBillCardView
        view.viewModel = viewModel
        return view
    }
    
    func resetAnimation() {
        alertAnimation.removeFromSuperview()
        alertAnimation = AnimationView(name: "alert_icon")
        alertAnimation.translatesAutoresizingMaskIntoConstraints = false
        alertAnimation.frame = headerAlertAnimationContainer.bounds
        alertAnimation.contentMode = .scaleAspectFit
        alertAnimation.backgroundBehavior = .pauseAndRestore
        headerAlertAnimationContainer.addSubview(alertAnimation)
        alertAnimation.centerXAnchor.constraint(equalTo: headerAlertAnimationContainer.centerXAnchor).isActive = true
        alertAnimation.centerYAnchor.constraint(equalTo: headerAlertAnimationContainer.centerYAnchor).isActive = true
        alertAnimation.play()
    }
    
    private func styleViews() {
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 10
        clippingView.layer.cornerRadius = 10
        
        headerView.layer.borderColor = UIColor.accentGray.cgColor
        headerView.layer.borderWidth = 1
        
        headerLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        
        reinstatementFeeLabel.textColor = .deepGray
        reinstatementFeeLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        bankCreditNumberButton.layer.borderWidth = 1
        bankCreditNumberButton.layer.cornerRadius = 15
        
        bankCreditCardNumberLabel.textColor = .deepGray
        bankCreditCardNumberLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        
        expiredLabel.textColor = .deepGray
        expiredLabel.font = SystemFont.semibold.of(textStyle: .caption1)
        
        saveAPaymentAccountButton.layer.borderWidth = 1
        saveAPaymentAccountButton.layer.borderColor = UIColor.accentGray.cgColor
        saveAPaymentAccountLabel.font = OpenSans.semibold.of(textStyle: .caption1)
        saveAPaymentAccountButton.accessibilityLabel = NSLocalizedString("Set a default payment method", comment: "")
        
        tutorialButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        paymentDescriptionLabel.textColor = .deepGray
        paymentDescriptionLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        minimumPaymentLabel.textColor = .deepGray
        minimumPaymentLabel.font = SystemFont.semibold.of(textStyle: .footnote)
        
        viewModel.amountColor.drive(amountLabel.rx.textColor).disposed(by: bag)
        amountLabel.font = OpenSans.semibold.of(textStyle: .largeTitle)
        
        dueDateLabel.font = SystemFont.regular.of(textStyle: .caption1)
        dueDateTooltip.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        slideToPayConfirmationDetailLabel.textColor = .deepGray
        slideToPayConfirmationDetailLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        bankCreditCardNumberLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        scheduledPaymentBox.layer.cornerRadius = 6
        scheduledPaymentBox.layer.borderColor = UIColor.accentGray.cgColor
        scheduledPaymentBox.layer.borderWidth = 1
        thankYouForSchedulingButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
        thankYouForSchedulingButton.titleLabel?.numberOfLines = 0
        
        autoPayBox.layer.cornerRadius = 6
        autoPayBox.layer.borderColor = UIColor.accentGray.cgColor
        autoPayBox.layer.borderWidth = 1
        autoPayButtonLabel.textColor = .actionBlue
        autoPayButtonLabel.font = SystemFont.semibold.of(textStyle: .subheadline)
        
        viewBillButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        // Bill Not Ready
        billNotReadyLabel.textColor = .deepGray
        billNotReadyLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        billNotReadyLabel.textAlignment = .center
        
        // Error State
        errorTitleLabel.textColor = .deepGray
        errorTitleLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        errorLabel.textColor = .deepGray
        errorLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        errorLabel.textAlignment = .center
        if let errorLabelText = errorLabel.text {
            let localizedAccessibililtyText = NSLocalizedString("Bill OverView, %@", comment: "")
            errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, errorLabelText)
        }
        
        // Maintenance Mode
        maintenanceModeLabel.textColor = .deepGray
        maintenanceModeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        // Accessibility
        alertAnimation.isAccessibilityElement = true
        alertAnimation.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        bankCreditCardImageView.isAccessibilityElement = true
        bankCreditCardImageView.tintColor = .primaryColor
        resetAnimation()
        
        if StormModeStatus.shared.isOn {
            styleStormMode()
        }
    }
    
    private func styleStormMode() {
        backgroundColor = .stormModeGray
        clippingView.backgroundColor = .stormModeGray
        loadingIndicator.isStormMode = true
        headerView.backgroundColor = .stormModeLightGray
        headerLabel.textColor = .white
        paymentDescriptionLabel.textColor = .white
        amountLabel.textColor = .white
        reinstatementFeeLabel.textColor = .white
        slideToPayConfirmationDetailLabel.textColor = .white
        bankCreditCardImageView.tintColor = .white
        bankCreditCardNumberLabel.textColor = .white
        minimumPaymentLabel.textColor = .white
        convenienceFeeLabel.textColor = .white
        billNotReadyLabel.textColor = .white
        errorLabel.textColor = .white
        maintenanceModeLabel.textColor = .white
        
        dueDateTooltip.setImage(#imageLiteral(resourceName: "ic_tooltip_white.pdf"), for: .normal)
        walletItemInfoBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        bankCreditNumberButton.normalBackgroundColor = UIColor.white.withAlphaComponent(0.1)
        bankCreditNumberButton.backgroundColorOnPress = UIColor.white.withAlphaComponent(0.06)
        bankCreditNumberButton.shouldFadeSubviewsOnPress = true
        
        expiredLabel.textColor = .white
        saveAPaymentAccountButton.normalBackgroundColor = UIColor.white.withAlphaComponent(0.1)
        saveAPaymentAccountButton.backgroundColorOnPress = UIColor.white.withAlphaComponent(0.06)
        saveAPaymentAccountButton.shouldFadeSubviewsOnPress = true
        saveAPaymentAccountLabel.textColor = .white
        tutorialButton.setImage(#imageLiteral(resourceName: "ic_tooltip_white.pdf"), for: .normal)
        
        saveAPaymentDescriptionLabel.textColor = .white
        
        scheduledPaymentBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        thankYouForSchedulingButton.setTitleColor(.white, for: .normal)
        scheduledImageView.image = #imageLiteral(resourceName: "ic_scheduled_sm.pdf")
        
        autoPayBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        autoPayButtonLabel.textColor = .white
        autoPayImageView.image = #imageLiteral(resourceName: "ic_autopay_sm.pdf")
        
        billNotReadyImageView.image = #imageLiteral(resourceName: "ic_home_billnotready_sm.pdf")
        
        errorTitleLabel.textColor = .white
    }
    
    private func bindViewModel() {
        viewBillButton.isHidden = !viewModel.showViewBillButton
        
        viewModel.paymentTracker.asDriver().drive(onNext: {
            if $0 {
                LoadingView.show(animated: true)
            } else {
                LoadingView.hide(animated: true)
            }
        })
        .disposed(by: bag)
        
        viewModel.showLoadingState
            .drive(onNext: { _ in UIAccessibility.post(notification: .screenChanged, argument: nil) })
            .disposed(by: bag)
        
        // Show/Hide Subviews
        viewModel.showLoadingState.drive(contentStack.rx.isHidden).disposed(by: bag)
        viewModel.showLoadingState.not().drive(loadingView.rx.isHidden).disposed(by: bag)
        
        Driver.combineLatest(viewModel.billNotReady.startWith(false), viewModel.showErrorState)
            .map { $0 && !$1 }
            .not()
            .drive(billNotReadyStack.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.showErrorState
            .filter { $0 }
            .drive(onNext: { _ in GoogleAnalytics.log(event: .checkBalanceError) })
            .disposed(by: bag)
        
        viewModel.showErrorState.not().drive(errorStack.rx.isHidden).disposed(by: bag)
        
        viewModel.showMaintenanceModeState.not().drive(maintenanceModeView.rx.isHidden).disposed(by: bag)
        
        Driver.combineLatest(viewModel.billNotReady.startWith(false), viewModel.showErrorState, viewModel.showMaintenanceModeState)
            .map { $0 || $1 || $2 }
            .startWith(false)
            .drive(infoStack.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.showHeaderView.map { CGFloat($0 ? 20 : 30) }.drive(topSpacerHeight.rx.constant).disposed(by: bag)
        viewModel.showHeaderView.not().drive(headerView.rx.isHidden).disposed(by: bag)
        viewModel.showAlertAnimation.not().drive(headerAlertAnimationContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.showPaymentPendingIcon.not().drive(paymentPendingContainer.rx.isHidden).disposed(by: bag)
        viewModel.showBillPaidIcon.not().drive(paymentConfirmationContainer.rx.isHidden).disposed(by: bag)
        viewModel.showSlideToPayConfirmationDetailLabel.not().drive(slideToPayConfirmationDetailContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.showPaymentDescription.not().drive(paymentDescriptionLabel.rx.isHidden).disposed(by: bag)
        viewModel.showAmount.not().drive(amountLabel.rx.isHidden).disposed(by: bag)
        viewModel.showDueDate.not().drive(dueDateStack.rx.isHidden).disposed(by: bag)
        dueDateTooltip.isHidden = !viewModel.showDueDateTooltip
        viewModel.showReinstatementFeeText.not().drive(reinstatementFeeContainer.rx.isHidden).disposed(by: bag)
        viewModel.showWalletItemInfo.not().drive(walletItemInfoContainer.rx.isHidden).disposed(by: bag)
        viewModel.showBankCreditNumberButton.not().drive(bankCreditNumberButton.rx.isHidden).disposed(by: bag)
        viewModel.bankCreditButtonBorderWidth.drive(bankCreditNumberButton.rx.borderWidth).disposed(by: bag)
        viewModel.showBankCreditExpiredLabel.not().drive(bankCreditCardExpiredContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.showBankCreditExpiredLabel.asObservable().subscribe(onNext: { [weak self] show in
            if show {
                self?.bankCreditNumberButton.layer.borderColor = UIColor.errorRed.cgColor
            } else {
                self?.bankCreditNumberButton.layer.borderColor = UIColor.accentGray.cgColor
            }
        }).disposed(by: bag)
        
        viewModel.showConvenienceFee.not().drive(convenienceFeeLabel.rx.isHidden).disposed(by: bag)
        viewModel.showMinMaxPaymentAllowed.not().drive(minimumPaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showScheduledPayment.not().drive(scheduledPaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showAutoPay.not().drive(autoPayContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.showSaveAPaymentAccountButton.not().drive(saveAPaymentAccountButton.rx.isHidden).disposed(by: bag)
        viewModel.showSaveAPaymentAccountButton.not().drive(tutorialButton.rx.isHidden).disposed(by: bag)
        viewModel.showSaveAPaymentAccountButton.not().drive(saveAPaymentDescriptionLabel.rx.isHidden).disposed(by: bag)
        viewModel.showSaveAPaymentAccountButton.drive(makeAPaymentSpacerView.rx.isHidden).disposed(by: bag)
        
        // Subview States
        viewModel.paymentDescriptionText.drive(paymentDescriptionLabel.rx.attributedText).disposed(by: bag)
        viewModel.titleFont.drive(paymentDescriptionLabel.rx.font).disposed(by: bag)
        viewModel.resetAlertAnimation.drive(onNext: { [weak self] in self?.resetAnimation() }).disposed(by: bag)
        viewModel.headerText.drive(headerLabel.rx.attributedText).disposed(by: bag)
        viewModel.headerA11yText.drive(headerLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.amountFont.drive(amountLabel.rx.font).disposed(by: bag)
        viewModel.amountText.drive(amountLabel.rx.text).disposed(by: bag)
        
        // `.delay(0.02)` fixes a weird bug where the label's font
        // is set to regular instead of semibold while the view is still hidden.
        // This is not an ideal fix, hoping to find a better one later.
        viewModel.dueDateText.delay(.milliseconds(20)).drive(dueDateLabel.rx.attributedText).disposed(by: bag)
        viewModel.reinstatementFeeText.drive(reinstatementFeeLabel.rx.text).disposed(by: bag)
        viewModel.bankCreditCardNumberText.drive(bankCreditCardNumberLabel.rx.text).disposed(by: bag)
        viewModel.bankCreditCardImage.drive(bankCreditCardImageView.rx.image).disposed(by: bag)
        viewModel.bankCreditCardButtonAccessibilityLabel.drive(bankCreditNumberButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.minMaxPaymentAllowedText.drive(minimumPaymentLabel.rx.text).disposed(by: bag)
        viewModel.convenienceFeeText.drive(convenienceFeeLabel.rx.text).disposed(by: bag)
        viewModel.showMakePaymentButton.not().drive(makePaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showMakePaymentButton.not().drive(makeAPaymentSpacerView.rx.isHidden).disposed(by: bag)
        
        viewModel.automaticPaymentInfoButtonText.drive(autoPayButtonLabel.rx.text).disposed(by: bag)
        viewModel.automaticPaymentInfoButtonText.drive(autoPayButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButton.rx.title(for: .normal)).disposed(by: bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.slideToPayConfirmationDetailText.drive(slideToPayConfirmationDetailLabel.rx.text).disposed(by: bag)
        
    }
    
    private(set) lazy var viewBillPressed: Driver<Void> = self.viewBillButton.rx.touchUpInside.asDriver()
        .do(onNext: {
            FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .bill_cta)])
            GoogleAnalytics.log(event: .viewBillBillCard)
        })
    
    private(set) lazy var oneTouchPayFinished: Observable<Void> = self.viewModel.oneTouchPayResult
        .do(onNext: { [weak self] _ in
            LoadingView.hide(animated: true)
            FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .bill_slide_to_pay)])
        })
        .mapTo(())
    
    // Modal View Controllers
    private lazy var paymentTACModal: Driver<UIViewController> = self.oneTouchPayTCButton.rx.touchUpInside.asObservable()
        .do(onNext: {
            FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .bill_terms)])
            GoogleAnalytics.log(event: .oneTouchTermsView)
        })
        .map { [weak self] in self?.viewModel.paymentTACUrl }
        .unwrap()
        .map { (LargeTitleNavigationController(rootViewController: WebViewController.init(title: NSLocalizedString("Terms and Conditions", comment: ""), url: $0))) }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var oneTouchPayErrorAlert: Driver<UIViewController> = self.viewModel.oneTouchPayResult.errors()
        .withLatestFrom(viewModel.walletItem) {
            return ($0, $1)
        }
        .map { [weak self] error, walletItem in
            return UIAlertController.paymentusErrorAlertController(
                forError: error as? NetworkingError ?? .unknown,
                walletItem: walletItem!,
                customMessageForSessionExpired: NSLocalizedString("Please try to Slide to Pay again.", comment: ""),
                callHandler: { _ in
                    if let phone = self?.viewModel.errorPhoneNumber {
                        UIApplication.shared.openPhoneNumberIfCan(phone)
                    }
                }
            )
        }
        .asDriver(onErrorDriveWith: .empty())
    
    func oneTouchBGELegalAlert(observer: AnyObserver<UIViewController>) -> UIAlertController {
        let alertController2 = UIAlertController(title: "",
                                                 message: NSLocalizedString("If service is off and your balance was paid after 3pm, or on a Sunday or Holiday, your service will be restored the next business day.\n\nPlease ensure that circuit breakers are off. If applicable, remove any fuses prior to reconnection of the service, remove any flammable materials from heat sources, and unplug any sensitive electronics and large appliances.\n\nIf an electric smart meter is installed at the premise, BGE will first attempt to restore the service remotely. If both gas and electric services are off, or if BGE does not have access to the meters, we may contact you to make arrangements when an adult will be present.", comment: ""), preferredStyle: .alert)
        alertController2.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
            observer.onCompleted()
        })
        alertController2.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
            LoadingView.show(animated: true)
            self?.viewModel.submitOneTouchPay.onNext(())
            observer.onCompleted()
        })
        return alertController2
    }
    
    private lazy var tooltipModal: Driver<UIViewController> = self.dueDateTooltip.rx.tap.asDriver()
        .map {
            let alertController = UIAlertController(title: NSLocalizedString("Your Due Date", comment: ""),
                                                    message: NSLocalizedString("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            return alertController
        }
    
    private(set) lazy var tutorialViewController: Driver<UIViewController> = Driver
        .merge(tutorialButton.rx.tap.asDriver())
        .withLatestFrom(Driver.combineLatest(self.viewModel.showSaveAPaymentAccountButton, self.viewModel.enableOneTouchSlider))
        .filter { $0 && !$1 }
        .mapTo(())
        .map { [weak self] in
            let vc = SetDefaultPaymentMethodTutorialViewController()
            vc.shouldPushWallet = self?.shouldPushWallet
            return vc
        }
    
    private lazy var bgeasyViewController: Driver<UIViewController> = self.autoPayButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .filter { $0.isBGEasy }
        .map { _ in UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "BGEasy") }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var autoPayAlert: Driver<UIViewController> = autoPayButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .filter { !$0.isBGEasy && StormModeStatus.shared.isOn }
        .map { accountDetail in
            let alert = UIAlertController(title: NSLocalizedString("AutoPay Settings Unavailable", comment: ""),
                                          message: NSLocalizedString("AutoPay settings are not available in Storm Mode. Sorry for the inconvenience.", comment: ""),
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            return alert
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var modalViewControllers: Driver<UIViewController> = Driver
        .merge(tooltipModal,
               paymentTACModal,
               oneTouchPayErrorAlert,
               tutorialViewController,
               bgeasyViewController,
               autoPayAlert,
               makeAPaymentReviewViewController)
    
    // Pushed View Controllers
    private lazy var walletViewController: Driver<UIViewController> =
        Observable.merge(bankCreditNumberButton.rx.touchUpInside.asObservable(), shouldPushWallet.asObservable())
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            let vc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "wallet") as! WalletViewController
            vc.viewModel.accountDetail = accountDetail
            vc.shouldPopToRootOnSave = true
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var addOTPViewController: Driver<UIViewController> = saveAPaymentAccountButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            FirebaseUtility.logEvent(.home, parameters: [EventParameter(parameterName: .action, value: .bill_choose_default_payment_method)])
            let vc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "wallet") as! WalletViewController
            vc.viewModel.accountDetail = accountDetail
            vc.shouldPopToRootOnSave = true
            vc.shouldSetOneTouchPayByDefault = true
            GoogleAnalytics.log(event: .oneTouchEnabledBillCard)
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var billingHistoryViewController: Driver<UIViewController> = thankYouForSchedulingButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            let vc = UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "billingHistory") as! BillingHistoryViewController
            vc.viewModel.accountDetail = accountDetail
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var autoPayViewController: Driver<UIViewController> = autoPayButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .filter { !$0.isBGEasy && !StormModeStatus.shared.isOn }
        .map { accountDetail in
            switch Environment.shared.opco {
            case .bge:
                let vc = UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "BGEAutoPay") as! BGEAutoPayViewController
                vc.accountDetail = accountDetail
                return vc
            case .peco, .comEd, .pepco, .ace, .delmarva:
                let vc = UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "AutoPay") as! AutoPayViewController
                vc.accountDetail = accountDetail
                return vc
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var makeAPaymentReviewViewController: Driver<UIViewController> = makeAPaymentButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { [weak self] accountDetail in
            let vc = UIStoryboard(name: "Payment", bundle: nil).instantiateInitialViewController() as! MakePaymentViewController
            vc.accountDetail = accountDetail
            return vc
            #warning("re-add new payment flow logic for dec release")
        }.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(walletViewController,
                                                                                         addOTPViewController,
                                                                                         billingHistoryViewController,
                                                                                         autoPayViewController)
}
