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
            footerTextView.attributedText = viewModel.footerTextViewText
            footerTextView.textContainerInset = .zero
            footerTextView.textColor = .softGray
            footerTextView.tintColor = .white // For phone numbers
            footerTextView.linkTapDelegate = self
        }
    }
    
    @IBOutlet weak var gasOnlyView: UIView!
    @IBOutlet weak var gasOnlyTitleLabel: UILabel! {
        didSet {
            gasOnlyTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    @IBOutlet weak var gasOnlyTextView: DataDetectorTextView! {
        didSet {
            gasOnlyTextView.font = OpenSans.regular.of(textStyle: .subheadline)
            gasOnlyTextView.textContainerInset = .zero
            gasOnlyTextView.tintColor = .white
            gasOnlyTextView.text = viewModel.gasOnlyMessage
        }
    }
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingBackgroundView: UIView! {
        didSet {
            loadingBackgroundView.layer.cornerRadius = loadingBackgroundView.frame.height / 2
            loadingBackgroundView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var loadingAnimationView: UIView!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    
    private var loadingLottieAnimation = LOTAnimationView(name: "sm_outage_loading")
    private var refreshControl: UIRefreshControl?
    
    let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService(),
                                                   outageService: ServiceFactory.createOutageService())
    
    let disposeBag = DisposeBag()
    
    var shouldShowOutageButtons = false

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)

        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        outageStatusButton.delegate = self
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopAnimation = true
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        
        
        // MARK: - Events
        
        viewModel.stormModeEnded
            .drive(onNext: { [weak self] in self?.stormModeEnded() })
            .disposed(by: disposeBag)
        
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.updateContent(outageJustReported: true) })
            .disposed(by: disposeBag)
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.gasOnlyView.isHidden = true
                self.loadingView.isHidden = true
                self.setRefreshControlEnabled(enabled: false)
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
    
    @objc private func onPullToRefresh() {
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            self.refreshControl?.endRefreshing()
            self.updateContent(outageJustReported: false)
            }, onError: { [weak self] serviceError in
                guard let `self` = self else { return }
                self.refreshControl?.endRefreshing()
                
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self.scrollView?.isHidden = true
                } else {
                    self.scrollView?.isHidden = false
                }

                // Hide everything else
                self.gasOnlyView.isHidden = true
            })
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
        gasOnlyView.isHidden = true
        loadingView.isHidden = false
        scrollView?.isHidden = false
        setRefreshControlEnabled(enabled: false)
        
        viewModel.fetchData(onSuccess: { [weak self] in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            self?.scrollView?.isHidden = false
            self?.loadingView.isHidden = true
            self?.setRefreshControlEnabled(enabled: true)
            self?.updateContent(outageJustReported: false)
            }, onError: { [weak self] serviceError in
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self?.scrollView?.isHidden = true
                } else {
                    self?.scrollView?.isHidden = false
                }
                self?.loadingView.isHidden = true
                self?.setRefreshControlEnabled(enabled: true)
            })
    }
    
    private func returnToMainApp() {
        guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
    }
    
    func updateContent(outageJustReported: Bool) {
        guard let currentOutageStatus = viewModel.currentOutageStatus  else { return }

        layoutBigButtonContent(outageJustReported: outageJustReported)
        
        // Show/hide the top level container views
        if currentOutageStatus.flagGasOnly {
            gasOnlyView.isHidden = false
            shouldShowOutageButtons = false
        } else {
            gasOnlyView.isHidden = true
            shouldShowOutageButtons = true
        }
        
        // Update after just reporting outage
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
    
    func layoutBigButtonContent(outageJustReported: Bool) {
        //outageStatusButton.setOutageState(estimatedRestorationDateString: "12:00:23")
        //outageStatusButton.setReportedState(estimatedRestorationDateString: "12:00:23")
        outageStatusButton.setIneligibleState(flagFinaled: true, nonPayFinaledMessage: "Outage Status and Outage Reporting are not available for accounts with an outstanding balance.")
       // outageStatusButton.setPowerOnState()
//        let currentOutageStatus = viewModel.currentOutageStatus!
//
//        if outageJustReported && viewModel.reportedOutage != nil {
//            outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
//        } else if currentOutageStatus.activeOutage {
//            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
//        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay || currentOutageStatus.flagNonService {
//            outageStatusButton.setIneligibleState(flagFinaled: currentOutageStatus.flagFinaled, nonPayFinaledMessage: viewModel.accountNonPayFinaledMessage)
//        } else { // Power is on
//            outageStatusButton.setPowerOnState()
//        }
    }
    
    @objc private func killRefresh() -> Void {
        refreshControl?.endRefreshing()
        scrollView!.alwaysBounceVertical = false
    }
    
    private func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            scrollView!.insertSubview(refreshControl!, at: 0)
            scrollView!.alwaysBounceVertical = true
        } else {
            if let rc = refreshControl {
                rc.endRefreshing()
                rc.removeFromSuperview()
                refreshControl = nil
            }
            scrollView!.alwaysBounceVertical = false
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UpdatesDetailViewController {
            vc.opcoUpdate = OpcoUpdate(title: NSLocalizedString("Storm Mode is in effect", comment: ""), message: NSLocalizedString("Due to severe weather, limited features are available to allow us to better serve you.", comment: ""))
        } else if let vc = segue.destination as? ReportOutageViewController {
            navigationController?.setNavigationBarHidden(false, animated: true) // may be able to refactor this out into the root of prep for segue
            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
            
            guard let phone = viewModel.currentOutageStatus!.contactHomeNumber else { return }
            vc.viewModel.phoneNumber.value = phone
        } else if let vc = segue.destination as? OutageMapViewController {
            navigationController?.setNavigationBarHidden(false, animated: true)
            vc.hasPressedStreetlightOutageMapButton = false
        } else if let vc = segue.destination as? BillViewController {
            vc.shouldHideNavigationBar = false
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else if let vc = segue.destination as? MoreViewController {
            vc.shouldHideNavigationBar = false
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
}

extension StormModeHomeViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        getOutageStatus()
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
        Analytics.log(event: .outageAuthEmergencyCall)
    }
    
}
