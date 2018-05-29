//
//  BGEAutoPayViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol BGEAutoPayViewControllerDelegate: class {
    func BGEAutoPayViewController(_ BGEAutoPayViewController: BGEAutoPayViewController, didUpdateWithToastMessage message: String)
}

class BGEAutoPayViewController: UIViewController {
    
    weak var delegate: BGEAutoPayViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var learnMoreButton: ButtonControl!
    @IBOutlet weak var learnMoreButtonLabel: UILabel!
    
    @IBOutlet weak var enrollmentSwitchView: UIView!
    @IBOutlet weak var enrollmentStatusLabel: UILabel!
    @IBOutlet weak var enrollmentSwitch: Switch!
    
    @IBOutlet weak var topSpacerView: UIView!
    
    @IBOutlet weak var expirationLabel: UILabel!
    
    @IBOutlet weak var selectBankAccountLabel: UILabel!
    
    @IBOutlet weak var bankAccountContainerStack: UIStackView!
    @IBOutlet weak var enrolledPaymentAccountLabel: UILabel!
    @IBOutlet weak var bankAccountButton: ButtonControl!
    @IBOutlet weak var bankAccountButtonIcon: UIImageView!
    @IBOutlet weak var bankAccountButtonSelectLabel: UILabel!
    @IBOutlet weak var bankAccountButtonAccountNumberLabel: UILabel!
    @IBOutlet weak var bankAccountButtonNicknameLabel: UILabel!
    
    @IBOutlet weak var settingsButtonView: UIView!
    @IBOutlet weak var settingsButton: ButtonControl!
    @IBOutlet weak var settingsButtonLabel: UILabel!
    
    @IBOutlet weak var bottomLabelView: UIView!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var accountDetail: AccountDetail! // Passed from BillViewController
    
