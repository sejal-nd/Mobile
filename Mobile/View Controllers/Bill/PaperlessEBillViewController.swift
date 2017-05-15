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

enum PaperlessEBillChangedStatus {
    case Enroll
    case Unenroll
    case Mixed
}

protocol PaperlessEBillViewControllerDelegate: class {
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus)
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
	@IBOutlet weak var updateDetailsView: UIView!
    @IBOutlet weak var updateDetailsLabel: UILabel!
    @IBOutlet weak var enrollAllAccountsView: UIView!
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
        
        emailLabel.text = viewModel.initialAccountDetail.value.customerInfo.emailAddress
        detailsLabel.text = viewModel.footerText
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
    }
    
    func colorAndShadowSetup() {
        topBackgroundView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0, height: 2), radius: 1)
        enrollAllAccountsView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 2)
        enrollAllAccountsView.layer.cornerRadius = 2
        whatIsButtonView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        whatIsButtonView.layer.cornerRadius = 2
        
        let whatIsButtonSelectedColor = whatIsButton.rx.controlEvent(.touchDown).asDriver()
            .map { UIColor.softGray }
        
        let whatIsButtonDeselectedColor = Driver.merge(whatIsButton.rx.controlEvent(.touchUpInside).asDriver(),
                                                       whatIsButton.rx.controlEvent(.touchUpOutside).asDriver(),
                                                       whatIsButton.rx.controlEvent(.touchCancel).asDriver())
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
        gLayer.colors = [UIColor.softGray.cgColor, UIColor.white.cgColor]
        
        gradientLayer = gLayer
        gradientBackgroundView.layer.addSublayer(gLayer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        gradientLayer.frame = gradientBackgroundView.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
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
        LoadingView.show()
        viewModel.submitChanges(onSuccess: { changedStatus in
            LoadingView.hide()
            self.delegate?.paperlessEBillViewController(self, didChangeStatus: changedStatus)
            self.navigationController?.popViewController(animated: true)
        }, onError: { errMessage in
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertVc, animated: true, completion: nil)
        })
    }
}
