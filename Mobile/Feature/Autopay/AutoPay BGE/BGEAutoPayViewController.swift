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

protocol BGEAutoPayViewControllerDelegate: class {
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String)
}

class BGEAutoPayViewController: UIViewController {
    
    weak var delegate: BGEAutoPayViewControllerDelegate?
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var mainStackView: UIStackView!
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
    @IBOutlet weak var enrollButton: PrimaryButton!
    @IBOutlet weak var unenrollView: UIView!
    @IBOutlet weak var unenrollButtonLabel: UILabel!
    @IBOutlet weak var unenrollButton: UIButton!
    
    var accountDetail: AccountDetail! // Passed from BillViewController
    
    lazy var viewModel: BGEAutoPayViewModel = BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(),
                                                                  walletService: ServiceFactory.createWalletService(),
                                                                  accountDetail: accountDetail)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("AutoPay", comment: "")

        let helpButton = UIBarButtonItem(image: UIImage(named: "ic_tooltip"), style: .plain, target: self, action: #selector(onLearnMorePress))
        navigationItem.rightBarButtonItem = helpButton
        
    viewModel.submitButtonEnabled.drive(enrollButton.rx.isEnabled).disposed(by: disposeBag)

        styleViews()
        setupBindings()
        accessibilitySetup()
        
        switch viewModel.initialEnrollmentStatus.value {
        case .unenrolled:
            GoogleAnalytics.log(event: .autoPayEnrollOffer)
        case .enrolled:
            termsStackView.isHidden = true
            termsStackView.alpha = 0
        }
        
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
        }, onError: { [weak self] _ in
            guard let self = self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.view)
        })
        
        if accountDetail.isAutoPay {
            enrollButton.isHidden = true
        } else {
            unenrollView.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if termsStackView.isHidden &&
            (viewModel.userDidChangeSettings.value || viewModel.userDidChangeBankAccount.value) {
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.termsStackView.isHidden = false
                self?.termsStackView.alpha = 1
            }
        }
    }
    
    private func accessibilitySetup() {
        bankAccountButton.isAccessibilityElement = true
        settingsButton.isAccessibilityElement = true
    }
    
    private func styleViews() {
        selectBankAccountLabel.textColor = .deepGray
        selectBankAccountLabel.font = OpenSans.semibold.of(textStyle: .caption2)
        selectBankAccountLabel.text = NSLocalizedString("Bank Account", comment: "")
        
        bankAccountButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        bankAccountButton.backgroundColorOnPress = .softGray
        
        bankAccountButtonSelectLabel.textColor = .deepGray
        bankAccountButtonSelectLabel.font = SystemFont.regular.of(textStyle: .callout)
        bankAccountButtonSelectLabel.text = NSLocalizedString("Select Bank Account", comment: "")
        
        bankAccountButtonAccountNumberLabel.textColor = .deepGray
        bankAccountButtonAccountNumberLabel.font = SystemFont.regular.of(textStyle: .callout)
        bankAccountButtonNicknameLabel.textColor = .middleGray
        bankAccountButtonNicknameLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        settingsButton.fullyRoundCorners(diameter: 20, borderColor: .accentGray, borderWidth: 1)
        settingsButton.backgroundColorOnPress = .softGray
//        settingsButton.label.lineBreakMode = .byTruncatingMiddle
        
        termsLabel.textColor = .deepGray
        termsLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        termsLabel.setLineHeight(lineHeight: 25)
        termsLabel.isAccessibilityElement = false
        termsButton.setTitleColor(.actionBlue, for: .normal)
        termsButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .subheadline)
        termsSwitch.accessibilityLabel = termsLabel.text
        
        bottomLabel.textColor = .deepGray
        bottomLabel.text = viewModel.bottomLabelText
        bottomLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        settingsTitleLabel.textColor = .deepGray
        settingsTitleLabel.font = OpenSans.semibold.of(textStyle: .caption2)
        
        settingsLabel.textColor = .deepGray
        settingsLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        settingsDescriptionLabel.textColor = .middleGray
        settingsDescriptionLabel.font = SystemFont.regular.of(textStyle: .caption1)
        
        unenrollButtonLabel.textColor = .deepGray
        unenrollButtonLabel.font = SystemFont.regular.of(textStyle: .callout)
        unenrollButton.setTitleColor(.actionBlue, for: .normal)
        unenrollButton.titleLabel?.font = SystemFont.bold.of(textStyle: .callout)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        errorLabel.textColor = .deepGray
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }
    
    func setupBindings() {
        viewModel.shouldShowContent.not().drive(mainStackView.rx.isHidden).disposed(by: disposeBag)
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

    @objc func onSubmitPress(submitButton: UIBarButtonItem) {
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
            self.viewModel.unenroll(onSuccess: { [weak self] in
                LoadingView.hide()
                GoogleAnalytics.log(event: .autoPayUnenrollComplete)
                
                guard let self = self else { return }
                let title = NSLocalizedString("Unenrolled from AutoPay", comment: "")
                let description = NSLocalizedString("You have successfully unenrolled from AutoPay. If you have an upcoming automatic payment for your current balance, it may be viewed or canceled in Bill & Payment Activity.", comment: "")
                let infoModal = InfoModalViewController(title: title,
                                                        image: #imageLiteral(resourceName: "img_confirmation"),
                                                        description: description)
                { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
                
                self.navigationController?.present(infoModal, animated: true)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                self?.showErrorAlert(message: errMessage)
            })
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func enroll() {
        GoogleAnalytics.log(event: .autoPayEnrollSubmit)
        if viewModel.userDidChangeSettings.value {
            GoogleAnalytics.log(event: .autoPayModifySettingSubmit)
        }
        
        viewModel.enroll(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            
            GoogleAnalytics.log(event: .autoPayEnrollComplete)
            if self.viewModel.userDidChangeSettings.value {
                GoogleAnalytics.log(event: .autoPayModifySettingCompleteNew)
            }
            
            let title = NSLocalizedString("Enrolled in AutoPay", comment: "")
            let description: String
            if let netDueAmount = self.accountDetail.billingInfo.netDueAmount, netDueAmount > 0 {
                let formatText = NSLocalizedString("You are successfully enrolled in AutoPay and it will begin with your next bill. Upon payment you will receive a payment confirmation for your records.", comment: "")
                description = String.localizedStringWithFormat(formatText, netDueAmount.currencyString)
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
            LoadingView.hide()
            self?.showErrorAlert(message: errMessage)
        })
    }
    
    private func updateSettings() {
        GoogleAnalytics.log(event: .autoPayModifySettingSubmit)
        viewModel.update(onSuccess: { [weak self] in
            LoadingView.hide()
            GoogleAnalytics.log(event: .autoPayModifySettingComplete)
            
            guard let self = self else { return }
            self.delegate?.BGEAutoPayViewController(self, didUpdateWithToastMessage: NSLocalizedString("AutoPay changes saved", comment: ""))
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
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
        let infoModal = InfoModalViewController(title: NSLocalizedString("What is AutoPay?", comment: ""), image: #imageLiteral(resourceName: "img_autopaymodal"), description: viewModel.learnMoreDescriptionText)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }

    @IBAction func onSelectBankAccountPress() {
        guard let miniWalletVC = UIStoryboard(name: "MiniWalletSheet", bundle: .main).instantiateInitialViewController() as? MiniWalletSheetViewController else { return }
        miniWalletVC.modalPresentationStyle = .overCurrentContext
        
        miniWalletVC.viewModel.walletItems = self.viewModel.walletItems ?? []
        miniWalletVC.accountDetail = viewModel.accountDetail
        miniWalletVC.isCreditCardDisabled = true
        miniWalletVC.allowTemporaryItems = false
        miniWalletVC.delegate = self

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
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension BGEAutoPayViewController: MiniWalletSheetViewControllerDelegate {
    func miniWalletSheetViewController(_ miniWalletSheetViewController: MiniWalletSheetViewController, didSelect walletItem: WalletItem) {
        guard walletItem != viewModel.selectedWalletItem.value else { return }
        viewModel.userDidChangeBankAccount.value = true
        viewModel.selectedWalletItem.value = walletItem
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
        viewModel.userDidChangeBankAccount.value = true
        viewModel.selectedWalletItem.value = walletItem
    }
}

extension BGEAutoPayViewController: BGEAutoPaySettingsViewControllerDelegate {
    func didUpdateSettings(amountToPay: AmountType, amountNotToExceed: Double, whenToPay: BGEAutoPayViewModel.PaymentDateType, numberOfDaysBeforeDueDate: Int) {
        if viewModel.amountToPay.value != amountToPay ||
            (viewModel.amountToPay.value == .upToAmount && viewModel.amountNotToExceed.value != amountNotToExceed) ||
            viewModel.whenToPay.value != whenToPay ||
            (viewModel.whenToPay.value == .beforeDueDate && viewModel.numberOfDaysBeforeDueDate.value != numberOfDaysBeforeDueDate) {
            viewModel.userDidChangeSettings.value = true
        }
        
        viewModel.amountToPay.value = amountToPay
        viewModel.amountNotToExceed.value = amountNotToExceed
        viewModel.whenToPay.value = whenToPay
        viewModel.numberOfDaysBeforeDueDate.value = numberOfDaysBeforeDueDate
    }
}
