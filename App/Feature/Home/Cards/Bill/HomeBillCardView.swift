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
import SafariServices

class HomeBillCardView: UIView {
    
    var bag = DisposeBag()
    
    @IBOutlet private weak var clippingView: UIView!
    
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var loadingIndicator: LoadingIndicator!
    
    @IBOutlet private weak var infoStack: UIStackView!
    
    @IBOutlet weak var billCardHeader: HomeCardHeaderView!
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
    
    @IBOutlet private weak var slideToPayConfirmationDetailContainer: UIView!
    @IBOutlet private weak var slideToPayConfirmationDetailLabel: UITextView!
    
    @IBOutlet private weak var makeAPaymentButton: PrimaryButton!
    
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
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var maintenanceModeView: UIView!
    @IBOutlet private weak var maintenanceModeLabel: UILabel!
    
    @IBOutlet weak var assistanceView: UIView!
    @IBOutlet weak var assistanceViewSeparator: UIView!
    @IBOutlet weak var titleAssistanceProgram: UILabel!
    @IBOutlet weak var descriptionAssistanceProgram: UILabel!
    @IBOutlet weak var assistanceCTA: UIButton!
    
    @IBOutlet weak var enrolmentStatusView: UIView!
    @IBOutlet weak var enrolmentStatusLabel: UILabel!
    
    @IBOutlet weak var ddeExtendedDateView: UIView!
    @IBOutlet weak var ddeExtendedDateLabel: UILabel!
    
    @IBOutlet weak var enrolmentStatusViewBillNotReady: UIView!
    @IBOutlet weak var enrolmentStatusLabelBillNotReady: UILabel!
    
    @IBOutlet weak var ddeExtendedDateViewBillNotReady: UIView!
    @IBOutlet weak var ddeExtendedDateLabelBillNotReady: UILabel!
    
    
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
        assistanceViewSeparator.backgroundColor = UIColor.accentGray
        titleAssistanceProgram.font = .caption1Semibold
        titleAssistanceProgram.textColor = .neutralDark
        if assistanceCTA.titleLabel?.text == "Reinstate Payment Arrangement" {
            self.titleAssistanceProgram.font = .caption1
            
        } else {

        descriptionAssistanceProgram.font = .caption1
        }
        descriptionAssistanceProgram.textColor = .neutralDark
        assistanceCTA.setTitleColor(.primaryBlue, for: .normal)
        assistanceCTA.titleLabel?.font = .headlineSemibold
        
        enrolmentStatusLabel.textColor = .neutralDark
        enrolmentStatusLabel.font = .caption1
        
        enrolmentStatusLabelBillNotReady.textColor = .neutralDark
        enrolmentStatusLabelBillNotReady.font = .caption1
        
        ddeExtendedDateLabel.textColor = .neutralDark
        ddeExtendedDateLabel.font = .caption1Semibold
        
        ddeExtendedDateLabelBillNotReady.textColor = .neutralDark
        ddeExtendedDateLabelBillNotReady.font = .caption1Semibold
        
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 10
        clippingView.layer.cornerRadius = 10

//        Removing border for rebrand
//        headerView.layer.borderColor = UIColor.accentGray.cgColor
//        headerView.layer.borderWidth = 1
        
        headerLabel.font = .caption1
        
        paymentDescriptionLabel.textColor = .neutralDark
        paymentDescriptionLabel.font = .headline
        
        viewModel.amountColor.drive(amountLabel.rx.textColor).disposed(by: bag)
        amountLabel.font = .largeTitle
        
        dueDateTooltip.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        slideToPayConfirmationDetailLabel.textColor = .neutralDark
        slideToPayConfirmationDetailLabel.font = .caption1
        
        scheduledPaymentBox.layer.cornerRadius = 6
        scheduledPaymentBox.layer.borderColor = UIColor.accentGray.cgColor
        scheduledPaymentBox.layer.borderWidth = 1
        thankYouForSchedulingButton.titleLabel?.font = .subheadlineSemibold
        thankYouForSchedulingButton.titleLabel?.numberOfLines = 0
        
