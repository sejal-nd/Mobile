//
//  StormModeHomeViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 8/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import Lottie

class StormModeHomeViewController: AccountPickerViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var exitButton: UIButton!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerContentView: ButtonControl! {
        didSet {
            headerContentView.layer.cornerRadius = 10.0
            headerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            headerContentView.backgroundColor = .lightGray
        }
    }
    
    @IBOutlet weak var headerViewTitleLabel: UILabel! {
        didSet {
            headerViewTitleLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    @IBOutlet weak var headerViewDescriptionLabel: UILabel! {
        didSet {
            headerViewDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet weak var footerTextView: DataDetectorTextView! {
        didSet {
            footerTextView.text = "To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123\n\nFor downed or sparking power lines or dim/flickering lights, please call 1-877-778-2222"
            footerTextView.font = OpenSans.regular.of(textStyle: .footnote)
            footerTextView.textColor = .softGray
            footerTextView.tintColor = .white
        }
    }
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingAnimationView: UIView!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    
    private let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService())
    
    private var loadingLottieAnimation = LOTAnimationView(name: "outage_loading")
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)
        
        exitButton.isHidden = true
        
        viewModel.stormModeEnded
            .drive(onNext: { [weak self] in self?.stormModeEnded() })
            .disposed(by: disposeBag)
        
        exitButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in self?.returnToMainApp() })
            .disposed(by: disposeBag)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        outageStatusButton.delegate = self
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopAnimation = true
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        
        loadingView.isHidden = true
        
        
//        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
//            guard let `self` = self else { return }
//            switch(state) {
//            case .loadingAccounts:
//                self.accountContentView.isHidden = true
//                self.gasOnlyTextViewBottomSpaceConstraint.isActive = false
//                self.gasOnlyView.isHidden = true
//                self.errorLabel.isHidden = true
//                self.customErrorView.isHidden = true
//                self.loadingView.isHidden = true
//                self.noNetworkConnectionView.isHidden = true
//                self.maintenanceModeView.isHidden = true
//                self.setRefreshControlEnabled(enabled: false)
//            case .readyToFetchData:
//                if AccountsStore.shared.currentAccount != self.accountPicker.currentAccount {
//                    self.getOutageStatus()
//                } else if self.viewModel.currentOutageStatus == nil {
//                    self.getOutageStatus()
//                }
//            }
//        }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerView.frame.size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        tableView.tableHeaderView = headerView
    }
    
    private func stormModeEnded() {
        let noAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel)
        { [weak self] _ in self?.exitButton.isHidden = false }
        
        let yesAction = UIAlertAction(title: NSLocalizedString("Return", comment: ""), style: .default)
        { [weak self] _ in
            self?.returnToMainApp()
        }
        
        presentAlert(title: NSLocalizedString("Storm Mode Has Ended", comment: ""),
                     message: NSLocalizedString("Would you like to return to the main app?", comment: ""),
                     style: .alert,
                     actions: [noAction, yesAction])
    }
    
    private func returnToMainApp() {
        guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
    }
    
}

extension StormModeHomeViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        //getOutageStatus()
    }
    
}

extension StormModeHomeViewController: OutageStatusButtonDelegate {
    
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        print("Outage Tapped")
//        Analytics.log(event: .outageStatusDetails)
        
//        if viewModel.currentOutageStatus!.flagNoPay && Environment.shared.opco != .bge  {
//            tabBarController?.selectedIndex = 1 // Jump to Bill tab
//        } else {
//            if let message = viewModel.currentOutageStatus!.outageDescription {
//                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
//                present(alert, animated: true, completion: nil)
//            }
//        }
    }
    
}
