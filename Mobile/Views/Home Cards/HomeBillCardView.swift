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
    
    @IBOutlet weak var amountPaidContainer: UIView!
    @IBOutlet weak var amountPaidLabel: UILabel!
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
    
    static func create(withViewModel viewModel: HomeBillCardViewModel) -> HomeBillCardView {
        let view = Bundle.main.loadViewFromNib() as HomeBillCardView
        view.viewModel = viewModel
        return view
    }
    
    private func styleViews() {
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.cornerRadius = 2
        
        alertImageView.accessibilityLabel = NSLocalizedString("Alert", comment: "")
        
        amountPaidLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        bankCreditNumberButton.layer.borderColor = UIColor.accentGray.cgColor
        bankCreditNumberButton.layer.borderWidth = 2
        bankCreditNumberButton.layer.cornerRadius = 3
        bankCreditCardNumberLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        saveAPaymentAccountButton.layer.borderColor = UIColor.accentGray.cgColor
        saveAPaymentAccountButton.layer.borderWidth = 2
        saveAPaymentAccountButton.layer.cornerRadius = 3
        saveAPaymentAccountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        dueDateTooltip.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        dueAmountAndDateTooltip.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        saveAPaymentAccountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
        bankCreditCardNumberLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        convenienceFeeLabel.font = OpenSans.semibold.of(textStyle: .footnote)
        
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
    }
    
    private func bindViewModel() {
        viewModel.paymentTracker.asDriver().drive(onNext: {
            if $0 {
                LoadingView.show(animated: true)
            } else {
                LoadingView.hide(animated: true)
            }
            })
            .addDisposableTo(bag)
        
        // Show/Hide Subviews
        viewModel.billNotReady.not().drive(billNotReadyStack.rx.isHidden).addDisposableTo(bag)
        viewModel.showErrorState.not().drive(errorStack.rx.isHidden).addDisposableTo(bag)
        viewModel.showAlertIcon.not().drive(alertContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showPaymentPendingIcon.not().drive(paymentPendingContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showBillPaidIcon.not().drive(paymentConfirmationContainer.rx.isHidden).addDisposableTo(bag)
        Driver.zip(viewModel.showAlertIcon, viewModel.showPaymentPendingIcon, viewModel.showBillPaidIcon)
            .map { $0 || $1 || $2 }
            .map { $0 ? 0: 32 }
            .drive(titleLabelTopConstraint.rx.constant)
            .addDisposableTo(bag)
        viewModel.showAmountPaid.not().drive(amountPaidContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showAmount.not().drive(amountLabel.rx.isHidden).addDisposableTo(bag)
        viewModel.showDueDate.not().drive(dueDateStack.rx.isHidden).addDisposableTo(bag)
        viewModel.showDueDateTooltip.not().drive(dueDateTooltip.rx.isHidden).addDisposableTo(bag)
        viewModel.showDueAmountAndDate.not().drive(dueAmountAndDateContainer.rx.isHidden).addDisposableTo(bag)
        dueAmountAndDateTooltip.isHidden = !viewModel.showDueAmountAndDateTooltip
        viewModel.showBankCreditButton.not().drive(bankCreditNumberContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showSaveAPaymentAccountButton.not().drive(saveAPaymentAccountContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showConvenienceFee.not().drive(convenienceFeeContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showMinimumPaymentAllowed.not().drive(minimumPaymentContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showOneTouchPaySlider.not().drive(oneTouchSlider.rx.isHidden).addDisposableTo(bag)
        viewModel.showScheduledImageView.not().drive(scheduledImageContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showAutoPayIcon.not().drive(autoPayImageContainer.rx.isHidden).addDisposableTo(bag)
        viewModel.showAutomaticPaymentInfoButton.not().drive(automaticPaymentInfoButton.rx.isHidden).addDisposableTo(bag)
        viewModel.showScheduledPaymentInfoButton.not().drive(thankYouForSchedulingButton.rx.isHidden).addDisposableTo(bag)
        viewModel.showOneTouchPayTCButton.not().drive(oneTouchPayTCButton.rx.isHidden).addDisposableTo(bag)
        
        // Subview States
        viewModel.titleText.drive(titleLabel.rx.text).addDisposableTo(bag)
        viewModel.titleFont.drive(onNext: { [weak self] font in
            self?.titleLabel.font = font
        }).addDisposableTo(bag)
        viewModel.amountFont.drive(onNext: { [weak self] font in
            self?.amountLabel.font = font
        }).addDisposableTo(bag)
        viewModel.amountPaidText.drive(amountPaidLabel.rx.text).addDisposableTo(bag)
        viewModel.amountText.drive(amountLabel.rx.text).addDisposableTo(bag)
        viewModel.dueDateText.drive(dueDateLabel.rx.attributedText).addDisposableTo(bag)
        viewModel.dueAmountAndDateText.drive(dueAmountAndDateLabel.rx.text).addDisposableTo(bag)
        viewModel.bankCreditCardNumberText.drive(bankCreditCardNumberLabel.rx.text).addDisposableTo(bag)
        viewModel.bankCreditCardImage.drive(bankCreditCardImageView.rx.image).addDisposableTo(bag)
        viewModel.bankCreditCardImageAccessibilityLabel
            .drive(onNext: { [weak self] accessibilityLabel in
                self?.bankCreditCardImageView.accessibilityLabel = accessibilityLabel
            }).addDisposableTo(bag)
        viewModel.minPaymentAllowedText.drive(minimumPaymentLabel.rx.text).addDisposableTo(bag)
        viewModel.convenienceFeeText.drive(convenienceFeeLabel.rx.text).addDisposableTo(bag)
        viewModel.enableOneTouchSlider.drive(oneTouchSlider.rx.isEnabled).addDisposableTo(bag)
        viewModel.automaticPaymentInfoButtonText.drive(automaticPaymentInfoButtonLabel.rx.text).addDisposableTo(bag)
        viewModel.thankYouForSchedulingButtonText.drive(thankYouForSchedulingButtonLabel.rx.text).addDisposableTo(bag)
        viewModel.oneTouchPayTCButtonText.drive(oneTouchPayTCButtonLabel.rx.text).addDisposableTo(bag)
        
        // Actions
        oneTouchSlider.didFinishSwipe
            .withLatestFrom(self.viewModel.shouldShowWeekendWarning)
            //.filter { !$0 }
            .map { _ in () }
            .drive(viewModel.submitOneTouchPay)
            .addDisposableTo(bag)
        
        viewModel.oneTouchPayResult.subscribe { print($0) }.addDisposableTo(bag)
    }
    
    private(set) lazy var oneTouchSliderWeekendAlert: Driver<UIViewController> = self.oneTouchSlider.didFinishSwipe
        .withLatestFrom(self.viewModel.shouldShowWeekendWarning)
        .filter { $0 }
        .map { _ in
            let alertController = UIAlertController(title: NSLocalizedString("Weekend/Holiday Payment", comment: ""),
                                                    message: NSLocalizedString("You are making a payment on a weekend or holiday. Your payment will be scheduled for the next business day.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
                self?.viewModel.submitOneTouchPay.onNext()
            })
            return alertController
    }
    
    private lazy var tooltipModal: Driver<UIViewController> = Driver.merge(self.dueDateTooltip.rx.tap.asDriver(),
                                                                           self.dueAmountAndDateTooltip.rx.tap.asDriver())
        .map {
            let alertController = UIAlertController(title: NSLocalizedString("Your Due Date", comment: ""),
                                                    message: NSLocalizedString("If you recently changed your energy supplier, a portion of your balance may have an earlier due date. Please view your previous bills and corresponding due dates.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            return alertController
    }
    
    private(set) lazy var modalViewControllers: Driver<UIViewController> = Driver.merge(self.tooltipModal, self.oneTouchSliderWeekendAlert)

}
