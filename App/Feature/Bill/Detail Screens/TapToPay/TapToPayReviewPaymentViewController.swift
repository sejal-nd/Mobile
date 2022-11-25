//
//  TapToPayReviewPaymentViewController.swift
//  Mobile
//
//  Created by Adarsh Maurya on 07/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TapToPayReviewPaymentViewController: UIViewController {
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    @IBOutlet weak var dueAmountDescriptionLabel: UILabel!
    @IBOutlet weak var paymentAmountContainer: UIView!
    
    @IBOutlet weak var activeSeveranceTextContainer: UIView!
    @IBOutlet weak var youArePayingLabel: UILabel!
    @IBOutlet weak var paymentsAssociatedTextLabel: UILabel!
    @IBOutlet weak var submitDescriptionLabel: UILabel!
    @IBOutlet weak var termsNConditionsButton: UIButton!
    @IBOutlet weak var paymentErrorLabel: UILabel!
    @IBOutlet weak var paymentAmountContainerButton: ButtonControl!
    
    // -- Additional Recipients View -- //
    @IBOutlet weak var addAdditionalRecipients: UIView!
    @IBOutlet weak var collapseButton: UIButton!
    @IBOutlet weak var alternateEmailNumberView: UIView!
    @IBOutlet weak var alternateEmailTextField: FloatLabelTextField!
    @IBOutlet weak var alternateNumberTextField: FloatLabelTextField!
    @IBOutlet weak var alternateViewTextView: UITextView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var alternateContactDivider: UIView!
    @IBOutlet weak var addAdditionaRecipientButton: UIButton!
    @IBOutlet weak var addAdditionalRecipeintBottomDivider: UIView!
    
    // -- Payment Method View -- //
    @IBOutlet weak var bankAccount: ButtonControl!
    @IBOutlet weak var creditDebitCard: ButtonControl!
    @IBOutlet weak var bankAccountTitleLabel: UILabel!
    @IBOutlet weak var creditCardTitleLabel: UILabel!
    @IBOutlet weak var paymentMethodContainer: UIView!
    @IBOutlet weak var choosePaymentMethodContainer: UIView!
    @IBOutlet weak var cashOnlyPaymentMethodLabel: UILabel!
    @IBOutlet weak var cashOnlyChoosePaymentLabel: UILabel!
    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentMethodNicknameLabel: UILabel!
    @IBOutlet weak var paymentMethodButton: ButtonControl!
    @IBOutlet weak var selectPaymentMethodContainer: UIView!
    @IBOutlet weak var selectPaymentButton: ButtonControl!
    @IBOutlet weak var selectPaymentLabel: UILabel!
    @IBOutlet weak var bankAccountNotAvailableBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var bankAccountNotAvailable: NSLayoutConstraint!
    @IBOutlet weak var editPaymentMethodIcon: UIImageView!
    
    // -- Payment Date View -- //
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentDateTitleLabel: UILabel!
    @IBOutlet weak var paymentDateButton: ButtonControl!
    @IBOutlet weak var paymentDateEditIcon: UIImageView!
    @IBOutlet weak var paymentDatePastDueLabel: UILabel!
    @IBOutlet weak var sameDayPaymentWarningLabel: UILabel!
    @IBOutlet weak var editPaymentAmountButton: UIButton!
    
    @IBOutlet weak var overPayingAmountLabel: UILabel!
    @IBOutlet weak var overPayingContainerView: UIView!
    @IBOutlet weak var overPayingHeaderLabel: UILabel!
    @IBOutlet weak var overPayingCheckbox: Checkbox!
    @IBOutlet weak var overPayingLabel: UILabel!
    @IBOutlet weak var latePaymentErrorLabel: UILabel!
    
    
    // -- Review Payment View -- //
    @IBOutlet weak var submitButton: PrimaryButton!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stickyPaymentFooterView: StickyFooterView!
    @IBOutlet weak var dateWarningStackBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateWarningstackviewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var paymentAmountContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var convienceFeeBottomLabel: NSLayoutConstraint!
    @IBOutlet weak var scrollViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewLeadingConstraint: NSLayoutConstraint!
    
    // Cancel Payment
    @IBOutlet weak var cancelPaymentButton: ButtonControl!
    @IBOutlet weak var cancelPaymentLabel: UILabel!
    
    @IBOutlet weak var creditCardDateRangeError: UILabel!
    
    var viewModel: TapToPayViewModel!
    var accountDetail: AccountDetail! // Passed in from presenting view
    var billingHistoryItem: BillingHistoryItem? // Passed in from Billing History, indicates we are modifying a payment
    
    var bag = DisposeBag()
    var animatedView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        viewModel = TapToPayViewModel(accountDetail: accountDetail,
                                      billingHistoryItem: billingHistoryItem)
        
        addCloseButton()
        if billingHistoryItem != nil {
            title = NSLocalizedString("Edit Payment", comment: "")
            addAdditionalRecipients.isHidden = true
            addAdditionalRecipeintBottomDivider.isHidden = true
        } else {
            title = NSLocalizedString("Review Payment", comment: "")
        }
        
        youArePayingLabel.textColor = .deepGray
        youArePayingLabel.font = SystemFont.regular.of(size: 13)
        youArePayingLabel.text = NSLocalizedString("You’re Paying", comment: "")
        youArePayingLabel.isAccessibilityElement = true
        youArePayingLabel.accessibilityLabel = youArePayingLabel.text
        
        paymentAmountContainer.isAccessibilityElement = false
        paymentAmountContainer.accessibilityLabel = youArePayingLabel.text
        paymentAmountContainerButton.isAccessibilityElement = false
        
        amountLabel.textColor = .deepGray
        amountLabel.font = SystemFont.semibold.of(size: 22)
        amountLabel.isAccessibilityElement = true
        amountLabel.accessibilityElementsHidden = false
        amountLabel.accessibilityLabel = amountLabel.text
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(size: 12)
        convenienceFeeLabel.isAccessibilityElement = true
        convenienceFeeLabel.accessibilityLabel = convenienceFeeLabel.text
        
        self.paymentAmountContainer.accessibilityElements = [youArePayingLabel as Any,
                                                             amountLabel as Any,
                                                             convenienceFeeLabel as Any,
                                                             editPaymentAmountButton as Any]
        
        addAdditionaRecipientButton.setTitleColor(.deepGray, for: .normal)
        addAdditionaRecipientButton.titleLabel?.font = SystemFont.medium.of(size: 16)
        
        paymentsAssociatedTextLabel.textColor = .deepGray
        paymentsAssociatedTextLabel.font = SystemFont.regular.of(size: 12)
        
        if Configuration.shared.opco == .comEd {
            paymentsAssociatedTextLabel.text = "All payments are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment."
        } else {
            paymentsAssociatedTextLabel.text = "All payments and associated convenience fees are processed by Paymentus Corporation. Payment methods saved to My Wallet are stored by Paymentus Corporation. You will receive an email confirming that your payment was submitted successfully. If you receive an error message, please check for your email confirmation to verify you’ve successfully submitted payment."
        }
        
        submitDescriptionLabel.textColor = .deepGray
        submitDescriptionLabel.font = SystemFont.regular.of(size: 12)
        submitDescriptionLabel.text = NSLocalizedString("By tapping Submit, you agree to the payment", comment: "")
        
        termsNConditionsButton.setTitleColor(.actionBlue, for: .normal)
        termsNConditionsButton.titleLabel?.text = NSLocalizedString("Terms & Conditions.", comment: "")
        termsNConditionsButton.titleLabel?.font = SystemFont.semibold.of(size: 12)
        termsNConditionsButton.accessibilityLabel = termsNConditionsButton.titleLabel?.text
        
        paymentMethodContainer.isAccessibilityElement = false
        paymentMethodButton.isAccessibilityElement = false
        
        paymentMethodAccountNumberLabel.textColor = .deepGray
        paymentMethodAccountNumberLabel.font = SystemFont.regular.of(size: 16)
        paymentMethodAccountNumberLabel.isAccessibilityElement = true
        paymentMethodAccountNumberLabel.accessibilityLabel = paymentMethodAccountNumberLabel.text
        
        paymentMethodNicknameLabel.textColor = .middleGray
        paymentMethodNicknameLabel.font = SystemFont.regular.of(size: 12)
        paymentMethodNicknameLabel.isAccessibilityElement = true
        paymentMethodNicknameLabel.accessibilityLabel = paymentMethodNicknameLabel.text
        
        bankAccount.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        bankAccount.backgroundColorOnPress = .actionBlue
        bankAccount.accessibilityLabel = NSLocalizedString("Bank Account", comment: "")
        
        bankAccountTitleLabel.text = NSLocalizedString("Bank Account", comment: "")
        bankAccountTitleLabel.textColor = .actionBlue
        bankAccountTitleLabel.font = SystemFont.semibold.of(size: 12)
        
        creditDebitCard.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        creditDebitCard.backgroundColorOnPress = .actionBlue
        creditDebitCard.accessibilityLabel = NSLocalizedString("Credit/Debit Card", comment: "")
        
        creditCardTitleLabel.text = NSLocalizedString("Credit/Debit Card", comment: "")
        creditCardTitleLabel.textColor = .actionBlue
        creditCardTitleLabel.font = SystemFont.semibold.of(size: 12)
        
        self.paymentDateButton.isAccessibilityElement = false
        
        paymentDateLabel.textColor = .deepGray
        paymentDateLabel.font = SystemFont.semibold.of(size: 16)
        
        selectPaymentLabel.textColor = .deepGray
        selectPaymentLabel.font = SystemFont.semibold.of(size: 16)
        
        paymentDatePastDueLabel.textColor = .deepGray
        paymentDatePastDueLabel.font = SystemFont.regular.of(size: 12)
        paymentDatePastDueLabel.text = NSLocalizedString("Past due payments cannot be scheduled for a later date.", comment: "")
        
        sameDayPaymentWarningLabel.textColor = .deepGray
        sameDayPaymentWarningLabel.font = SystemFont.regular.of(size: 12)
        sameDayPaymentWarningLabel.text = NSLocalizedString("Same-day payments cannot be edited or canceled after submission.", comment: "")
        
        creditCardDateRangeError.textColor = .errorRed
        creditCardDateRangeError.font = SystemFont.semibold.of(size: 12)
        creditCardDateRangeError.text = NSLocalizedString("Error: Credit card payments cannot be scheduled more than 90 days in advance.", comment: "")
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .deepGray
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.accessibilityLabel = errorLabel.text
        
        // Overpaying
        overPayingAmountLabel.textColor = .errorRed
        overPayingAmountLabel.font = SystemFont.semibold.of(size: 12)
        overPayingAmountLabel.text = NSLocalizedString("Overpaying: $0.00", comment: "")
        overPayingAmountLabel.isAccessibilityElement = true
        overPayingAmountLabel.accessibilityLabel = overPayingAmountLabel.text
        
        overPayingHeaderLabel.textColor = .deepGray
        overPayingHeaderLabel.font = SystemFont.regular.of(size: 15)
        overPayingHeaderLabel.text = NSLocalizedString("You are scheduling a payment that may result in overpaying your total amount due.", comment: "")
        
        overPayingLabel.textColor = .deepGray
        overPayingLabel.font = SystemFont.regular.of(size: 15)
        overPayingLabel.text = NSLocalizedString("Yes, I acknowledge I am scheduling a payment for more than is currently due on my account.", comment: "")
        
        latePaymentErrorLabel.textColor = .errorRed
        latePaymentErrorLabel.font = SystemFont.regular.of(size: 12)
        latePaymentErrorLabel.numberOfLines = .zero
        latePaymentErrorLabel.text = "The Selected date is past your bill's due date and could result in a late payment"
        latePaymentErrorLabel.isAccessibilityElement = true
        latePaymentErrorLabel.accessibilityLabel = latePaymentErrorLabel.text
        
        paymentErrorLabel.textColor = .errorRed
        paymentErrorLabel.font = SystemFont.semibold.of(size: 12)
        
        paymentsAssociatedTextLabel.textColor = .deepGray
        paymentsAssociatedTextLabel.font = SystemFont.regular.of(size: 12)
        
        submitButton.titleLabel?.textColor = .white
        submitButton.titleLabel?.font = SystemFont.semibold.of(size: 17)
        
        viewModel.fetchData(initialFetch: true, onSuccess: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }, onError: { [weak self] in
                guard let self = self else { return }
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
        })
        
        self.editPaymentAmountButton.isAccessibilityElement = true
        self.editPaymentAmountButton.accessibilityLabel = NSLocalizedString("Edit Payment Amount", comment: "")
        
        self.editPaymentMethodIcon.isAccessibilityElement = true
        self.editPaymentMethodIcon.accessibilityLabel = NSLocalizedString("Edit Payment Method", comment: "")
        self.editPaymentMethodIcon.accessibilityTraits = UIAccessibilityTraits.button
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollViewTrailingConstraint.priority = UILayoutPriority(rawValue: 750)
            scrollViewLeadingConstraint.priority = UILayoutPriority(rawValue: 750)
        } else {
            scrollViewTrailingConstraint.priority = UILayoutPriority(rawValue: 1000)
            scrollViewLeadingConstraint.priority = UILayoutPriority(rawValue: 1000)
        }
        
        
        let cancelPaymentText = NSLocalizedString("Cancel Payment", comment: "")
        cancelPaymentButton.accessibilityLabel = cancelPaymentText
        cancelPaymentLabel.text = cancelPaymentText
        cancelPaymentLabel.font = SystemFont.semibold.of(textStyle: .headline)
        cancelPaymentLabel.textColor = .actionBlue
        
        self.stickyPaymentFooterView.accessibilityElements = [submitDescriptionLabel as Any,
                                                              termsNConditionsButton as Any,
                                                              submitButton as Any]
        
        configureAdditionalRecipientsView()
        bindViewContent()
        bindButtonTaps()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        FirebaseUtility.logScreenView(.paymentView(className: self.className))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TapToPayConfirmationViewController {
            vc.presentingNavController = navigationController
            vc.modalPresentationStyle = .overFullScreen
            vc.viewModel = viewModel
        }
    }
    
    @objc override func dismissModal() {
        FirebaseUtility.logEvent(.payment(parameters: [.cancel]))
        dismiss(animated: true, completion: nil)
    }
    
    func bindViewContent() {
        
        // Payment Amount Text Field
        viewModel.convenienceDisplayString.asDriver()
            .drive(convenienceFeeLabel.rx.text)
            .disposed(by: bag)
        
        viewModel.paymentAmountReviewPageErrorMessage.asDriver().drive(onNext: { [weak self] errorMessage in
            if (FeatureFlagUtility.shared.bool(forKey: .isLowPaymentAllowed)) {
                self?.paymentErrorLabel.text = ""
            } else {
                self?.paymentErrorLabel.text = errorMessage
            }
        }).disposed(by: bag)
        viewModel.paymentFieldReviewPaymentValid.asDriver().drive(paymentErrorLabel.rx.isHidden).disposed(by: bag)
        
        // Selected Wallet Item
        viewModel.selectedWalletItemImage.drive(paymentMethodImageView.rx.image).disposed(by: bag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentMethodAccountNumberLabel.rx.text).disposed(by: bag)
        viewModel.selectedWalletItemMaskedAccountString.drive(paymentMethodAccountNumberLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.selectedWalletItemNickname.drive(paymentMethodNicknameLabel.rx.text).disposed(by: bag)
        viewModel.selectedWalletItemNickname.drive(paymentMethodNicknameLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.showSelectedWalletItemNickname.not().drive(paymentMethodNicknameLabel.rx.isHidden).disposed(by: bag)
        
        viewModel.isCashOnlyUser.not().drive(cashOnlyPaymentMethodLabel.rx.isHidden).disposed(by: bag)
        viewModel.isCashOnlyUser.not().drive(cashOnlyChoosePaymentLabel.rx.isHidden).disposed(by: bag)
        viewModel.isCashOnlyUser.not().drive(bankAccount.rx.isEnabled).disposed(by: bag)
        viewModel.isCashOnlyUser.not().drive(onNext: { [weak self] isNotCashOnlyUser in
            self?.bankAccountNotAvailable.constant = isNotCashOnlyUser ? -5 : 16
            self?.bankAccountNotAvailableBottomContraint.constant = isNotCashOnlyUser ? -5 : 16
        }).disposed(by: bag)
        
        
        viewModel.hasWalletItems.drive(choosePaymentMethodContainer.rx.isHidden).disposed(by: bag)
        viewModel.hasWalletItems.not().drive(paymentMethodContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: bag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: bag)
        
        viewModel.shouldShowPaymentMethodExpiredButton.not().drive(selectPaymentMethodContainer.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowPaymentMethodExpiredButton.drive(paymentMethodContainer.rx.isHidden).disposed(by: bag)
        
        // Payment Date
        viewModel.paymentDateString.asDriver().drive(paymentDateLabel.rx.text).disposed(by: bag)
        viewModel.shouldShowPastDueLabel.not().drive(paymentDatePastDueLabel.rx.isHidden).disposed(by: bag)
       
        viewModel.shouldShowSameDayPaymentWarning.drive(onNext: { [weak self] showSameDayWarning in
            guard let self = self else { return }
            self.sameDayPaymentWarningLabel.isHidden = !showSameDayWarning
        }).disposed(by: bag)
        
        viewModel.shouldShowLatePaymentWarning.drive(onNext: { [weak self] showLatePaymentWarning in
            guard let self = self else { return }
            self.latePaymentErrorLabel.isHidden = !showLatePaymentWarning
        }).disposed(by: bag)
        
        viewModel.showCreditCardDateRangeError.drive(onNext: { [weak self] showcreditCardDateRangeError in
            guard let self = self else { return }
            self.creditCardDateRangeError.isHidden = !showcreditCardDateRangeError
        }).disposed(by: bag)
        
        viewModel.enablePaymentDate.drive(onNext: { [weak self]  enableDate in
            guard let self = self else { return }
            self.paymentDateEditIcon.image = enableDate ? #imageLiteral(resourceName: "ic_edit") : #imageLiteral(resourceName: "ic_edit_disabled")
            self.paymentDateButton.isUserInteractionEnabled = enableDate
            self.paymentDateEditIcon.isAccessibilityElement = true
            self.paymentDateEditIcon.accessibilityLabel = enableDate ? NSLocalizedString("Edit Payment date", comment: "") :  NSLocalizedString("Edit Payment date, disabled", comment: "")
            self.paymentDateEditIcon.accessibilityTraits = UIAccessibilityTraits.button
        }).disposed(by: bag)

                
        //Paymentus < $5
        viewModel.enableReviewEditPayment.drive(onNext: { [weak self]  enableEditPayment in
            guard let self = self else { return }
            self.paymentAmountContainer.isUserInteractionEnabled = enableEditPayment ? true : false
            self.editPaymentAmountButton.isEnabled = enableEditPayment ? true : false
           
        }).disposed(by: bag)

        
        // OverPaying
        viewModel.isOverpaying.map(!).drive( onNext: { [weak self] isNotOverPaying in
            guard let self = self else { return }
            self.overPayingAmountLabel.isHidden = isNotOverPaying
            self.convienceFeeBottomLabel.constant = isNotOverPaying ? 30 : 50
        }).disposed(by: bag)
        
        viewModel.isOverpaying.map(!).drive(overPayingContainerView.rx.isHidden).disposed(by: bag)
        viewModel.overpayingValueDisplayString.asDriver().drive(overPayingAmountLabel.rx.text).disposed(by: bag)
        self.overPayingCheckbox.rx.isChecked.bind(to: viewModel.overpayingSwitchValue).disposed(by: bag)
        
        // Submit button enable/disable
        if billingHistoryItem != nil {
            // Edit flow
            viewModel.editPaymentSubmitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: bag)
        } else {
            viewModel.reviewPaymentSubmitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: bag)
        }
        
        // Show content
        viewModel.shouldShowContent.drive(onNext: { [weak self] shouldShow in
            self?.stickyPaymentFooterView.isHidden = !shouldShow
        }).disposed(by: bag)
        
        // Cancel Payment
        viewModel.shouldShowCancelPaymentButton.not().drive(cancelPaymentButton.rx.isHidden).disposed(by: bag)
        
        cancelPaymentButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            self?.onCancelPaymentPress()
        }).disposed(by: bag)
        
    }
    
    func bindButtonTaps() {
        
        Driver.merge(paymentAmountContainerButton.rx.touchUpInside.asDriver(),
                           editPaymentAmountButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
                
                guard let paymentAmountSheet = UIStoryboard(name: "PaymentAmount", bundle: .main).instantiateInitialViewController() as? PaymentAmountSheetViewController else { return }
                paymentAmountSheet.modalPresentationStyle = .overCurrentContext
                paymentAmountSheet.viewModel = self.viewModel
                self.present(paymentAmountSheet, animated: false, completion: nil)
            }).disposed(by: bag)
        
        Driver.merge(paymentMethodButton.rx.touchUpInside.asDriver(),
                     selectPaymentButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
                
                FirebaseUtility.logEvent(.payment(parameters: [.switch_payment_method]))
                
                guard let miniWalletVC = UIStoryboard(name: "MiniWalletSheet", bundle: .main).instantiateInitialViewController() as? MiniWalletSheetViewController else { return }
                miniWalletVC.modalPresentationStyle = .overCurrentContext
                
                miniWalletVC.viewModel.walletItems = self.viewModel.walletItems.value!
                if let selectedItem = self.viewModel.selectedWalletItem.value {
                    miniWalletVC.viewModel.selectedWalletItem = selectedItem
                    if selectedItem.isTemporary {
                        miniWalletVC.viewModel.temporaryWalletItem = selectedItem
                    } else if selectedItem.isEditingItem {
                        miniWalletVC.viewModel.editingWalletItem = selectedItem
                    }
                }
                miniWalletVC.accountDetail = self.viewModel.accountDetail.value
                miniWalletVC.delegate = self
                
                self.present(miniWalletVC, animated: false, completion: nil)
            }).disposed(by: bag)
        
        
        // Bank button when no payment method selected
        bankAccount.rx.touchUpInside
            .do(onNext: { GoogleAnalytics.log(event: .addBankNewWallet) })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let actionSheet = UIAlertController
                    .saveToWalletActionSheet(bankOrCard: .bank, saveHandler: { [weak self] _ in
                        self?.presentPaymentusForm(bankOrCard: .bank, temporary: false)
                        }, dontSaveHandler: { [weak self] _ in
                            self?.presentPaymentusForm(bankOrCard: .bank, temporary: true)
                    })
                self.present(actionSheet, animated: true, completion: nil)
            }).disposed(by: bag)
        // Credit card button when no payment method selected
        creditDebitCard.rx.touchUpInside
             .do(onNext: { GoogleAnalytics.log(event: .addCardNewWallet) })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let actionSheet = UIAlertController
                    .saveToWalletActionSheet(bankOrCard: .card, saveHandler: { [weak self] _ in
                        self?.presentPaymentusForm(bankOrCard: .card, temporary: false)
                        }, dontSaveHandler: { [weak self] _ in
                            self?.presentPaymentusForm(bankOrCard: .card, temporary: true)
                    })
                self.present(actionSheet, animated: true, completion: nil)
            }).disposed(by: bag)
        
        // Payment Date button
        paymentDateButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            
            let calendarViewController = CalendarViewController()
            calendarViewController.extendedLayoutIncludesOpaqueBars = true
            calendarViewController.calendar = .opCo
            calendarViewController.delegate = self
            calendarViewController.title = NSLocalizedString("Select Payment Date", comment: "")
            calendarViewController.selectedDate = self.viewModel.paymentDate.value
            
            self.navigationController?.pushViewController(calendarViewController, animated: true)
        }).disposed(by: bag)
    }
    
    func configureAdditionalRecipientsView() {
        
        viewModel.totalPaymentDisplayString.drive(amountLabel.rx.text).disposed(by: bag)
        viewModel.totalPaymentDisplayString.drive(amountLabel.rx.accessibilityLabel).disposed(by: bag)
        viewModel.convenienceDisplayString.drive(convenienceFeeLabel.rx.text).disposed(by: bag)
        viewModel.convenienceDisplayString.drive(convenienceFeeLabel.rx.accessibilityLabel).disposed(by: bag)
        
        viewModel.dueAmountDescriptionText.drive(dueAmountDescriptionLabel.rx.attributedText).disposed(by: bag)
        
        // Active Severance Label
        viewModel.isActiveSeveranceUser.not().drive(activeSeveranceTextContainer.rx.isHidden).disposed(by: bag)
        
        collapseButton.isSelected = false
        collapseButton.setImage(#imageLiteral(resourceName: "ic_caret_down"), for: .normal)
        collapseButton.setImage(#imageLiteral(resourceName: "ic_caret_up"), for: .selected)
        collapseButton.isAccessibilityElement = false
        
        alternateEmailNumberView.isHidden = true
        alternateEmailNumberView.backgroundColor = .softGray
        self.alternateContactDivider.isHidden = true
        
        alternateViewTextView.backgroundColor = .softGray
        alternateViewTextView.textColor = .deepGray
        alternateViewTextView.font = SystemFont.regular.of(size: 15)
        alternateViewTextView.text = NSLocalizedString("A confirmation will be sent to the email address associated with your My Account. If you'd like to send this payment confirmation to an additional email or via text message, add the recipients below. Standard messaging rates apply.", comment: "")
        
        addAdditionaRecipientButton.setTitleColor(.deepGray, for: .normal)
        addAdditionaRecipientButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        alternateEmailTextField.placeholder = NSLocalizedString("Email Address (Optional)",
                                                                comment: "")
        alternateEmailTextField.textField.autocorrectionType = .no
        alternateEmailTextField.textField.returnKeyType = .next
        alternateEmailTextField.setKeyboardType(.emailAddress)
        alternateEmailTextField.textField.isShowingAccessory = true
        alternateEmailTextField.setError(nil)
        alternateEmailTextField.textField.delegate = self
        
        viewModel.emailIsValid.drive(onNext: { [weak self] errorMessage in
            self?.alternateEmailTextField.setError(errorMessage)
        }).disposed(by: self.bag)
        
        alternateEmailTextField.textField.rx.text.orEmpty.bind(to: viewModel.emailAddress).disposed(by: bag)
        
        alternateEmailTextField.textField.rx.controlEvent(.editingDidBegin).asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                // If we displayed an inline error, clear it when user edits the text
                if self.alternateEmailTextField.errorState {
                    self.alternateEmailTextField.setError(nil)
                }
            }).disposed(by: bag)
        
        alternateEmailTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .drive(onNext: { [weak self] in
                self?.alternateNumberTextField.textField.becomeFirstResponder()
            }).disposed(by: bag)
        
        alternateNumberTextField.placeholder = NSLocalizedString("Phone Number (Optional)",
                                                                 comment: "")
        alternateNumberTextField.textField.autocorrectionType = .no
        alternateNumberTextField.setKeyboardType(.phonePad)
        alternateNumberTextField.textField.delegate = self
        alternateNumberTextField.textField.isShowingAccessory = true
        
        alternateNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).disposed(by: bag)
        
        alternateNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.phoneNumber.asDriver(), viewModel.phoneNumberHasTenDigits))
            .drive(onNext: { [weak self] phoneNumber, hasTenDigits in
                guard let self = self else { return }
                if !phoneNumber.isEmpty && !hasTenDigits {
                    self.alternateNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long", comment: ""))
                }
            }).disposed(by: bag)
        
        alternateNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.alternateNumberTextField.setError(nil)
        }).disposed(by: bag)
        
    }
    
    
    // MARK: - Keyboard
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        let safeAreaBottomInset = view.safeAreaInsets.bottom
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: endFrameRect.size.height - safeAreaBottomInset, right: 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets

    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    @IBAction func termsConditionPress(_ sender: Any) {
        FirebaseUtility.logEvent(.payment(parameters: [.view_terms]))
        
        let url = URL(string: "https://ipn2.paymentus.com/rotp/www/terms-and-conditions-exln.html")!
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""), url: url)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    @IBAction func collapseExpandAdditionalRecipients(_ sender: Any) {
        
        // Animate expand/collapse
        self.collapseButton.isSelected = !self.collapseButton.isSelected
        self.alternateContactDivider.isHidden = self.collapseButton.isSelected ? false : true
        self.view.layoutIfNeeded()
        self.alternateEmailNumberView.isHidden = self.collapseButton.isSelected ? false : true
    }

    private func presentPaymentusForm(bankOrCard: BankOrCard, temporary: Bool) {
        let paymentusVC = PaymentusFormViewController(bankOrCard: bankOrCard,
                                                      temporary: temporary,
                                                      isWalletEmpty: viewModel.walletItems.value!.isEmpty)
        paymentusVC.delegate = self
        let largeTitleNavController = LargeTitleNavigationController(rootViewController: paymentusVC)
        present(largeTitleNavController, animated: true, completion: nil)
    }
    
    func fetchData(initialFetch: Bool) {
         viewModel.fetchData(initialFetch: initialFetch, onSuccess: { [weak self] in
             guard let self = self else { return }
             UIAccessibility.post(notification: .screenChanged, argument: self.view)
         }, onError: { [weak self] in
             guard let self = self else { return }
             UIAccessibility.post(notification: .screenChanged, argument: self.view)
         })
     }
    
    @IBAction func submitPaymentAction(_ sender: Any) {
       // LoadingView.show()
        self.view.isUserInteractionEnabled = false
        submitButton.setLoading()
        
        submitButton.isAccessibilityElement = true
        submitButton.accessibilityLabel = NSLocalizedString("Loading", comment: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
            UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Loading", comment: ""))
        })
        
        FirebaseUtility.logEvent(.reviewPaymentSubmit)
        FirebaseUtility.logEvent(.payment(parameters: [.submit]))
        
        if let bankOrCard = viewModel.selectedWalletItem.value?.bankOrCard {
            let temp = viewModel.selectedWalletItem.value?.isTemporary ?? false
            switch bankOrCard {
            case .bank:
                GoogleAnalytics.log(event: .eCheckOffer)
                GoogleAnalytics.log(event: .eCheckSubmit, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
            case .card:
                GoogleAnalytics.log(event: .cardOffer)
                GoogleAnalytics.log(event: .cardSubmit, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
            }
        }
        
        // Animated View
        animatedView.frame =  self.view.window?.frame ?? self.view.frame
        animatedView.frame.size.width = animatedView.frame.size.height + 150
        animatedView.layer.cornerRadius = animatedView.frame.size.height / 2
        animatedView.frame.origin = CGPoint.init(x: self.view.frame.size.width - 100, y: self.view.frame.size.height)
        animatedView.backgroundColor = UIColor.primaryColor
        self.view.window?.addSubview(animatedView)
        
        let handleError = { [weak self] (error: NetworkingError) in
            guard let self = self else { return }
            self.animatedView.removeFromSuperview()
            
          //  LoadingView.hide()
            self.submitButton.reset()
            self.view.isUserInteractionEnabled = true
            let paymentusAlertVC = UIAlertController.paymentusErrorAlertController(
                forError: error,
                walletItem: self.viewModel.selectedWalletItem.value!,
                okHandler: { [weak self] _ in
                    guard let self = self else { return }
                    if error == .walletItemIdTimeout {
                        guard let navCtl = self.navigationController else { return }
                        
                        let makePaymentVC = UIStoryboard(name: "Payment", bundle: nil)
                            .instantiateInitialViewController() as! MakePaymentViewController
                        makePaymentVC.accountDetail = self.viewModel.accountDetail.value
                        navCtl.viewControllers = [navCtl.viewControllers.first!, makePaymentVC]
                    }
                },
                callHandler: { _ in
                    UIApplication.shared.openPhoneNumberIfCan(self.viewModel.errorPhoneNumber)
                }
            )
            self.present(paymentusAlertVC, animated: true, completion: nil)
        }
        
        if viewModel.paymentId.value != nil { // Modify
            viewModel.modifyPayment(onSuccess: { [weak self] in
                if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard {
                    switch bankOrCard {
                    case .bank:
                        FirebaseUtility.logEvent(.payment(parameters: [.bank_complete]))
                    case .card:
                        FirebaseUtility.logEvent(.payment(parameters: [.card_complete]))
                    }
                }
                
               // LoadingView.hide()
                self?.submitButton.reset()
                self?.view.isUserInteractionEnabled = true
                FirebaseUtility.logEvent(.paymentNetworkComplete)
                                
                UIView.animate(withDuration: 0.4, animations: {  [weak self]  in
                    guard let self = self else {return}
                    self.animatedView.center = CGPoint.init(x: self.view.frame.size.width, y: self.view.frame.size.height)
                    }, completion: { [weak self] _ in
                        self?.animatedView.layer.cornerRadius = .zero
                        UIView.animate(withDuration: 0.18, animations: {  [weak self]  in
                            
                            self?.animatedView.frame = self?.view.window?.bounds as! CGRect
                            }, completion: { [weak self] _ in
                                self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
                                self?.animatedView.removeFromSuperview()
                        })
                })
            }, onError: { error in
                handleError(error)
            })
        } else { // Schedule
            viewModel.schedulePayment(onDuplicate: { [weak self] (errTitle, errMessage) in
               // LoadingView.hide()
                self?.submitButton.reset()
                self?.view.isUserInteractionEnabled = true
                let alertVc = UIAlertController(title: errTitle, message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
                }, onSuccess: { [weak self] in
                    self?.submitButton.setSuccess(animationCompletion: {
                        
                        self?.view.isUserInteractionEnabled = true
                        UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Complete", comment: ""))
                        
                        FirebaseUtility.logEvent(.paymentNetworkComplete)
                                                
                        if let viewModel = self?.viewModel,
                            viewModel.billingHistoryItem == nil {
                            var contactType = PaymentParameter.AlternateContact.none
                            if !viewModel.emailAddress.value.isEmpty &&
                                !viewModel.phoneNumber.value.isEmpty {
                                contactType = .both
                            } else if !viewModel.emailAddress.value.isEmpty {
                                contactType = .email
                            } else if !viewModel.phoneNumber.value.isEmpty {
                                contactType = .text
                            } else {
                                contactType = .none
                            }
                                                        
                            FirebaseUtility.logEvent(.payment(parameters: [.alternateContact(contactType)]))
                        }
                        if let bankOrCard = self?.viewModel.selectedWalletItem.value?.bankOrCard {
                            let temp = self?.viewModel.selectedWalletItem.value?.isTemporary ?? false
                            switch bankOrCard {
                            case .bank:
                                GoogleAnalytics.log(event: .eCheckComplete, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
                                FirebaseUtility.logEvent(.payment(parameters: [.bank_complete]))
                            case .card:
                                GoogleAnalytics.log(event: .cardComplete, dimensions: [.paymentTempWalletItem: temp ? "true" : "false"])
                                FirebaseUtility.logEvent(.payment(parameters: [.card_complete]))
                            }
                        }
                        
                        UIView.animate(withDuration: 0.4, animations: {  [weak self]  in
                            guard let self = self else {return}
                            self.animatedView.center = CGPoint.init(x: self.view.frame.size.width, y: self.view.frame.size.height)
                            }, completion: { [weak self] _ in
                                self?.animatedView.layer.cornerRadius = .zero
                                UIView.animate(withDuration: 0.18, animations: {  [weak self]  in
                                    self?.animatedView.frame = self?.view.window?.bounds as! CGRect
                                    }, completion: { [weak self] _ in
                                        self?.performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
                                        self?.animatedView.removeFromSuperview()
                                })
                        })
                    })
                }, onError: { error in
                    handleError(error)
            })
        }
        
    }
    
    @IBAction func onCancelPaymentPress() {
        let alertTitle = NSLocalizedString("Cancel Payment", comment: "")
        let alertMessage = NSLocalizedString("Are you sure you want to cancel this payment?", comment: "")
        let alertConfirm = NSLocalizedString("Yes", comment: "")
        let alertDeny = NSLocalizedString("No", comment: "")
        
        let confirmAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: alertDeny, style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: alertConfirm, style: .destructive, handler: { [weak self] _ in
            LoadingView.show()
            self?.viewModel.cancelPayment(onSuccess: { [weak self] in
                LoadingView.hide()
                if let confirmationNumber = self?.billingHistoryItem?.paymentID,
                   let storedConfirmationNumber = RecentPaymentsStore.shared[AccountsStore.shared.currentAccount]?.confirmationNumber,
                   confirmationNumber == storedConfirmationNumber {
                    RecentPaymentsStore.shared[AccountsStore.shared.currentAccount] = nil
                    NotificationCenter.default.post(name: .didRecievePaymentCancelConfirmation, object: nil)
                    NotificationCenter.default.post(name: .didRecievePaymentConfirmation, object: nil)
                }
                self?.dismiss(animated: true, completion: nil)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
            })
        }))
        present(confirmAlert, animated: true, completion: nil)
    }
    
}

extension TapToPayReviewPaymentViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == alternateEmailTextField.textField && (string == " ") {
            return false
        }
        
        if textField == alternateNumberTextField.textField {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 10 {
                return false
            }
            
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if length - index > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            
            textField.sendActions(for: .valueChanged) // Send rx events
            
            return false
        }
        
        return true
    }
}

// MARK: - MiniWalletViewControllerDelegate

extension TapToPayReviewPaymentViewController: MiniWalletSheetViewControllerDelegate {
    func miniWalletSheetViewController(_ miniWalletSheetViewController: MiniWalletSheetViewController, didSelect walletItem: WalletItem) {
        viewModel.selectedWalletItem.accept(walletItem)
    }
    
    func miniWalletSheetViewControllerDidSelectAddBank(_ miniWalletSheetViewController: MiniWalletSheetViewController) {
        dismissModal()
        let actionSheet = UIAlertController
            .saveToWalletActionSheet(bankOrCard: .bank, saveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .bank, temporary: false)
            }, dontSaveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .bank, temporary: true)
            })
        present(actionSheet, animated: true, completion: nil)
    }
    
    func miniWalletSheetViewControllerDidSelectAddCard(_ miniWalletSheetViewController: MiniWalletSheetViewController) {
        dismissModal()
        let actionSheet = UIAlertController
            .saveToWalletActionSheet(bankOrCard: .card, saveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .card, temporary: false)
            }, dontSaveHandler: { [weak self] _ in
                self?.presentPaymentusForm(bankOrCard: .card, temporary: true)
            })
        present(actionSheet, animated: true, completion: nil)
    }
    
}

