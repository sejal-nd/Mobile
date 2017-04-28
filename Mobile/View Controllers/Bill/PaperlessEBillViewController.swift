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
    func paperlessEBillViewControllerDidEnroll(_ paperlessEBillViewController: PaperlessEBillViewController)
    func paperlessEBillViewControllerDidUnenroll(_ paperlessEBillViewController: PaperlessEBillViewController)
    func paperlessEBillViewControllerDidChangeStatus(_ paperlessEBillViewController: PaperlessEBillViewController)
}

class PaperlessEBillViewController: UIViewController {
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    @IBOutlet weak var scrollView: UIScrollView!
    // Background
    @IBOutlet weak var topBackgroundView: UIView!
    @IBOutlet weak var gradientBackgroundView: UIView!
    private var gradientLayer: CALayer = CAGradientLayer()
    
    // Content
    @IBOutlet weak var whatIsButtonView: UIView!
    @IBOutlet weak var whatIsButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsView: UIView!
    @IBOutlet weak var enrollAllAccountsSwitch: UISwitch!
    @IBOutlet weak var allAccountsSeparatorView: UIView!
    @IBOutlet weak var accountsStackView: UIStackView!
    @IBOutlet weak var detailsLoadingActivityView: UIView!
    @IBOutlet weak var detailsLoadingActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var detailsLabel: UILabel!
    
    var initialAccountDetail: AccountDetail!
    var accounts: [Account]!
    
    lazy var viewModel: PaperlessEBillViewModel = {
        PaperlessEBillViewModel(accountService: ServiceFactory.createAccountService(), initialAccountDetail: self.initialAccountDetail, accounts: self.accounts)
    } ()
    
    weak var delegate: PaperlessEBillViewControllerDelegate?
    
    
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        topBackgroundView.layer.shadowColor = UIColor.black.cgColor
        topBackgroundView.layer.shadowOpacity = 0.08
        topBackgroundView.layer.shadowRadius = 1
        topBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        enrollAllAccountsView.layer.shadowColor = UIColor.black.cgColor
        enrollAllAccountsView.layer.shadowOpacity = 0.2
        enrollAllAccountsView.layer.shadowRadius = 2
        enrollAllAccountsView.layer.shadowOffset = .zero
        enrollAllAccountsView.layer.cornerRadius = 2
        
        enrollAllAccountsView.isHidden = viewModel.accounts.value.count <= 1
        enrollAllAccountsView.isHidden = viewModel.accounts.value.count <= 1
        
        emailLabel.text = viewModel.initialAccountDetail.value.customerInfo.emailAddress
        
        viewModel.accountsToEnroll.asObservable()
            .subscribe(onNext: {
                print("Updated accounts to enroll", $0)
            })
            .addDisposableTo(bag)
        
        viewModel.accountsToUnenroll.asObservable()
            .subscribe(onNext: {
                print("Updated accounts to unenroll", $0)
            })
            .addDisposableTo(bag)
        
        self.detailsLoadingActivityIndicator.color = .primaryColor
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
        
        
        viewModel.enrollAllAccounts.asDriver()
            .drive(onNext: { [weak self] in
                self?.enrollAllAccountsSwitch.setOn($0, animated: true)
            })
            .addDisposableTo(bag)
        
        whatIsButtonSetup()
        
        detailsLabel.text = viewModel.footerText
        
        Driver.combineLatest(viewModel.accountsToEnroll.asDriver(), viewModel.accountsToUnenroll.asDriver()) { !$0.isEmpty || !$1.isEmpty }
            .drive(submitButton.rx.isEnabled)
            .addDisposableTo(bag)
    }
    
    func whatIsButtonSetup() {
        whatIsButtonView.layer.shadowColor = UIColor.black.cgColor
        whatIsButtonView.layer.shadowOpacity = 0.2
        whatIsButtonView.layer.shadowRadius = 3
        whatIsButtonView.layer.shadowOffset = .zero
        whatIsButtonView.layer.cornerRadius = 2
        
        let whatIsButtonSelectedColor = whatIsButton.rx.controlEvent(.touchDown).asDriver()
            .map { UIColor.whiteButtonHighlight }
        
        let whatIsButtonDeselectedColor = Driver.of(whatIsButton.rx.controlEvent(.touchUpInside).asDriver(),
                                                    whatIsButton.rx.controlEvent(.touchUpOutside).asDriver(),
                                                    whatIsButton.rx.controlEvent(.touchCancel).asDriver())
            .merge()
            .map { UIColor.white }
        
        Driver.merge(whatIsButtonSelectedColor, whatIsButtonDeselectedColor)
            .drive(onNext: { [weak self] color in
                self?.whatIsButtonView.backgroundColor = color
            })
            .addDisposableTo(bag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.removeFromSuperlayer()
        
        let gLayer = CAGradientLayer()
        gLayer.frame = gradientBackgroundView.frame
        gLayer.colors = [UIColor.whiteSmoke.cgColor, UIColor.white.cgColor]
        
        gradientLayer = gLayer
        gradientBackgroundView.layer.addSublayer(gLayer)
    }
    
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = gradientBackgroundView.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.ofSize(18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    
    func add(accountDetail: AccountDetail, animated: Bool) {
        let accountView = PaperlessEBillAccountView.create(withAccountDetail: accountDetail)
        
        accountView.isOn.asDriver()
            .drive(onNext: { [weak self] isOn in
                self?.viewModel.switched(accountDetail: accountDetail, on: isOn)
            })
            .addDisposableTo(accountView.bag)
        
        self.accountsStackView.addArrangedSubview(accountView)
        
    }
    
    @IBAction func cancelAction() {
        if viewModel.enrollStatesChanged.value {
            let message = !viewModel.accountsToEnroll.value.isEmpty ? NSLocalizedString("Are you sure you want to exit this screen without completing enrollment?", comment: "") : NSLocalizedString("Are you sure you want to exit this screen without completing unenrollment?", comment: "")
            let alertVc = UIAlertController(title: NSLocalizedString("Exit Paperless eBill", comment: ""), message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func submitAction(_ sender: Any) {
        if viewModel.accounts.value.count > 1 {
            delegate?.paperlessEBillViewControllerDidChangeStatus(self)
        } else {
            if !viewModel.accountsToEnroll.value.isEmpty {
                delegate?.paperlessEBillViewControllerDidEnroll(self)
            }
            if !viewModel.accountsToUnenroll.value.isEmpty {
                delegate?.paperlessEBillViewControllerDidUnenroll(self)
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
}
