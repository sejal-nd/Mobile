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
    
    @IBOutlet weak var exitView: UIView! {
        didSet {
            exitView.isHidden = true
        }
    }
    @IBOutlet weak var headerView: UIView!

    @IBOutlet weak var exitTextLabel: UILabel!
    @IBOutlet weak var exitButton: ButtonControl! {
        didSet {
            exitButton.layer.cornerRadius = 10.0
            exitButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
        }
    }
    
    @IBOutlet weak var headerContentView: ButtonControl! {
        didSet {
            headerContentView.layer.cornerRadius = 10.0
            
            headerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
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
            footerTextView.text = viewModel.footerTextViewText
            
            footerTextView.textContainerInset = .zero
            footerTextView.textColor = .softGray
            footerTextView.tintColor = .white // For phone numbers
            footerTextView.linkTapDelegate = self
        }
    }
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingAnimationView: UIView!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    
    let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService(),
                                                   outageService: ServiceFactory.createOutageService())
    
    private var loadingLottieAnimation = LOTAnimationView(name: "outage_loading")
    
    let disposeBag = DisposeBag()
    

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)
        
        viewModel.stormModeEnded
            .drive(onNext: { [weak self] in self?.stormModeEnded() })
            .disposed(by: disposeBag)
        
        // re implement
//        exitButton.rx.tap.asDriver()
//            .drive(onNext: { [weak self] in self?.returnToMainApp() })
//            .disposed(by: disposeBag)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        outageStatusButton.delegate = self
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopAnimation = true
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        
        loadingView.isHidden = true
        
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.updateContent(outageJustReported: true) })
            .disposed(by: disposeBag)
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                //self.accountContentView.isHidden = true
                //self.gasOnlyTextViewBottomSpaceConstraint.isActive = false
                //self.gasOnlyView.isHidden = true
                //self.errorLabel.isHidden = true
                //self.customErrorView.isHidden = true
                self.loadingView.isHidden = true
                //self.noNetworkConnectionView.isHidden = true
                //self.maintenanceModeView.isHidden = true
                //self.setRefreshControlEnabled(enabled: false)
            case .readyToFetchData:
                if AccountsStore.shared.currentAccount != self.accountPicker.currentAccount {
                    self.getOutageStatus()
                } else if self.viewModel.currentOutageStatus == nil {
                    self.getOutageStatus()
                }
            }
        }).disposed(by: disposeBag)
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
    
    
    // MARK: - Actions
    
    @IBAction func showStormModeDetails(_ sender: Any) {
        performSegue(withIdentifier: "UpdatesDetailSegue", sender: nil)
    }

    @IBAction func exitStormMode(_ sender: Any) {
        returnToMainApp()
    }
    
    
    // MARK: - Helper
    
    private func stormModeEnded() {
        let noAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel)
        { [weak self] _ in
            self?.exitView.isHidden = false
            self?.headerContentView.isHidden = true
        }
        
        let yesAction = UIAlertAction(title: NSLocalizedString("Return", comment: ""), style: .default)
        { [weak self] _ in
            self?.returnToMainApp()
        }
        
        presentAlert(title: NSLocalizedString("Storm Mode Has Ended", comment: ""),
                     message: NSLocalizedString("Would you like to return to the main app?", comment: ""),
                     style: .alert,
                     actions: [noAction, yesAction])
    }
    
    func getOutageStatus() {
        //accountContentView.isHidden = true
        //gasOnlyTextViewBottomSpaceConstraint.isActive = false
        //gasOnlyView.isHidden = true
        //errorLabel.isHidden = true
        //customErrorView.isHidden = true
        loadingView.isHidden = false
        scrollView?.isHidden = false
        //noNetworkConnectionView.isHidden = true
        //maintenanceModeView.isHidden = true
        //setRefreshControlEnabled(enabled: false)
        
        viewModel.fetchData(onSuccess: { [weak self] in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            self?.scrollView?.isHidden = false
            //self?.noNetworkConnectionView.isHidden = true
            self?.loadingView.isHidden = true
            //self?.maintenanceModeView.isHidden = true
            //self?.setRefreshControlEnabled(enabled: true)
            self?.updateContent(outageJustReported: false)
            
            // If coming from shortcut, check these flags for report outage button availablility
//            if let outageStatus = self?.viewModel.currentOutageStatus,
//                !outageStatus.flagGasOnly &&
//                    !outageStatus.flagNoPay &&
//                    !outageStatus.flagFinaled &&
//                    !outageStatus.flagNonService &&
//                    self?.shortcutItem == .reportOutage {
//                self?.performSegue(withIdentifier: "reportOutageSegue", sender: self)
//            }
            
//            self?.shortcutItem = .none
            }, onError: { [weak self] serviceError in
//                self?.shortcutItem = .none
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self?.scrollView?.isHidden = true
//                    self?.noNetworkConnectionView.isHidden = false
                } else {
                    self?.scrollView?.isHidden = false
//                    self?.noNetworkConnectionView.isHidden = true
                }
                self?.loadingView.isHidden = true
//                self?.setRefreshControlEnabled(enabled: true)
                
                if serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
//                    self?.errorLabel.isHidden = true
//                    self?.customErrorView.isHidden = false
                } else {
//                    self?.errorLabel.isHidden = false
//                    self?.customErrorView.isHidden = true
                }
//                self?.maintenanceModeView.isHidden = true
            })
    }
    
    private func returnToMainApp() {
        guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
    }
    
    func updateContent(outageJustReported: Bool) {
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UpdatesDetailViewController {
            vc.opcoUpdate = OpcoUpdate(title: "Hello", message: "World")
        } else if let vc = segue.destination as? ReportOutageViewController {
            navigationController?.setNavigationBarHidden(false, animated: true) // may be able to refactor this out into the root of prep for segue
            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
            if let phone = viewModel.currentOutageStatus!.contactHomeNumber {
                vc.viewModel.phoneNumber.value = phone
            }
        } else if let vc = segue.destination as? OutageMapViewController {
            navigationController?.setNavigationBarHidden(false, animated: true)
            vc.hasPressedStreetlightOutageMapButton = false
        } else if segue.destination is BillViewController {
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else if segue.destination is MoreViewController {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
}

extension StormModeHomeViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        //getOutageStatus()
    }
    
}

extension StormModeHomeViewController: OutageStatusButtonDelegate {
    
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        Analytics.log(event: .outageStatusDetails)
        
        if let message = viewModel.currentOutageStatus!.outageDescription {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
}

extension StormModeHomeViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        print("INTERACTION")
        //Analytics.log(event: .outageAuthEmergencyCall)
    }
    
}