    lazy var viewModel: BGEAutoPayViewModel = { BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: self.accountDetail) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("AutoPay", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        viewModel.submitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        enrollmentStatusLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        learnMoreButtonLabel.textColor = .actionBlue
        learnMoreButtonLabel.text = NSLocalizedString("Learn more about AutoPay", comment: "")
        learnMoreButtonLabel.font = SystemFont.semibold.of(textStyle: .headline)
        learnMoreButtonLabel.numberOfLines = 0
        
        expirationLabel.textColor = .blackText
        
        selectBankAccountLabel.textColor = .blackText
        selectBankAccountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        selectBankAccountLabel.text = NSLocalizedString("Select a bank account to enroll in AutoPay.", comment: "")
        
        enrolledPaymentAccountLabel.textColor = .deepGray
        enrolledPaymentAccountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        enrolledPaymentAccountLabel.text = NSLocalizedString("AutoPay Payment Account:", comment: "")
        
        bankAccountButton.backgroundColorOnPress = .softGray
        bankAccountButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        
        bankAccountButtonSelectLabel.font = SystemFont.medium.of(textStyle: .title1)
        bankAccountButtonSelectLabel.textColor = .blackText
        bankAccountButtonSelectLabel.text = NSLocalizedString("Select Bank Account", comment: "")
        
        bankAccountButtonAccountNumberLabel.textColor = .blackText
        bankAccountButtonNicknameLabel.textColor = .middleGray
        
        bottomLabelView.backgroundColor = .softGray
        bottomLabel.textColor = .blackText
        bottomLabel.text = NSLocalizedString("Your recurring payment will apply to the next BGE bill you receive. You will need to submit a payment for your current BGE bill if you have not already done so.", comment: "")
        bottomLabel.font = OpenSans.regular.of(textStyle: .footnote)
        
        settingsButtonLabel.textColor = .actionBlue
        settingsButtonLabel.font = SystemFont.semibold.of(textStyle: .headline)
        settingsButtonLabel.text = NSLocalizedString("AutoPay Settings", comment: "")
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        setupBindings()
        accessibilitySetup()
    
        viewModel.getAutoPayInfo(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.view)
        }, onError: { [weak self] _ in
            guard let `self` = self else { return }
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.view)
        })
        
        if viewModel.initialEnrollmentStatus.value == .unenrolled {
            Analytics().logScreenView(AnalyticsPageView.AutoPayEnrollOffer.rawValue)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
        
        if viewModel.initialEnrollmentStatus.value == .enrolled {
            selectBankAccountLabel.isHidden = true
            topSpacerView.isHidden = true
        } else {
            enrollmentSwitchView.isHidden = true
            enrolledPaymentAccountLabel.isHidden = true
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = gradientView.bounds
    }
    
    private func accessibilitySetup() {
        learnMoreButton.isAccessibilityElement = true
        learnMoreButton.accessibilityLabel = learnMoreButtonLabel.text
        bankAccountButton.isAccessibilityElement = true
        settingsButton.isAccessibilityElement = true
        settingsButton.accessibilityLabel = settingsButtonLabel.text
        
        enrollmentSwitch.accessibilityLabel = "Enrollment status: "
        enrollmentStatusLabel.isAccessibilityElement = false
    }
    
    func setupBindings() {
        viewModel.shouldShowContent.not().drive(scrollView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowContent.not().drive(gradientView.rx.isHidden).disposed(by: disposeBag)
        viewModel.isFetchingAutoPayInfo.asDriver().map(!).drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.showBottomLabel.not().drive(bottomLabelView.rx.isHidden).disposed(by: disposeBag)
        viewModel.showBottomLabel.asObservable().subscribe(onNext: { [weak self] show in
            self?.view.backgroundColor = show ? .softGray : .white
        }).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowWalletItem.map(!).drive(bankAccountButtonAccountNumberLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowWalletItem.map(!).drive(bankAccountButtonNicknameLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowWalletItem.drive(bankAccountButtonSelectLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.bankAccountButtonImage.drive(bankAccountButtonIcon.rx.image).disposed(by: disposeBag)
        viewModel.walletItemAccountNumberText.drive(bankAccountButtonAccountNumberLabel.rx.text).disposed(by: disposeBag)
        viewModel.walletItemNicknameText.drive(bankAccountButtonNicknameLabel.rx.text).disposed(by: disposeBag)
        viewModel.selectedWalletItemA11yLabel.drive(bankAccountButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        viewModel.enrollSwitchValue.asDriver().drive(enrollmentSwitch.rx.isOn).disposed(by: disposeBag)
        enrollmentSwitch.rx.isOn.asDriver().drive(viewModel.enrollSwitchValue).disposed(by: disposeBag)
        
        viewModel.isUnenrolling.drive(bankAccountContainerStack.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowSettingsButton.map(!).drive(settingsButtonView.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.expiredReason.asDriver().drive(expirationLabel.rx.text).disposed(by: disposeBag)
        viewModel.shouldShowExpiredReason.map(!).drive(expirationLabel.rx.isHidden).disposed(by: disposeBag)
    }
    
    @objc func onCancelPress() {
        if viewModel.initialEnrollmentStatus.value == .enrolled && (viewModel.userDidChangeSettings.value || viewModel.userDidChangeBankAccount.value) {
            let alertVc = UIAlertController(title: NSLocalizedString("Unsaved Changes", comment: ""), message: NSLocalizedString("You have unsaved changes - are you sure you want to exit this screen without saving your changes? Return to the AutoPay screen and Tap \"Submit\" to save your AutoPay changes.", comment: ""), preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .destructive, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func onSubmitPress() {
        LoadingView.show()
        
        if viewModel.initialEnrollmentStatus.value == .unenrolled {
            Analytics().logScreenView(AnalyticsPageView.AutoPayEnrollSubmit.rawValue)
            if viewModel.userDidChangeSettings.value {
                Analytics().logScreenView(AnalyticsPageView.AutoPayModifySettingSubmit.rawValue)
            }
            
            viewModel.enrollOrUpdate(onSuccess: { [weak self] in
                LoadingView.hide()
                Analytics().logScreenView(AnalyticsPageView.AutoPayEnrollComplete.rawValue)
                if self?.viewModel.userDidChangeSettings.value ?? false {
                    Analytics().logScreenView(AnalyticsPageView.AutoPayModifySettingCompleteNew.rawValue)
                }
                
                guard let `self` = self else { return }
                self.delegate?.BGEAutoPayViewController(self, didUpdateWithToastMessage: NSLocalizedString("Enrolled in AutoPay", comment: ""))
                self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    
                    guard let `self` = self else { return }
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
            })
        } else if viewModel.initialEnrollmentStatus.value == .enrolled {
            if viewModel.enrollSwitchValue.value { // Update
                Analytics().logScreenView(AnalyticsPageView.AutoPayModifySettingSubmit.rawValue)
                viewModel.enrollOrUpdate(update: true, onSuccess: { [weak self] in
                    LoadingView.hide()
                    Analytics().logScreenView(AnalyticsPageView.AutoPayModifySettingComplete.rawValue)
                    
                    guard let `self` = self else { return }
                    self.delegate?.BGEAutoPayViewController(self, didUpdateWithToastMessage: NSLocalizedString("AutoPay changes saved", comment: ""))
                    self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    
                    guard let `self` = self else { return }
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
                })
            } else { // Unenroll
                Analytics().logScreenView(AnalyticsPageView.AutoPayUnenrollOffer.rawValue)
                viewModel.unenroll(onSuccess: { [weak self] in
                    LoadingView.hide()
                    Analytics().logScreenView(AnalyticsPageView.AutoPayUnenrollComplete.rawValue)
                    
                    guard let `self` = self else { return }
                    self.delegate?.BGEAutoPayViewController(self, didUpdateWithToastMessage: NSLocalizedString("Unenrolled from AutoPay", comment: ""))
                    self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self] errMessage in
                    LoadingView.hide()
                    
                    guard let `self` = self else { return }
                    let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertVc, animated: true, completion: nil)
                })
            }
        }

    }
    
    @IBAction func onLearnMorePress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("What is AutoPay?", comment: ""), image: #imageLiteral(resourceName: "img_autopaymodal"), description: NSLocalizedString("With AutoPay, your payment is automatically deducted from your bank account. Upon payment, you will receive a payment confirmation for your records.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }

    @IBAction func onSelectBankAccountPress() {
        let miniWalletVC = UIStoryboard(name: "Wallet", bundle: nil).instantiateViewController(withIdentifier: "miniWallet") as! MiniWalletViewController
        miniWalletVC.tableHeaderLabelText = NSLocalizedString("Select a bank account to enroll in AutoPay.", comment: "")
        miniWalletVC.accountDetail = viewModel.accountDetail
        miniWalletVC.creditCardsDisabled = true
        miniWalletVC.delegate = self
        if accountDetail.isAutoPay {
            Analytics().logScreenView(AnalyticsPageView.AutoPayModifyWallet.rawValue)
        } else {
            Analytics().logScreenView(AnalyticsPageView.AutoPayEnrollSelectBank.rawValue)
        }
        navigationController?.pushViewController(miniWalletVC, animated: true)
    }
    
    @IBAction func onSettingsPress() {
        performSegue(withIdentifier: "bgeAutoPaySettingsSegue", sender: self)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? BGEAutoPaySettingsViewController {
            vc.viewModel = viewModel
        }
    }
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension BGEAutoPayViewController: MiniWalletViewControllerDelegate {
    
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem) {
        if let currWalletItem = viewModel.selectedWalletItem.value {
            if walletItem != currWalletItem {
                viewModel.userDidChangeBankAccount.value = true
            }
        }
        viewModel.selectedWalletItem.value = walletItem
    }
}