// MARK: - PaymentusFormViewControllerDelegate

extension TapToPayReviewPaymentViewController: PaymentusFormViewControllerDelegate {
    func didAddWalletItem(_ walletItem: WalletItem) {
        viewModel.selectedWalletItem.accept(walletItem)
        fetchData(initialFetch: false)
        if !walletItem.isTemporary {
            GoogleAnalytics.log(event: walletItem.bankOrCard == .bank ? .eCheckAddNewWallet : .cardAddNewWallet, dimensions: [.otpEnabled: walletItem.isDefault ? "enabled" : "disabled"])
            let toastMessage = walletItem.bankOrCard == .bank ?
                NSLocalizedString("Bank account added", comment: "") :
                NSLocalizedString("Card added", comment: "")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.view.showToast(toastMessage)
            })
        }
    }
}

// MARK: - CalendarViewDelegate

extension TapToPayReviewPaymentViewController: CalendarViewDelegate {
    func calendarViewController(_ controller: CalendarViewController, isDateEnabled date: Date) -> Bool {
        return viewModel.shouldCalendarDateBeEnabled(date)
    }
    
    func calendarViewController(_ controller: CalendarViewController, didSelect date: Date) {
        let components = Calendar.opCo.dateComponents([.year, .month, .day], from: date)
        guard let opCoTimeDate = Calendar.opCo.date(from: components) else { return }
        viewModel.paymentDate.accept(opCoTimeDate.isInToday(calendar: .opCo) ? .now : opCoTimeDate)
    }
}
