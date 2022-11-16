//
//  BGEAutoPayViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import UIKit

protocol BGEAutoPayViewControllerDelegate: class {
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String)
}

class BGEAutoPayViewController: UIViewController {
    
    weak var delegate: BGEAutoPayViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    private var backButton: UIBarButtonItem?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var selectBankAccountLabel: UILabel!
    
    @IBOutlet weak var bankAccountButton: ButtonControl!
    @IBOutlet weak var bankAccountButtonIcon: UIImageView!
    @IBOutlet weak var bankAccountButtonSelectLabel: UILabel!
    @IBOutlet weak var bankAccountButtonAccountNumberLabel: UILabel!
    @IBOutlet weak var bankAccountButtonNicknameLabel: UILabel!
    
    @IBOutlet weak var settingsButton: ButtonControl!
    @IBOutlet weak var settingsTitleLabel: UILabel!
    @IBOutlet weak var settingsLabel: UILabel!
    @IBOutlet weak var settingsDescriptionLabel: UILabel!
    
    @IBOutlet weak var termsStackView: UIStackView!
    @IBOutlet weak var termsSwitch: Checkbox!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var termsButton: UIButton!
    
    @IBOutlet weak var bottomLabelView: UIView!
    @IBOutlet weak var bottomLabel: UILabel!
    
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var submitButton: PrimaryButton!
    @IBOutlet weak var unenrollView: UIView!
    @IBOutlet weak var unenrollButtonLabel: UILabel!
    @IBOutlet weak var unenrollButton: UIButton!
    
    var accountDetail: AccountDetail! // Passed from BillViewController
    
    lazy var viewModel: BGEAutoPayViewModel = BGEAutoPayViewModel( accountDetail: accountDetail)
    let billingHistoryVC = BillingHistoryViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("AutoPay", comment: "")
        
