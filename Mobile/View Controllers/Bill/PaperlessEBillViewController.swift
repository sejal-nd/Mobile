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

class PaperlessEBillViewController: UIViewController {
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
    @IBOutlet weak var accountsStackView: UIStackView!
    
    @IBOutlet weak var detailsLabel: UILabel!
    
    let viewModel = PaperlessEBillViewModel()
    
    var accounts:[Account]!
    
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        topBackgroundView.layer.shadowColor = UIColor.black.cgColor
        topBackgroundView.layer.shadowOpacity = 0.08
        topBackgroundView.layer.shadowRadius = 1
        topBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        enrollAllAccountsView.isHidden = accounts.count <= 1
        
        viewModel.accountsToEnroll.asObservable()
            .subscribe(onNext: {
                print("Updated accounts to enroll", $0)
            })
            .addDisposableTo(bag)
        
        viewModel.accounts.value = accounts
        
        // Just some statuses thrown in for testing.
        let testStatuses: [EBillEnrollStatus] = [.canEnroll, .canEnroll, .finaled, .ineligible]
        
        for (index, account) in viewModel.accounts.value.enumerated() {
            add(account: account, enrollStatus: testStatuses[index % testStatuses.count])
        }
        
        viewModel.enrollAllAccounts.asDriver()
            .drive(enrollAllAccountsSwitch.rx.isOn)
            .addDisposableTo(bag)
        
        whatIsButtonSetup()
    }
    
    func whatIsButtonSetup() {
        whatIsButtonView.layer.shadowColor = UIColor.black.cgColor
        whatIsButtonView.layer.shadowOpacity = 0.2
        whatIsButtonView.layer.shadowRadius = 3
        whatIsButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
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
    
    func add(account: Account, enrollStatus: EBillEnrollStatus) {
        let accountView = PaperlessEBillAccountView.create(withAccount: account, enrollStatus: enrollStatus)
        
        accountView.isOn.asDriver()
            .drive(onNext: { [weak self] isOn in
                guard let viewModel = self?.viewModel else { return }
                if isOn {
                    viewModel.accountsToEnroll.value.insert(account)
                } else {
                    viewModel.accountsToEnroll.value.remove(account)
                }
            })
            .addDisposableTo(accountView.bag)
        
        accountsStackView.addArrangedSubview(accountView)
        
    }

}
