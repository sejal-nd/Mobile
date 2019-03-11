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
    private var alertAnimation = LOTAnimationView(name: "alert_icon")
    
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
    
    @IBOutlet private weak var saveAPaymentAccountButton: ButtonControl!
    @IBOutlet private weak var saveAPaymentAccountLabel: UILabel!
    
    @IBOutlet private weak var minimumPaymentContainer: UIView!
    @IBOutlet private weak var minimumPaymentLabel: UILabel!
    
    @IBOutlet private weak var convenienceFeeLabel: UILabel!
    
    @IBOutlet private weak var a11yTutorialButtonContainer: UIView!
    @IBOutlet private weak var a11yTutorialButton: UIButton!
    
    @IBOutlet private weak var oneTouchSliderContainer: UIView!
    @IBOutlet private weak var oneTouchSlider: OneTouchSlider!
    @IBOutlet private weak var commercialBgeOtpVisaLabelContainer: UIView!
    @IBOutlet private weak var commericalBgeOtpVisaLabel: UILabel!
    
    @IBOutlet private weak var scheduledPaymentContainer: UIView!
    @IBOutlet private weak var scheduledPaymentBox: UIView!
    @IBOutlet private weak var scheduledImageView: UIImageView!
    @IBOutlet private weak var thankYouForSchedulingButton: UIButton!
    
    @IBOutlet private weak var autoPayContainer: UIView!
    @IBOutlet private weak var autoPayBox: UIView!
    @IBOutlet private weak var autoPayImageView: UIImageView!
    @IBOutlet private weak var autoPayButton: UIButton!
    
    @IBOutlet private weak var oneTouchPayTCButton: ButtonControl!
    @IBOutlet private weak var oneTouchPayTCButtonLabel: UILabel!
    
    @IBOutlet private weak var viewBillButton: ButtonControl!
    @IBOutlet private weak var viewBillButtonLabel: UILabel!
    
    @IBOutlet private weak var billNotReadyStack: UIStackView!
    @IBOutlet private weak var billNotReadyImageView: UIImageView!
    @IBOutlet private weak var billNotReadyLabel: UILabel!
    @IBOutlet private weak var errorStack: UIStackView!
    @IBOutlet private weak var errorTitleLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var maintenanceModeView: UIView!
    @IBOutlet private weak var maintenanceModeLabel: UILabel!
    
    private let tutorialTap = UITapGestureRecognizer()
    private let tutorialSwipe = UISwipeGestureRecognizer()
    
    private var viewModel: HomeBillCardViewModel! {
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
    
    func resetAnimation() {
        alertAnimation.removeFromSuperview()
        alertAnimation = LOTAnimationView(name: "alert_icon")
        alertAnimation.translatesAutoresizingMaskIntoConstraints = false
        alertAnimation.frame = headerAlertAnimationContainer.bounds
        alertAnimation.contentMode = .scaleAspectFit
        headerAlertAnimationContainer.addSubview(alertAnimation)
        alertAnimation.centerXAnchor.constraint(equalTo: headerAlertAnimationContainer.centerXAnchor).isActive = true
        alertAnimation.centerYAnchor.constraint(equalTo: headerAlertAnimationContainer.centerYAnchor).isActive = true
        alertAnimation.play()
    }
    
    private func styleViews() {
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 13)
        layer.cornerRadius = 10
        clippingView.layer.cornerRadius = 10
        
        headerView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 2)
        
        reinstatementFeeLabel.font = OpenSans.regular.of(textStyle: .footnote)
        reinstatementFeeLabel.setLineHeight(lineHeight: 16)
        
        bankCreditNumberButton.layer.borderColor = UIColor.errorRed.cgColor
        bankCreditNumberButton.layer.cornerRadius = 3
        bankCreditNumberButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 2)
        bankCreditCardNumberLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        saveAPaymentAccountButton.layer.cornerRadius = 3
        saveAPaymentAccountButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 2)
        saveAPaymentAccountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        saveAPaymentAccountButton.accessibilityLabel = NSLocalizedString("Set a default payment method", comment: "")
        
        a11yTutorialButton.setTitleColor(StormModeStatus.shared.isOn ? .white : .actionBlue, for: .normal)
        a11yTutorialButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .title1)
        a11yTutorialButton.titleLabel?.text = NSLocalizedString("View Tutorial", comment: "")
        
        dueDateLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        dueDateTooltip.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        //TODO: Remove this check when BGE switches to Paymentus
        switch Environment.shared.opco {
        case .bge:
            slideToPayConfirmationDetailLabel.isSelectable = false
            slideToPayConfirmationDetailLabel.font = OpenSans.regular.of(textStyle: .footnote)
        case .comEd, .peco:
            slideToPayConfirmationDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        }
        
        bankCreditCardNumberLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        convenienceFeeLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        commericalBgeOtpVisaLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        walletItemInfoBox.layer.cornerRadius = 6
        walletItemInfoBox.backgroundColor = .softGray
        
        scheduledPaymentBox.layer.cornerRadius = 6
        thankYouForSchedulingButton.titleLabel?.font = OpenSans.semibold.of(textStyle: .subheadline)
        thankYouForSchedulingButton.titleLabel?.numberOfLines = 0
        
        autoPayBox.layer.cornerRadius = 6
        autoPayButton.titleLabel?.font = OpenSans.semibold.of(textStyle: .subheadline)
        autoPayButton.titleLabel?.numberOfLines = 0
        
        oneTouchPayTCButtonLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        viewBillButtonLabel.font = SystemFont.semibold.of(textStyle: .title1)
        viewBillButton.accessibilityLabel = NSLocalizedString("View Bill Details", comment: "")
        
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
        
        errorTitleLabel.textColor = .blackText
        errorTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        maintenanceModeLabel.font = OpenSans.regular.of(textStyle: .title1)
        
        // Accessibility
        alertAnimation.isAccessibilityElement = true
        alertAnimation.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        bankCreditCardImageView.isAccessibilityElement = true
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
        bankCreditCardNumberLabel.textColor = .white
        minimumPaymentLabel.textColor = .white
        convenienceFeeLabel.textColor = .white
        commericalBgeOtpVisaLabel.textColor = .white
        oneTouchPayTCButtonLabel.textColor = .white
        billNotReadyLabel.textColor = .white
        errorLabel.textColor = .white
        maintenanceModeLabel.textColor = .white
        
        dueDateTooltip.setImage(#imageLiteral(resourceName: "ic_question_white.pdf"), for: .normal)
        walletItemInfoBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        bankCreditNumberButton.normalBackgroundColor = UIColor.white.withAlphaComponent(0.1)
        bankCreditNumberButton.backgroundColorOnPress = UIColor.white.withAlphaComponent(0.06)
        bankCreditNumberButton.shouldFadeSubviewsOnPress = true
        bankCreditNumberButton.layer.borderColor = UIColor.red.cgColor
        expiredLabel.textColor = .white
        saveAPaymentAccountButton.normalBackgroundColor = UIColor.white.withAlphaComponent(0.1)
        saveAPaymentAccountButton.backgroundColorOnPress = UIColor.white.withAlphaComponent(0.06)
        saveAPaymentAccountButton.shouldFadeSubviewsOnPress = true
        saveAPaymentAccountLabel.textColor = .white
        
        scheduledPaymentBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        thankYouForSchedulingButton.setTitleColor(.white, for: .normal)
        scheduledImageView.image = #imageLiteral(resourceName: "ic_scheduled_sm.pdf")
        
        autoPayBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        autoPayButton.setTitleColor(.white, for: .normal)
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
            .drive(onNext: { _ in Analytics.log(event: .checkBalanceError) })
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
        viewModel.showSaveAPaymentAccountButton.not().drive(saveAPaymentAccountButton.rx.isHidden).disposed(by: bag)
        viewModel.showSaveAPaymentAccountButton.asObservable().subscribe(onNext: { [weak self] show in
            let a11yEnabled = UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
            self?.a11yTutorialButtonContainer.isHidden = !show || !a11yEnabled
        }).disposed(by: bag)
        viewModel.showConvenienceFee.not().drive(convenienceFeeLabel.rx.isHidden).disposed(by: bag)
        viewModel.showMinMaxPaymentAllowed.not().drive(minimumPaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showOneTouchPaySlider.not().drive(oneTouchSliderContainer.rx.isHidden).disposed(by: bag)
        viewModel.showCommercialBgeOtpVisaLabel.not().drive(commercialBgeOtpVisaLabelContainer.rx.isHidden).disposed(by: bag)
        viewModel.showScheduledPayment.not().drive(scheduledPaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showAutoPay.not().drive(autoPayContainer.rx.isHidden).disposed(by: bag)
        viewModel.showOneTouchPayTCButton.not().drive(oneTouchPayTCButton.rx.isHidden).disposed(by: bag)
        
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
        viewModel.dueDateText.delay(0.02).drive(dueDateLabel.rx.attributedText).disposed(by: bag)
        viewModel.reinstatementFeeText.drive(reinstatementFeeLabel.rx.text).disposed(by: bag)
        viewModel.bankCreditCardNumberText.drive(bankCreditCardNumberLabel.rx.text).disposed(by: bag)
        viewModel.bankCreditCardImage.drive(bankCreditCardImageView.rx.image).disposed(by: bag)
        viewModel.bankCreditCardButtonAccessibilityLabel.drive(bankCreditNumberButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.minMaxPaymentAllowedText.drive(minimumPaymentLabel.rx.text).disposed(by: bag)
        viewModel.convenienceFeeText.drive(convenienceFeeLabel.rx.text).disposed(by: bag)
        viewModel.enableOneTouchSlider.drive(oneTouchSlider.rx.isEnabled).disposed(by: bag)
        viewModel.automaticPaymentInfoButtonText.drive(autoPayButton.rx.title(for: .normal)).disposed(by: bag)
        viewModel.automaticPaymentInfoButtonText.drive(autoPayButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButton.rx.title(for: .normal)).disposed(by: bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.oneTouchPayTCButtonText.drive(oneTouchPayTCButtonLabel.rx.text).disposed(by: bag)
        viewModel.oneTouchPayTCButtonText.drive(oneTouchPayTCButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.oneTouchPayTCButtonText.drive(oneTouchPayTCButtonLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.enableOneTouchPayTCButton.drive(oneTouchPayTCButton.rx.isUserInteractionEnabled).disposed(by: bag)
        viewModel.oneTouchPayTCButtonTextColor.drive(oneTouchPayTCButtonLabel.rx.textColor).disposed(by: bag)
        viewModel.enableOneTouchPayTCButton.drive(oneTouchPayTCButton.rx.isAccessibilityElement).disposed(by: bag)
        viewModel.enableOneTouchPayTCButton.not().drive(oneTouchPayTCButtonLabel.rx.isAccessibilityElement).disposed(by: bag)
        viewModel.slideToPayConfirmationDetailText.drive(slideToPayConfirmationDetailLabel.rx.text).disposed(by: bag)
        
        // Actions
        oneTouchSlider.didFinishSwipe
            .withLatestFrom(viewModel.promptForCVV)
            .filter(!)
            .map(to: ())
            .do(onNext: { LoadingView.show(animated: true) })
            .drive(viewModel.submitOneTouchPay)
            .disposed(by: bag)
        
        oneTouchSliderContainer.removeGestureRecognizer(tutorialTap)
        oneTouchSliderContainer.removeGestureRecognizer(tutorialSwipe)
        oneTouchSliderContainer.addGestureRecognizer(tutorialTap)
        oneTouchSliderContainer.addGestureRecognizer(tutorialSwipe)
        
        Observable.merge(NotificationCenter.default.rx.notification(UIAccessibility.switchControlStatusDidChangeNotification, object: nil),
                         NotificationCenter.default.rx.notification(Notification.Name(rawValue: UIAccessibilityVoiceOverStatusChanged), object: nil))
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.showSaveAPaymentAccountButton.asObservable().single().subscribe(onNext: { show in
                    let a11yEnabled = UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
                    self.a11yTutorialButtonContainer.isHidden = !show || !a11yEnabled
                    UIAccessibility.post(notification: .screenChanged, argument: self)
                }).disposed(by: self.bag)
            })
            .disposed(by: bag)
    }
    
    private(set) lazy var viewBillPressed: Driver<Void> = self.viewBillButton.rx.touchUpInside.asDriver()
        .do(onNext: { Analytics.log(event: .viewBillBillCard) })
    
    private(set) lazy var oneTouchPayFinished: Observable<Void> = self.viewModel.oneTouchPayResult
        .do(onNext: { [weak self] _ in
            LoadingView.hide(animated: true)
            self?.oneTouchSlider.reset(animated: true)
        })
        .mapTo(())
    
    // Modal View Controllers
    private lazy var paymentTACModal: Driver<UIViewController> = self.oneTouchPayTCButton.rx.touchUpInside.asObservable()
        .do(onNext: {
            Analytics.log(event: .oneTouchTermsView)
        })
        .map { [weak self] in self?.viewModel.paymentTACUrl }
        .unwrap()
        .map { (NSLocalizedString("Terms and Conditions", comment: ""), $0) }
        .map(WebViewController.init)
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var oneTouchPayErrorAlert: Driver<UIViewController> = self.viewModel.oneTouchPayResult.errors()
        .withLatestFrom(self.viewModel.walletItem) {
            return ($0, $1)
        }
        .map { [weak self] error, walletItem in
            if Environment.shared.opco == .bge {
                let errMessage = error.localizedDescription
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString(errMessage, comment: ""), preferredStyle: .alert)
                
                // use regular expression to check the US phone number format: start with 1, then -, then 3 3 4 digits grouped together that separated by dash
                // e.g: 1-111-111-1111 is valid while 1-1111111111 and 111-111-1111 are not
                if let phoneRange = errMessage.range(of:"1-\\d{3}-\\d{3}-\\d{4}", options: .regularExpression) {
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: nil))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Contact Us", comment: ""), style: .default, handler: {
                        action -> Void in
                        UIApplication.shared.openPhoneNumberIfCan(String(errMessage[phoneRange]))
                    }))
                } else {
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                }
                
                return alert
            } else {
                let err = error as! ServiceError
                return UIAlertController.paymentusErrorAlertController(
                    forError: err,
                    walletItem: walletItem!,
                    customMessage: NSLocalizedString("Please try to Slide to Pay again.", comment: ""),
                    callHandler: { _ in
                        if let phone = self?.viewModel.errorPhoneNumber {
                            UIApplication.shared.openPhoneNumberIfCan(phone)
                        }
                }
                )
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    func oneTouchBGELegalAlert(observer: AnyObserver<UIViewController>) -> UIAlertController {
        let alertController2 = UIAlertController(title: "",
                                                 message: NSLocalizedString("If service is off and your balance was paid after 3pm, or on a Sunday or Holiday, your service will be restored the next business day.\n\nPlease ensure that circuit breakers are off. If applicable, remove any fuses prior to reconnection of the service, remove any flammable materials from heat sources, and unplug any sensitive electronics and large appliances.\n\nIf an electric smart meter is installed at the premise, BGE will first attempt to restore the service remotely. If both gas and electric services are off, or if BGE does not have access to the meters, we may contact you to make arrangements when an adult will be present.", comment: ""), preferredStyle: .alert)
        alertController2.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { [weak self] _ in
            self?.oneTouchSlider.reset(animated: true)
            observer.onCompleted()
        })
        alertController2.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
            LoadingView.show(animated: true)
            self?.viewModel.submitOneTouchPay.onNext(())
            observer.onCompleted()
        })
        return alertController2
    }
    
    private(set) lazy var oneTouchSliderCVV2Alert: Driver<UIViewController> = oneTouchSlider.didFinishSwipe
        .withLatestFrom(self.viewModel.promptForCVV)
        .asObservable()
        .filter { $0 }
        .flatMap { [weak self] _ -> Observable<UIViewController> in
            Observable<UIViewController>.create { [weak self] observer in
                guard let self = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }
                
                let alertController = UIAlertController(title: NSLocalizedString("Enter CVV2", comment: ""),
                                                        message: NSLocalizedString("Enter your 3 or 4 digit security code to complete your payment.", comment: ""),
                                                        preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] _ in
                    self?.cvvValidationDisposable?.dispose()
                    self?.oneTouchSlider.reset(animated: true)
                    observer.onCompleted()
                }
                
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.cvvValidationDisposable?.dispose()
                    let textField = alertController.textFields![0]
                    let alertController2 = self.oneTouchBGELegalAlert(observer: observer)
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
                .do(onCompleted: { [weak self] in
                    self?.viewModel.cvv2.value = nil
                })
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var tooltipModal: Driver<UIViewController> = self.dueDateTooltip.rx.tap.asDriver()
        .map {
            let alertController = UIAlertController(title: NSLocalizedString("Your Due Date", comment: ""),
                                                    message: NSLocalizedString("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            return alertController
    }
    
    private(set) lazy var tutorialViewController: Driver<UIViewController> = Driver
        .merge(tutorialTap.rx.event.asDriver().map(to: ()),
               tutorialSwipe.rx.event.asDriver().map(to: ()),
               a11yTutorialButton.rx.tap.asDriver())
        .withLatestFrom(Driver.combineLatest(self.viewModel.showSaveAPaymentAccountButton, self.viewModel.enableOneTouchSlider))
        .filter { $0 && !$1 }
        .map(to: ())
        .map(OneTouchTutorialViewController.init)
    
    private lazy var bgeasyViewController: Driver<UIViewController> = self.autoPayButton.rx.tap.asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .filter { $0.isBGEasy }
        .map { _ in UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "BGEasy") }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var autoPayAlert: Driver<UIViewController> = autoPayButton.rx.tap
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
               oneTouchSliderCVV2Alert,
               tutorialViewController,
               bgeasyViewController,
               autoPayAlert)
    
    // Pushed View Controllers
    private lazy var walletViewController: Driver<UIViewController> = bankCreditNumberButton.rx.touchUpInside
        .asObservable()
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
            let vc = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "wallet") as! WalletViewController
            vc.viewModel.accountDetail = accountDetail
            vc.shouldPopToRootOnSave = true
            vc.shouldSetOneTouchPayByDefault = true
            Analytics.log(event: .oneTouchEnabledBillCard)
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var billingHistoryViewController: Driver<UIViewController> = thankYouForSchedulingButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { accountDetail in
            let vc = UIStoryboard(name: "Bill", bundle: nil).instantiateViewController(withIdentifier: "billingHistory") as! BillingHistoryViewController
            vc.accountDetail = accountDetail
            return vc
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private lazy var autoPayViewController: Driver<UIViewController> = autoPayButton.rx.tap
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .filter { !$0.isBGEasy && !StormModeStatus.shared.isOn }
        .map { accountDetail in
            switch Environment.shared.opco {
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
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(walletViewController,
                                                                                         addOTPViewController,
                                                                                         billingHistoryViewController,
                                                                                         autoPayViewController)

    deinit {
        cvvValidationDisposable?.dispose()
    }
}

extension HomeBillCardView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        
        if CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 4 {
            viewModel.cvv2.value = newString
            return true
        } else {
            return false
        }
    }
}
