//
//  BGEAutoPayViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class BGEAutoPayViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var stickyBottomView: UIView!
    @IBOutlet weak var stickyBottomLabel: UILabel!
    @IBOutlet weak var stickyBottomViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var learnMoreButton: ButtonControl!
    @IBOutlet weak var learnMoreButtonLabel: UILabel!
    
    @IBOutlet weak var enrollmentSwitchView: UIView!
    @IBOutlet weak var enrollmentSwitch: Switch!
    
    @IBOutlet weak var expirationLabel: UILabel!
    
    @IBOutlet weak var selectBankAccountLabel: UILabel!
    
    @IBOutlet weak var enrolledPaymentAccountLabel: UILabel!
    @IBOutlet weak var bankAccountButton: ButtonControl!
    @IBOutlet weak var bankAccountButtonIcon: UIImageView!
    @IBOutlet weak var bankAccountButtonSelectLabel: UILabel!
    @IBOutlet weak var bankAccountButtonAccountNumberLabel: UILabel!
    @IBOutlet weak var bankAccountButtonNicknameLabel: UILabel!
    
    @IBOutlet weak var settingsButton: ButtonControl!
    @IBOutlet weak var settingsButtonLabel: UILabel!
    
    var accountDetail: AccountDetail! // Passed from BillViewController
    
    lazy var viewModel: BGEAutoPayViewModel = { BGEAutoPayViewModel(paymentService: ServiceFactory.createPaymentService(), accountDetail: self.accountDetail) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("AutoPay", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        learnMoreButton.backgroundColorOnPress = .softGray
        learnMoreButton.addShadow(color: .black, opacity: 0.12, offset: CGSize(width: 0, height: 0), radius: 3)
        learnMoreButtonLabel.textColor = .blackText
        learnMoreButtonLabel.font = OpenSans.regular.of(size: 18)
        let autoPayString = NSLocalizedString("AutoPay", comment: "")
        let attrString = NSMutableAttributedString(string: String(format: NSLocalizedString("Learn more about\n%@", comment: ""), autoPayString))
        attrString.addAttribute(NSFontAttributeName, value: OpenSans.bold.of(size: 18), range: (attrString.string as NSString).range(of: autoPayString))
        learnMoreButtonLabel.attributedText = attrString
        
        expirationLabel.textColor = .blackText
        expirationLabel.text = "Enrollment expired due to AutoPay settings - you set enrollment to expire on TODO."
        
        selectBankAccountLabel.textColor = .blackText
        selectBankAccountLabel.font = OpenSans.semibold.of(textStyle: .headline)
        selectBankAccountLabel.text = NSLocalizedString("Select a bank account to enroll in AutoPay.", comment: "")
        
        enrolledPaymentAccountLabel.textColor = .deepGray
        enrolledPaymentAccountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        enrolledPaymentAccountLabel.text = NSLocalizedString("AutoPay Payment Account:", comment: "")
        
        bankAccountButton.backgroundColorOnPress = .softGray
        bankAccountButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        bankAccountButtonSelectLabel.font = SystemFont.medium.of(textStyle: .title1)
        bankAccountButtonSelectLabel.textColor = .blackText
        bankAccountButtonSelectLabel.text = NSLocalizedString("Select Bank Account", comment: "")
        
        bankAccountButtonAccountNumberLabel.textColor = .blackText
        bankAccountButtonNicknameLabel.textColor = .middleGray
        
        stickyBottomView.backgroundColor = .softGray
        stickyBottomLabel.textColor = .blackText
        stickyBottomLabel.text = NSLocalizedString("Your recurring payment will apply to the next BGE bill you receive. You will need to submit a payment for your current BGE bill if you have not already done so.", comment: "")
        
        settingsButtonLabel.textColor = .actionBlue
        settingsButtonLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
        
        if viewModel.enrollmentStatus.value == .isEnrolled {
            stickyBottomViewHeightConstraint.constant = 0
            expirationLabel.isHidden = true
            selectBankAccountLabel.isHidden = true
        } else {
            enrollmentSwitchView.isHidden = true
            expirationLabel.isHidden = true
            enrolledPaymentAccountLabel.isHidden = true
        }
        
        viewModel.getAutoPayInfo(onSuccess: { 
            
        }, onError: { errMessage in
            print(errMessage)
        })
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = gradientView.bounds
    }
    
    func setupBindings() {
        viewModel.shouldShowWalletItem.map(!).drive(bankAccountButtonAccountNumberLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowWalletItem.map(!).drive(bankAccountButtonNicknameLabel.rx.isHidden).addDisposableTo(disposeBag)
        viewModel.shouldShowWalletItem.drive(bankAccountButtonSelectLabel.rx.isHidden).addDisposableTo(disposeBag)
        
        viewModel.bankAccountButtonImage.drive(bankAccountButtonIcon.rx.image).addDisposableTo(disposeBag)
        viewModel.walletItemAccountNumberText.drive(bankAccountButtonAccountNumberLabel.rx.text).addDisposableTo(disposeBag)
        viewModel.walletItemNicknameText.drive(bankAccountButtonNicknameLabel.rx.text).addDisposableTo(disposeBag)
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        print("Submit")
        print(viewModel.amountToPay.value)
    }
    
    @IBAction func onLearnMorePress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("What is AutoPay?", comment: ""), image: #imageLiteral(resourceName: "img_autopaymodal"), description: NSLocalizedString("Sign up for AutoPay and you will never have to write another check to pay your bill. With AutoPay, your payment is automatically deducted from your bank account. Upon payment, you will receive a payment confirmation for your records.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }

    @IBAction func onSelectBankAccountPress() {
        let storyboard = UIStoryboard(name: "Bill", bundle: nil)
        let miniWalletVC = storyboard.instantiateViewController(withIdentifier: "miniWallet") as! MiniWalletViewController
        miniWalletVC.tableHeaderLabelText = NSLocalizedString("Select a bank account to enroll in AutoPay.", comment: "")
        miniWalletVC.accountDetail = viewModel.accountDetail
        miniWalletVC.creditCardsDisabled = true
        miniWalletVC.delegate = self
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

}

extension BGEAutoPayViewController: MiniWalletViewControllerDelegate {
    
    func miniWalletViewController(_ miniWalletViewController: MiniWalletViewController, didSelectWalletItem walletItem: WalletItem) {
        viewModel.selectedWalletItem.value = walletItem
    }
}