        autoPayBox.layer.cornerRadius = 6
        autoPayBox.layer.borderColor = UIColor.accentGray.cgColor
        autoPayBox.layer.borderWidth = 1
        autoPayButtonLabel.textColor = .actionBrand
        autoPayButtonLabel.font = .subheadlineSemibold
        
        viewBillButton.titleLabel?.font = .caption1Semibold
        
        // Bill Not Ready
        billNotReadyLabel.textColor = .neutralDark
        billNotReadyLabel.font = .subheadline
        billNotReadyLabel.textAlignment = .center
        
        errorLabel.textColor = .neutralDark
        errorLabel.font = .subheadline
        errorLabel.textAlignment = .center
        if let errorLabelText = errorLabel.text {
            let localizedAccessibililtyText = NSLocalizedString("Bill OverView, %@", comment: "")
            errorLabel.accessibilityLabel = String(format: localizedAccessibililtyText, errorLabelText)
        }
        
        // Maintenance Mode
        maintenanceModeLabel.textColor = .neutralDark
        maintenanceModeLabel.font = .subheadline
        
        // Accessibility
        alertAnimation.isAccessibilityElement = true
        alertAnimation.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        
        resetAnimation()
        
        if StormModeStatus.shared.isOn {
            styleStormMode()
        }
    }
    
    private func styleStormMode() {
        backgroundColor = .white.withAlphaComponent(0.10)
        clippingView.backgroundColor = .white.withAlphaComponent(0.10)
        loadingIndicator.isStormMode = true
        headerView.backgroundColor = .clear
        assistanceView.backgroundColor = .clear
        titleAssistanceProgram.textColor = .white
        descriptionAssistanceProgram.textColor = .white
        headerLabel.textColor = .white
        paymentDescriptionLabel.textColor = .white
        amountLabel.textColor = .white
        slideToPayConfirmationDetailLabel.textColor = .white
        billNotReadyLabel.textColor = .white
        errorLabel.textColor = .white
        maintenanceModeLabel.textColor = .white
        
        dueDateTooltip.setImage(UIImage(named: "ic_tooltip_white")?.withTintColor(.secondaryGreen), for: .normal)
        
        scheduledPaymentBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        thankYouForSchedulingButton.setTitleColor(.white, for: .normal)
        scheduledImageView.image = UIImage(named: "ic_home_scheduled")?.withTintColor(.secondaryGreen)
        
        autoPayBox.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        autoPayButtonLabel.textColor = .white
        autoPayImageView.image = UIImage(named: "ic_autopay")?.withTintColor(.secondaryGreen)
        
        billNotReadyImageView.image = UIImage(named: "ic_home_billnotready_sm")?.withTintColor(.secondaryGreen)

        layer.borderColor = UIColor.clear.cgColor
        billCardHeader.isHidden = true
    }
    
    private func bindViewModel() {
        viewBillButton.isHidden = !viewModel.showViewBillButton
        if Configuration.shared.opco == .bge {
            self.assistanceView.isHidden = true
        }
        
        viewModel.paymentTracker.asDriver().drive(onNext: {
            if $0 {
                LoadingView.show(animated: true)
            } else {
                LoadingView.hide(animated: true)
            }
        })
            .disposed(by: bag)
        
        viewModel.fetchCoreSerivicesDdeDpaDetails.asDriver().drive().disposed(by: bag)
        
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
            .drive(onNext: { _ in
                GoogleAnalytics.log(event: .checkBalanceError)
                FirebaseUtility.logEvent(.home(parameters: [.balance_not_available]))
            })
            .disposed(by: bag)
        
        viewModel.showErrorState.not().drive(errorStack.rx.isHidden).disposed(by: bag)
        
        viewModel.showMaintenanceModeState.not().drive(maintenanceModeView.rx.isHidden).disposed(by: bag)
        
        Driver.combineLatest(viewModel.billNotReady.startWith(false), viewModel.showErrorState, viewModel.showMaintenanceModeState)
            .map { $0 || $1 || $2 }
            .startWith(false)
            .drive(infoStack.rx.isHidden)
            .disposed(by: bag)
        
//        viewModel.showHeaderView.map { CGFloat($0 ? 20 : 30) }.drive(topSpacerHeight.rx.constant).disposed(by: bag)
        viewModel.showHeaderView.not().drive(headerView.rx.isHidden).disposed(by: bag)
        viewModel.showAlertAnimation.not().drive(headerAlertAnimationContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.showPaymentPendingIcon.not().drive(paymentPendingContainer.rx.isHidden).disposed(by: bag)
        viewModel.showBillPaidIcon.not().drive(paymentConfirmationContainer.rx.isHidden).disposed(by: bag)
        viewModel.showSlideToPayConfirmationDetailLabel.not().drive(slideToPayConfirmationDetailContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.showPaymentDescription.not().drive(paymentDescriptionLabel.rx.isHidden).disposed(by: bag)
        viewModel.showAmount.not().drive(amountLabel.rx.isHidden).disposed(by: bag)
        viewModel.showDueDate.not().drive(dueDateStack.rx.isHidden).disposed(by: bag)
        dueDateTooltip.isHidden = !viewModel.showDueDateTooltip
        
        viewModel.showScheduledPayment.not().drive(scheduledPaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showAutoPay.not().drive(autoPayContainer.rx.isHidden).disposed(by: bag)
        
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
        
        viewModel.showMakePaymentButton.not().drive(makePaymentContainer.rx.isHidden).disposed(by: bag)
        viewModel.showMakePaymentButton.not().drive(makeAPaymentSpacerView.rx.isHidden).disposed(by: bag)
        
        viewModel.automaticPaymentInfoButtonText.drive(autoPayButtonLabel.rx.text).disposed(by: bag)
        viewModel.automaticPaymentInfoButtonText.drive(autoPayButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButton.rx.title(for: .normal)).disposed(by: bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButton.rx.accessibilityLabel).disposed(by: bag)
        viewModel.slideToPayConfirmationDetailText.drive(slideToPayConfirmationDetailLabel.rx.text).disposed(by: bag)
        
        viewModel.showCatchUpDisclaimer.not().drive(enrolmentStatusView.rx.isHidden).disposed(by: bag)
        viewModel.enrollmentStatus.drive(enrolmentStatusLabel.rx.text).disposed(by: bag)
        viewModel.showDDEExtendedView.not().drive(ddeExtendedDateView.rx.isHidden).disposed(by: bag)
        if Configuration.shared.opco == .comEd || Configuration.shared.opco == .peco {
            viewModel.showAssistanceCTAComedPeco.not().drive(onNext: { [weak self] showHideCTA in
                if self?.viewModel.comedPecoCTADetails.value?.title == "" {
                    self?.assistanceView.isHidden = true
                } else {
                    self?.assistanceView.isHidden = false
                }
        }).disposed(by: bag)
        } else {
        viewModel.showAssistanceCTA.not().drive(assistanceView.rx.isHidden).disposed(by: bag)
        }
        
        viewModel.showCatchUpDisclaimer.not().drive(enrolmentStatusViewBillNotReady.rx.isHidden).disposed(by: bag)
        viewModel.enrollmentStatus.drive(enrolmentStatusLabelBillNotReady.rx.text).disposed(by: bag)
        viewModel.showDDEExtendedView.not().drive(ddeExtendedDateViewBillNotReady.rx.isHidden).disposed(by: bag)
        viewModel.setComedPedoCTAAndEnrollment.drive().disposed(by: bag)
        viewModel.comedPecoCTADetails.asDriver().drive(onNext: { [weak self] description in
            guard let self = self else { return }
            if description == nil {
                DispatchQueue.main.async {
                    self.assistanceView.isHidden = true
                }
            }
            if (description?.title == "") &&
                (description?.description == "") {
                self.assistanceView.isHidden = true
            }
            
            DispatchQueue.main.async {
                if description?.ctaType == "Reinstate Payment Arrangement" {
                    self.titleAssistanceProgram.font = .caption1
                }

            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.titleAssistanceProgram.text = description?.title
            self.descriptionAssistanceProgram.text = description?.description
            self.assistanceCTA.setTitle(description?.ctaType, for: .normal)
            })
        }).disposed(by: bag)
        

        viewModel.paymentAssistanceValues.drive(onNext: { [weak self] description in
            guard let self = self else { return }
            if Configuration.shared.opco == .comEd || Configuration.shared.opco == .peco {
                return
            }
            if description == nil {
                DispatchQueue.main.async {
                    self.assistanceView.isHidden = true
                }
            }
            if (description?.title == "") &&
                (description?.description == "") {
                self.assistanceView.isHidden = true
            }
            
            DispatchQueue.main.async {
                if description?.ctaType == "Reinstate Payment Arrangement" {
                    self.titleAssistanceProgram.font = .caption1
                }

            }
            self.titleAssistanceProgram.text = description?.title
            self.descriptionAssistanceProgram.text = description?.description
            self.assistanceCTA.setTitle(description?.ctaType, for: .normal)
        }).disposed(by: bag)
        
        viewModel.accountDetailEvents
            .subscribe(onError: {
                if let error = $0 as? NetworkingError,
                   error != .blockAccount && error != .passwordProtected {
                    FirebaseUtility.logEvent(.bill(parameters: [.bill_not_available]))
                }
            }).disposed(by: bag)
    }
    
    private(set) lazy var viewBillPressed: Driver<Void> =
    Driver.merge([self.viewBillButton.rx.touchUpInside.asDriver(), self.billCardHeader.button.rx.touchUpInside.asDriver()])
        .do(onNext: {
            FirebaseUtility.logEvent(.home(parameters: [.bill_cta]))
            GoogleAnalytics.log(event: .viewBillBillCard)
        })
    
    private(set) lazy var oneTouchPayFinished: Observable<Void> = self.viewModel.oneTouchPayResult
        .do(onNext: { [weak self] _ in
            LoadingView.hide(animated: true)
            FirebaseUtility.logEvent(.home(parameters: [.bill_slide_to_pay]))
        })
        .mapTo(())
    
    // Modal View Controllers
    private lazy var paymentTACModal: Driver<UIViewController> = self.oneTouchPayTCButton.rx.touchUpInside.asObservable()
        .do(onNext: {
            FirebaseUtility.logEvent(.home(parameters: [.bill_terms]))
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
               bgeasyViewController,
               autoPayAlert,
               makeAPaymentReviewViewController,
               mobileAssistanceSFViewController)
    
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
            switch Configuration.shared.opco {
            case .ace, .bge, .delmarva, .pepco:
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
    
    private lazy var makeAPaymentReviewViewController: Driver<UIViewController> = makeAPaymentButton.rx.touchUpInside
        .asObservable()
        .withLatestFrom(self.viewModel.accountDetailEvents.elements())
        .map { [weak self] accountDetail in
            let storyboard = UIStoryboard(name: "TapToPay", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "TapToPayReviewPaymentViewController") as? TapToPayReviewPaymentViewController else { return UIViewController()}
            vc.accountDetail = accountDetail
            return vc
        }.asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var pushedViewControllers: Driver<UIViewController> = Driver.merge(
        billingHistoryViewController,
        autoPayViewController)
    
    private lazy var mobileAssistanceSFViewController: Driver<UIViewController> = assistanceCTA.rx.touchUpInside
        .asObservable()
        .map { [weak self] in
            guard let assistanceType = self?.viewModel.mobileAssistanceType else { return UIViewController()}
            switch assistanceType {
            case .dde:
                FirebaseUtility.logEvent(.home(parameters: [.extension_cta]))
            case .dpa:
                FirebaseUtility.logEvent(.home(parameters: [.dpa_cta]))
            case .dpaReintate:
                FirebaseUtility.logEvent(.home(parameters: [.reinstate_cta]))
            case .none:
                FirebaseUtility.logEvent(.home(parameters: [.assistance_cta]))
            }
            
            PKCEAuthenticationService.default.presentAssistanceCTA(ctaURL: self?.viewModel.mobileAssistanceURL.value ?? "") { result in
                switch (result) {
                case .success(let token):
                    if let json = TokenResponse.decodeToJson(token: token),
                       let editAction = json["profileEditActionTaken"] as? String {
                        
                    }
                case .failure(let error):
                    print(error)
                }
            }
            
            let safariVc = SFSafariViewController.createWithCustomStyle(url: URL(string: self?.viewModel.mobileAssistanceURL.value ?? "")!)
            return safariVc
        }.asDriver(onErrorDriveWith: .empty())
}
