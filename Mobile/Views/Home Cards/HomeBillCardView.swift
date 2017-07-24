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
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var paymentPendingImageView: UIImageView!
    @IBOutlet weak var paymentConfirmationImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var amountPaidLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var dueDateStack: UIStackView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dueDateTooltip: UIButton!
    
    @IBOutlet weak var dueAmountAndDateStack: UIStackView!
    @IBOutlet weak var dueAmountAndDateLabel: UILabel!
    @IBOutlet weak var dueAmountAndDateTooltip: UIButton!
    
    @IBOutlet weak var bankCreditNumberButton: ButtonControl!
    @IBOutlet weak var bankCreditCardImageView: UIImageView!
    @IBOutlet weak var bankCreditCardNumberLabel: UILabel!
    
    @IBOutlet weak var saveAPaymentAccountButton: ButtonControl!
    @IBOutlet weak var saveAPaymentAccountLabel: UILabel!
    
    @IBOutlet weak var minimumPaymentLabel: UILabel!
    
    @IBOutlet weak var billNotReadyStack: UIStackView!
    @IBOutlet weak var errorStack: UIStackView!
    
    @IBOutlet weak var oneTouchSlider: OneTouchSlider!
    
    @IBOutlet weak var scheduledImageView: UIImageView!
    @IBOutlet weak var autoPayImageView: UIImageView!
    
    @IBOutlet weak var automaticPaymentInfoButton: UIButton!
    @IBOutlet weak var thankYouForSchedulingButton: UIButton!
    @IBOutlet weak var oneTouchPayTCButton: UIButton!
    
    @IBOutlet weak var viewBillButton: UIButton!
    
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
        bankCreditNumberButton.layer.borderColor = UIColor.accentGray.cgColor
        bankCreditNumberButton.layer.borderWidth = 2
        bankCreditNumberButton.layer.cornerRadius = 3
        
        saveAPaymentAccountButton.layer.borderColor = UIColor.accentGray.cgColor
        saveAPaymentAccountButton.layer.borderWidth = 2
        saveAPaymentAccountButton.layer.cornerRadius = 3
        saveAPaymentAccountLabel.font = OpenSans.semibold.of(textStyle: .footnote)
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
        viewModel.showAlertIcon.not().drive(alertImageView.rx.isHidden).addDisposableTo(bag)
        viewModel.showPaymentPendingIcon.not().drive(paymentPendingImageView.rx.isHidden).addDisposableTo(bag)
        viewModel.showBillPaidIcon.not().drive(paymentConfirmationImageView.rx.isHidden).addDisposableTo(bag)
        viewModel.showAmountPaid.not().drive(amountPaidLabel.rx.isHidden).addDisposableTo(bag)
        viewModel.showAmount.not().drive(amountLabel.rx.isHidden).addDisposableTo(bag)
        viewModel.showDueDate.not().drive(dueDateStack.rx.isHidden).addDisposableTo(bag)
        dueDateTooltip.isHidden = !viewModel.showDueDateTooltip
        viewModel.showDueAmountAndDate.not().drive(dueAmountAndDateStack.rx.isHidden).addDisposableTo(bag)
        dueAmountAndDateTooltip.isHidden = !viewModel.showDueAmountAndDateTooltip
        viewModel.showBankCreditButton.not().drive(bankCreditNumberButton.rx.isHidden).addDisposableTo(bag)
        viewModel.showSaveAPaymentAccountButton.not().drive(saveAPaymentAccountButton.rx.isHidden).addDisposableTo(bag)
        viewModel.showMinimumPaymentAllowed.not().drive(minimumPaymentLabel.rx.isHidden).addDisposableTo(bag)
        //viewModel.showOneTouchPaySlider.not().drive(oneTouchSlider.rx.isHidden).addDisposableTo(bag)
        viewModel.showAutoPayIcon.not().drive(autoPayImageView.rx.isHidden).addDisposableTo(bag)
        viewModel.showScheduledImageView.not().drive(scheduledImageView.rx.isHidden).addDisposableTo(bag)
        viewModel.showAutomaticPaymentInfoButton.not().drive(automaticPaymentInfoButton.rx.isHidden).addDisposableTo(bag)
        viewModel.showScheduledPaymentInfoButton.not().drive(thankYouForSchedulingButton.rx.isHidden).addDisposableTo(bag)
        viewModel.showScheduledPaymentInfoButton.not().drive(oneTouchPayTCButton.rx.isHidden).addDisposableTo(bag)
        
        // Subview States
        viewModel.titleText.drive(titleLabel.rx.text).addDisposableTo(bag)
        viewModel.titleFont.drive(onNext: { [weak self] font in
            self?.titleLabel.font = font
        }).addDisposableTo(bag)
        viewModel.amountFont.drive(onNext: { [weak self] font in
            self?.amountLabel.font = font
        }).addDisposableTo(bag)
        viewModel.enableOneTouchSlider.drive(oneTouchSlider.rx.isEnabled).addDisposableTo(bag)
        
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