        let helpButton = UIBarButtonItem(image: UIImage(named: "ic_tooltip"), style: .plain, target: self, action: #selector(onLearnMorePress))
        helpButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        navigationItem.rightBarButtonItem = helpButton
        
        viewModel.submitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        styleViews()
        setupBindings()
        accessibilitySetup()
        
        switch viewModel.initialEnrollmentStatus.value {
        case .unenrolled:
            GoogleAnalytics.log(event: .autoPayEnrollOffer)
        case .enrolled:
            termsStackView.isHidden = true
        }
        
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
        })
        
        FirebaseUtility.logEvent(.autoPayStart)
        
        if accountDetail.isAutoPay {
            submitButton.isHidden = true
        } else {
            unenrollView.isHidden = true
        }
    }
    
    // Add back Button
    private func addCustomBackButton() {
        backButton = UIBarButtonItem(image: UIImage(named: "ic_back"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backAction))
        backButton?.accessibilityLabel = NSLocalizedString("Back", comment: "")
        navigationItem.setLeftBarButton(backButton, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.setHidesBackButton(true, animated: true)
    }
    
    // MARK: - Action
    
    @objc func backAction() {
        if viewModel.userPerformedAnyChanges {
            let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
            { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            presentAlert(title: NSLocalizedString("Unsaved Changes", comment: ""),
                         message: NSLocalizedString("You have unsaved changes - are you sure you want to exit this screen without saving your changes?", comment: ""),
                         style: .alert,
                         actions: [cancelAction, exitAction])
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if termsStackView.isHidden &&
            (viewModel.userDidChangeSettings.value || viewModel.userDidChangeBankAccount.value) {
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.termsStackView.isHidden = false
            }
        }
    }
    
    private func accessibilitySetup() {
        bankAccountButton.isAccessibilityElement = true
        settingsButton.isAccessibilityElement = true
    }
    
    private func styleViews() {
        addCustomBackButton()
        selectBankAccountLabel.textColor = .neutralDark
        selectBankAccountLabel.font = .caption2Semibold
        selectBankAccountLabel.text = NSLocalizedString("Bank Account", comment: "")
        
        bankAccountButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        bankAccountButton.backgroundColorOnPress = .softGray
        
        bankAccountButtonSelectLabel.textColor = .neutralDark
        bankAccountButtonSelectLabel.font = .callout
        bankAccountButtonSelectLabel.text = NSLocalizedString("Select Bank Account", comment: "")
        
        bankAccountButtonAccountNumberLabel.textColor = .neutralDark
        bankAccountButtonAccountNumberLabel.font = .callout
        bankAccountButtonNicknameLabel.textColor = .middleGray
        bankAccountButtonNicknameLabel.font = .caption1
        
        settingsButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        settingsButton.backgroundColorOnPress = .softGray
        
        termsLabel.textColor = .neutralDark
        termsLabel.font = .subheadline
        termsLabel.setLineHeight(lineHeight: 25)
        termsLabel.isAccessibilityElement = false
        termsButton.setTitleColor(.primaryBlue, for: .normal)
        termsButton.titleLabel?.font = .subheadlineSemibold
        termsSwitch.accessibilityLabel = termsLabel.text
        
        bottomLabel.textColor = .neutralDark
        let bottomLabelText = viewModel.bottomLabelText
        bottomLabel.text = bottomLabelText
        bottomLabel.font = .footnote
        
        settingsTitleLabel.textColor = .neutralDark
        settingsTitleLabel.font = .caption2Semibold
        
        settingsLabel.textColor = .neutralDark
        settingsLabel.font = .subheadline
        
        settingsDescriptionLabel.textColor = .middleGray
        settingsDescriptionLabel.font = .caption1
        
        unenrollButtonLabel.textColor = .neutralDark
        unenrollButtonLabel.font = .callout
        unenrollButton.setTitleColor(.primaryBlue, for: .normal)
        unenrollButton.titleLabel?.font = .callout
        
        errorLabel.font = .subheadline
        errorLabel.textColor = .neutralDark
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }
    
    func setupBindings() {
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowContent.not().drive(stickyFooterView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isLoading.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowWalletItem.map(!).drive(bankAccountButtonAccountNumberLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowWalletItem.map(!).drive(bankAccountButtonNicknameLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowWalletItem.drive(bankAccountButtonSelectLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.bankAccountButtonImage.drive(bankAccountButtonIcon.rx.image).disposed(by: disposeBag)
        viewModel.walletItemAccountNumberText.drive(bankAccountButtonAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.walletItemNicknameText.drive(bankAccountButtonNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(bankAccountButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        viewModel.settingsButtonAmountText.drive(settingsLabel.rx.text).disposed(by: disposeBag)
        viewModel.settingsButtonDaysBeforeText.drive(settingsDescriptionLabel.rx.text).disposed(by: disposeBag)
        
        viewModel.settingsButtonA11yLabel
            .drive(settingsButton.rx.accessibilityLabel)
            .disposed(by: disposeBag)
        
        viewModel.showUnenrollFooter.not().drive(unenrollView.rx.isHidden).disposed(by: disposeBag)
        
        termsSwitch.rx.isChecked.asDriver().drive(viewModel.userDidReadTerms).disposed(by: disposeBag)
    }
    
    private func showUpdateButton() {
        guard accountDetail.isAutoPay else { return }
        
        termsStackView.isHidden = false
        
        submitButton.isHidden = false
        submitButton.setTitle(NSLocalizedString("Update AutoPay", comment: ""), for: .normal)
        submitButton.accessibilityLabel = NSLocalizedString("Update AutoPay", comment: "")
        unenrollView.isHidden = true
    }
    
    @IBAction func onSubmitPress(_ sender: Any) {
        guard submitButton.isEnabled else { return }
        
        LoadingView.show()
        
        switch viewModel.initialEnrollmentStatus.value {
        case .unenrolled:
            enroll()
        case .enrolled:
            updateSettings()
        }
    }
    
    @IBAction func onUnenrollPress() {
        let alert = UIAlertController(title: NSLocalizedString("Unenroll from AutoPay", comment: ""), message: NSLocalizedString("You will be responsible for making separate one-time payments to cover your future bills after unenrolling from AutoPay. Any upcoming automatic payment for your current bill will not be canceled by unenrolling in AutoPay. To cancel an upcoming payment, visit the Bill & Payment Activity page.", comment: ""), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Unenroll", comment: ""), style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            LoadingView.show()
            GoogleAnalytics.log(event: .autoPayUnenrollOffer)
            
            FirebaseUtility.logEvent(.autoPay(parameters: [.unenroll_start]))
            
            FirebaseUtility.logEvent(.autoPaySubmit)
            
            self.viewModel.unenroll(onSuccess: { [weak self] in
                LoadingView.hide()
                GoogleAnalytics.log(event: .autoPayUnenrollComplete)
                
                FirebaseUtility.logEvent(.autoPay(parameters: [.unenroll_complete]))
                
                FirebaseUtility.logEvent(.autoPayNetworkComplete)
                
                guard let self = self else { return }
                let title = NSLocalizedString("Unenrolled from AutoPay", comment: "")
                let description = NSLocalizedString("You have successfully unenrolled from AutoPay. If you have an upcoming automatic payment for your current balance, it may be viewed or canceled in Bill & Payment Activity.", comment: "")
                let modalBtnLabel = "View Bill & Payment Activity"
                let infoModal = InfoModalViewController(title: title,
                                                        image: #imageLiteral(resourceName: "img_confirmation"),
                                                        description: description,
                                                        modalBtnLabel: modalBtnLabel,
                                                        onClose: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }, onBtnClick: { [weak self] in
                    let storyboard = UIStoryboard(name: "Bill", bundle: nil)
                    let billingHistoryVC = storyboard.instantiateViewController(withIdentifier: "billingHistory") as! BillingHistoryViewController
                    billingHistoryVC.viewModel.accountDetail = self?.viewModel.accountDetail
                    billingHistoryVC.viewModel.viewingMoreActivity = false
                    self?.navigationController?.pushViewController(billingHistoryVC, animated: true)
                    
                })
                
                self.navigationController?.present(infoModal, animated: true)
                }, onError: { [weak self] errMessage in
                    FirebaseUtility.logEvent(.autoPay(parameters: [.network_submit_error]))
                    
                    LoadingView.hide()
                    self?.showErrorAlert(message: errMessage)
            })
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func enroll() {
        GoogleAnalytics.log(event: .autoPayEnrollSubmit)
        FirebaseUtility.logEvent(.autoPay(parameters: [.enroll_start]))
        FirebaseUtility.logEvent(.autoPaySubmit)
        
        viewModel.enroll(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            
            GoogleAnalytics.log(event: .autoPayEnrollComplete)
            
            FirebaseUtility.logEvent(.autoPay(parameters: [.enroll_complete]))
            
            FirebaseUtility.logEvent(.autoPayNetworkComplete)
            
            if self.viewModel.userDidChangeSettings.value {
                GoogleAnalytics.log(event: .autoPayModifySettingCompleteNew)
            }
            
            let title = NSLocalizedString("Enrolled in AutoPay", comment: "")
            let description: String
            if let netDueAmount = self.accountDetail.billingInfo.netDueAmount, netDueAmount > 0 {
                let formatText = "You are successfully enrolled in AutoPay and will begin with your next bill. You must submit a separate payment for your account balance of %@. Any past due amount is due immediately.".localized()
                description = String(format: formatText, netDueAmount.currencyString)
            } else {
                description = NSLocalizedString("You are successfully enrolled in AutoPay and will begin with your next bill. Upon payment you will receive a payment confirmation for your records.", comment: "")
            }
            let infoModal = InfoModalViewController(title: title,
                                                    image: #imageLiteral(resourceName: "img_confirmation"),
                                                    description: description)
            { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            
            self.navigationController?.present(infoModal, animated: true)
            }, onError: { [weak self] errMessage in
                FirebaseUtility.logEvent(.autoPay(parameters: [.network_submit_error]))
                
                LoadingView.hide()
                self?.showErrorAlert(message: errMessage)
        })
    }
    
    private func updateSettings() {
        GoogleAnalytics.log(event: .autoPayModifySettingSubmit)
        FirebaseUtility.logEvent(.autoPaySubmit)
        FirebaseUtility.logEvent(.autoPay(parameters: [.modify_start]))
        
        viewModel.update(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .autoPayModifySettingComplete)
            
            FirebaseUtility.logEvent(.autoPay(parameters: [.settings_changed]))
            FirebaseUtility.logEvent(.autoPay(parameters: [.modify_complete]))
            
            FirebaseUtility.logEvent(.autoPayNetworkComplete)
            
            guard let self = self else { return }
            self.delegate?.BGEAutoPayViewController(self, didUpdateWithToastMessage: NSLocalizedString("AutoPay changes saved", comment: ""))
            self.navigationController?.popViewController(animated: true)
            }, onError: { [weak self] errMessage in
                FirebaseUtility.logEvent(.autoPay(parameters: [.network_submit_error]))
                
                LoadingView.hide()
                self?.showErrorAlert(message: errMessage)
        })
    }
    
    private func showErrorAlert(message: String) {
        let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: message, preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(alertVc, animated: true, completion: nil)
    }
    
    @objc
    func onLearnMorePress() {
        FirebaseUtility.logEvent(.autoPay(parameters: [.learn_more]))
        
        let infoModal = InfoModalViewController(title: NSLocalizedString("What is AutoPay?", comment: ""), image: #imageLiteral(resourceName: "img_autopaymodal"), description: viewModel.learnMoreDescriptionText)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    @IBAction func onSelectBankAccountPress() {
        guard let miniWalletVC = UIStoryboard(name: "MiniWalletSheet", bundle: .main).instantiateInitialViewController() as? MiniWalletSheetViewController else { return }
        miniWalletVC.modalPresentationStyle = .overCurrentContext
        
        miniWalletVC.viewModel.walletItems = self.viewModel.walletItems ?? []
        miniWalletVC.accountDetail = viewModel.accountDetail
        
        if let selectedItem = self.viewModel.selectedWalletItem.value {
            miniWalletVC.viewModel.selectedWalletItem = selectedItem
            if selectedItem.isTemporary {
                miniWalletVC.viewModel.temporaryWalletItem = selectedItem
            } else if selectedItem.isEditingItem {
                miniWalletVC.viewModel.editingWalletItem = selectedItem
            }
        }
        
        miniWalletVC.isCreditCardDisabled = true
        miniWalletVC.allowTemporaryItems = false
        miniWalletVC.delegate = self
        miniWalletVC.titleText = NSLocalizedString("Select Bank Account", comment: "")
        miniWalletVC.tableHeaderText = nil
        
        if accountDetail.isAutoPay {
            GoogleAnalytics.log(event: .autoPayModifyWallet)
        } else {
            GoogleAnalytics.log(event: .autoPayEnrollSelectBank)
        }
        
        self.present(miniWalletVC, animated: false, completion: nil)
    }
    
    @IBAction func onSettingsPress() {
        performSegue(withIdentifier: "bgeAutoPaySettingsSegue", sender: self)
    }
    
    @IBAction func onTermsConditionsPress() {
        FirebaseUtility.logEvent(.autoPay(parameters: [.terms]))
        
        let url = URL(string: "https://ipn2.paymentus.com/biller/stde/terms-conditions-autopay-exln.html")!
        let tacModal = WebViewController(title: NSLocalizedString("Terms and Conditions", comment: ""), url: url)
        navigationController?.present(tacModal, animated: true, completion: nil)
    }
    
    private func presentPaymentusForm(bankOrCard: BankOrCard, temporary: Bool) {
        let paymentusVC = PaymentusFormViewController(bankOrCard: bankOrCard,
                                                      temporary: temporary,
                                                      isWalletEmpty: (viewModel.walletItems ?? []).isEmpty)
        paymentusVC.delegate = self
        let largeTitleNavController = LargeTitleNavigationController(rootViewController: paymentusVC)
        present(largeTitleNavController, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navCtl = segue.destination as? UINavigationController,
            let settingsVC = navCtl.viewControllers.first as? BGEAutoPaySettingsViewController {
            settingsVC.viewModel = BGEAutoPaySettingsViewModel(accountDetail: accountDetail,
                                                               initialEnrollmentStatus: viewModel.initialEnrollmentStatus.value,
                                                               amountToPay: viewModel.amountToPay.value,
                                                               amountNotToExceed: viewModel.amountNotToExceed.value,
                                                               whenToPay: viewModel.whenToPay.value,
                                                               numberOfDaysBeforeDueDate: viewModel.numberOfDaysBeforeDueDate.value)
            settingsVC.delegate = self
        }
    }
    
}

extension BGEAutoPayViewController: MiniWalletSheetViewControllerDelegate {
    func miniWalletSheetViewController(_ miniWalletSheetViewController: MiniWalletSheetViewController, didSelect walletItem: WalletItem) {
        guard walletItem != viewModel.selectedWalletItem.value else { return }
        viewModel.userDidChangeBankAccount.accept(true)
        viewModel.selectedWalletItem.accept(walletItem)
        
        showUpdateButton()
        
        FirebaseUtility.logEvent(.autoPay(parameters: [.modify_bank]))
        GoogleAnalytics.log(event: .autoPayModifyBankComplete)
    }
    
    func miniWalletSheetViewControllerDidSelectAddBank(_ miniWalletSheetViewController: MiniWalletSheetViewController) {
        presentPaymentusForm(bankOrCard: .bank, temporary: false)
    }
    
    func miniWalletSheetViewControllerDidSelectAddCard(_ miniWalletSheetViewController: MiniWalletSheetViewController) {
        // Will never get called because we pass `creditCardsDisabled = true` from this VC
    }
}

extension BGEAutoPayViewController: PaymentusFormViewControllerDelegate {
    func didAddWalletItem(_ walletItem: WalletItem) {
        viewModel.userDidChangeBankAccount.accept(true)
        viewModel.selectedWalletItem.accept(walletItem)
        
        showUpdateButton()
        
        FirebaseUtility.logEvent(.autoPay(parameters: [.modify_bank]))
    }
}

extension BGEAutoPayViewController: BGEAutoPaySettingsViewControllerDelegate {
    func didUpdateSettings(amountToPay: AmountType, amountNotToExceed: Double, whenToPay: BGEAutoPayViewModel.PaymentDateType, numberOfDaysBeforeDueDate: Int) {
        if viewModel.amountToPay.value != amountToPay ||
            (viewModel.amountToPay.value == .upToAmount && viewModel.amountNotToExceed.value != amountNotToExceed) ||
            viewModel.whenToPay.value != whenToPay ||
            (viewModel.whenToPay.value == .beforeDueDate && viewModel.numberOfDaysBeforeDueDate.value != numberOfDaysBeforeDueDate) {
            viewModel.userDidChangeSettings.accept(true)
        }
        
        viewModel.amountToPay.accept(amountToPay)
        viewModel.amountNotToExceed.accept(amountNotToExceed)
        viewModel.whenToPay.accept(whenToPay)
        viewModel.numberOfDaysBeforeDueDate.accept(numberOfDaysBeforeDueDate)
        
        showUpdateButton()
    }
}
