//
//  PaperlessEBillViewController.swift
//  Mobile
//
//  Created by Sam Francis on 4/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol PaperlessEBillViewControllerDelegate: class {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus)
}

class PaperlessEBillViewController: UIViewController {
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    @IBOutlet weak var scrollView: UIScrollView!
    // Background
    @IBOutlet weak var topBackgroundView: UIView!
    @IBOutlet weak var gradientBackgroundView: UIView!
    private var gradientLayer: CAGradientLayer!
    
    // Content
    @IBOutlet weak var whatIsButton: ButtonControl!
    @IBOutlet weak var emailsWillBeSentToLabel: UILabel!
	@IBOutlet weak var emailLabel: UILabel!
	@IBOutlet weak var updateDetailsView: UIView!
    @IBOutlet weak var updateDetailsLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsView: UIView!
    @IBOutlet weak var allAccountsLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsSwitch: UISwitch!
    @IBOutlet weak var allAccountsSeparatorView: UIView!
    @IBOutlet weak var accountsStackView: UIStackView!
    @IBOutlet weak var detailsLoadingActivityView: UIView!
    @IBOutlet weak var detailsLoadingIndicator: LoadingIndicator!
    
    @IBOutlet weak var detailsLabel: UILabel!
    
    var initialAccountDetail: AccountDetail!
    
    lazy var viewModel: PaperlessEBillViewModel = {
        PaperlessEBillViewModel(accountService: ServiceFactory.createAccountService(),
                                billService: ServiceFactory.createBillService(),
                                initialAccountDetail: self.initialAccountDetail)
    }()
    
    weak var delegate: PaperlessEBillViewControllerDelegate?
    
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorAndShadowSetup()
        
        enrollAllAccountsView.isHidden = viewModel.accounts.value.count <= 1
		updateDetailsView.isHidden = Environment.sharedInstance.opco == .bge
        
        emailsWillBeSentToLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        emailLabel.text = viewModel.initialAccountDetail.value.customerInfo.emailAddress
        
        allAccountsLabel.font = SystemFont.medium.of(textStyle: .title1)
        
        detailsLabel.font = OpenSans.regular.of(textStyle: .footnote)
        detailsLabel.text = viewModel.footerText
        
        updateDetailsLabel.font = SystemFont.regular.of(textStyle: .headline)
        updateDetailsLabel.setLineHeight(lineHeight: 24)
        
        viewModel.accountDetails
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] accountDetails -> () in
                self?.enrollAllAccountsSwitch.isEnabled = true
                self?.detailsLoadingActivityView.isHidden = true
                accountDetails.forEach {
                    self?.add(accountDetail: $0, animated: true)
                }
            })
            .addDisposableTo(bag)
        
        viewModel.enrollAllAccounts.asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] in
                self?.enrollAllAccountsSwitch.setOn($0, animated: true)
            })
            .addDisposableTo(bag)
        
        Driver.combineLatest(viewModel.accountsToEnroll.asDriver(), viewModel.accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
            .drive(submitButton.rx.isEnabled)
            .addDisposableTo(bag)
        
        whatIsButton.backgroundColorOnPress = .softGray
        whatIsButton.rx.touchUpInside.asDriver().drive(onNext: { [weak self] in
            let description: String
            if Environment.sharedInstance.opco == .bge {
                description = NSLocalizedString("Eliminate your paper bill.  Your online bill is identical to your current paper bill and is available to view, download, or print at any time.  You will receive bill ready email notifications regardless of preference.  Your preference will be updated with your next month’s bill.", comment: "")
            } else {
                description = NSLocalizedString("Eliminate your paper bill and receive an email notification when your bill is ready to view online.  Your online bill is identical to your current paper bill and is available to view, download, or print at any time.  Your preference will be updated with your next month’s bill.", comment: "")
            }
            let infoModal = InfoModalViewController(title: NSLocalizedString("Paperless eBill", comment: ""), image: #imageLiteral(resourceName: "paperless_modal"), description: description)
            self?.navigationController?.present(infoModal, animated: true, completion: nil)
        }).addDisposableTo(bag)
        whatIsButton.accessibilityLabel = NSLocalizedString("What is Paperless e-bill", comment: "")
        enrollAllAccountsSwitch.accessibilityLabel = NSLocalizedString("Enrollment status: ", comment: "")
    }
    
    func colorAndShadowSetup() {
        topBackgroundView.backgroundColor = UIColor.white
        topBackgroundView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0, height: 2), radius: 1)
        enrollAllAccountsView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 2)
        enrollAllAccountsView.layer.cornerRadius = 2
        
        whatIsButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        whatIsButton.layer.cornerRadius = 2
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientBackgroundView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientBackgroundView.layer.addSublayer(gradientLayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientBackgroundView.frame
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = gradientBackgroundView.frame
    }
    
    func add(accountDetail: AccountDetail, animated: Bool) {
        let accountView = PaperlessEBillAccountView.create(withAccountDetail: accountDetail)
        
        accountView.isOn?.asDriver()
            .drive(onNext: { [weak self] isOn in
                self?.viewModel.switched(accountDetail: accountDetail, on: isOn)
            })
            .addDisposableTo(accountView.bag)
        
        enrollAllAccountsSwitch.rx.isOn.asDriver().skip(1)
            .drive(onNext: {
                accountView.toggleSwitch(on: $0)
            })
            .addDisposableTo(accountView.bag)
        
        accountsStackView.addArrangedSubview(accountView)
        
    }
    
    @IBAction func cancelAction() {
        if viewModel.enrollStatesChanged.value {
            let message = !viewModel.accountsToEnroll.value.isEmpty ? NSLocalizedString("Are you sure you want to exit this screen without completing enrollment?", comment: "") : NSLocalizedString("Are you sure you want to exit this screen without completing unenrollment?", comment: "")
            let alertVc = UIAlertController(title: NSLocalizedString("Exit Paperless eBill", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func submitAction(_ sender: Any) {
        LoadingView.show()
        viewModel.submitChanges(onSuccess: { [weak self] changedStatus in
            LoadingView.hide()
            guard let `self` = self else { return }
            self.delegate?.paperlessEBillViewController(self, didChangeStatus: changedStatus)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        })
    }
    
    deinit {
        dLog(message: className)
    }
}
