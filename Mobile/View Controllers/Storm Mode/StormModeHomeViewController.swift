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
    
    @IBOutlet weak var finalPayView: UIView!
    @IBOutlet weak var finalPayTitleLabel: UILabel! {
        didSet {
            finalPayTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    @IBOutlet weak var finalPayTextView: DataDetectorTextView! {
        didSet {
            finalPayTextView.font = OpenSans.regular.of(textStyle: .subheadline)
            finalPayTextView.textContainerInset = .zero
            finalPayTextView.tintColor = .white
        }
    }
    @IBOutlet weak var finalPayButton: ButtonControl! {
        didSet {
            finalPayButton.layer.cornerRadius = 10.0
        }
    }
    @IBOutlet weak var finalPayButtonLabel: UILabel! {
        didSet {
            finalPayButtonLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    /// This houses both the outage status button and the loading view for the button
    @IBOutlet weak var loadingContentView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingBackgroundView: UIView! {
        didSet {
            loadingBackgroundView.layer.cornerRadius = loadingBackgroundView.frame.height / 2
        }
    }
    @IBOutlet weak var loadingAnimationView: UIView!
    @IBOutlet weak var outageStatusButton: OutageStatusButton!
    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView! {
        didSet {
            noNetworkConnectionView.configureContactText(attributedText: viewModel.footerTextViewText)
        }
    }
    
    private var loadingLottieAnimation = LOTAnimationView(name: "sm_outage_loading")
    private var refreshControl: UIRefreshControl?
    
    let viewModel = StormModeHomeViewModel(authService: ServiceFactory.createAuthenticationService(),
                                                   outageService: ServiceFactory.createOutageService())
    
    let disposeBag = DisposeBag()
    
    /// Controls if content is shown within cells
    var shouldShowOutageCellData = false {
        didSet {
            tableView.reloadSections([0], with: .none)
        }
    }
    
    // Controls if buttons / space are visible
    var shouldShowOutageCell = true {
        didSet {
            tableView.reloadSections([0], with: .none)
        }
    }

    
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
        

        // Events
        
        viewModel.stormModeEnded
            .drive(onNext: { [weak self] in self?.stormModeEnded() })
            .disposed(by: disposeBag)
        
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.updateContent(outageJustReported: true) })
            .disposed(by: disposeBag)
        
        Observable.merge(noNetworkConnectionView.reload)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.getOutageStatus() })
            .disposed(by: disposeBag)
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            switch(state) {
            case .loadingAccounts:
                self.outageStatusButton.isHidden = true
                self.gasOnlyView.isHidden = true
                self.finalPayView.isHidden = true
                self.noNetworkConnectionView.isHidden = true
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
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Self Sizes Table View Header
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
        getOutageStatus(didPullToRefresh: true)
    }
    
    @IBAction func payButtonPress(_ sender: Any) {
        performSegue(withIdentifier: "BillSegue", sender: nil)
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
    
    private func getOutageStatus(didPullToRefresh: Bool = false) {
        if !didPullToRefresh {
            loadingContentView.isHidden = false
            shouldShowOutageCellData = false
            outageStatusButton.isHidden = true
            noNetworkConnectionView.isHidden = true
            gasOnlyView.isHidden = true
            finalPayView.isHidden = true
            loadingView.isHidden = false
            scrollView?.isHidden = false
            setRefreshControlEnabled(enabled: false)
        }
        
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            
            if didPullToRefresh {
                self.refreshControl?.endRefreshing()
            }

            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            self.shouldShowOutageCellData = true
            self.noNetworkConnectionView.isHidden = true
            self.scrollView?.isHidden = false
            self.loadingView.isHidden = true
            self.setRefreshControlEnabled(enabled: true)
            self.updateContent(outageJustReported: false)
            }, onError: { [weak self] serviceError in
                guard let `self` = self else { return }
                
                if didPullToRefresh {
                    self.refreshControl?.endRefreshing()
                }
                
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
                if serviceError.serviceCode == ServiceErrorCode.noNetworkConnection.rawValue {
                    self.scrollView?.isHidden = true
                    self.noNetworkConnectionView.isHidden = false
                } else {
                    self.scrollView?.isHidden = false
                    self.noNetworkConnectionView.isHidden = true
                }
                
                self.loadingContentView.isHidden = true
                self.loadingView.isHidden = true
                self.setRefreshControlEnabled(enabled: true)
            })
    }
    
    private func returnToMainApp() {
        guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
        StormModeStatus.shared.isOn = false
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController()
    }
    
    private func updateContent(outageJustReported: Bool) {
        guard let currentOutageStatus = viewModel.currentOutageStatus  else { return }

        // Show/hide the top level container views
        if currentOutageStatus.flagGasOnly {
            gasOnlyView.isHidden = false
            footerTextView.isHidden = true
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            shouldShowOutageCellData = false
            shouldShowOutageCell = false
        } else {
            gasOnlyView.isHidden = true
            footerTextView.isHidden = false
            shouldShowOutageCellData = true
            shouldShowOutageCell = true
            
            self.loadingContentView.isHidden = false
            outageStatusButton.onLottieAnimation?.animationProgress = 0.0
            outageStatusButton.onLottieAnimation?.play()
            
            outageStatusButton.isHidden = false
        }
        
        layoutBigButtonContent(outageJustReported: outageJustReported)
    }
    
    private func layoutBigButtonContent(outageJustReported: Bool) {
        let currentOutageStatus = viewModel.currentOutageStatus!
        
        if outageJustReported && viewModel.reportedOutage != nil {
            outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.activeOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay || currentOutageStatus.flagNonService {
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            finalPayView.isHidden = false
            finalPayTextView.text = viewModel.accountNonPayFinaledMessage
            
            finalPayButton.isHidden = currentOutageStatus.flagFinaled ? true : false
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
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
    
    @objc private func killRefresh() -> Void {
        refreshControl?.endRefreshing()
        scrollView!.alwaysBounceVertical = false
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UpdatesDetailViewController {
            vc.opcoUpdate = OpcoUpdate(title: NSLocalizedString("Storm Mode is in effect", comment: ""), message: NSLocalizedString("Due to severe weather, limited features are available to allow us to better serve you.", comment: ""))
        } else if let vc = segue.destination as? ReportOutageViewController {
            navigationController?.setNavigationBarHidden(false, animated: false) // may be able to refactor this out into the root of prep for segue
            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
            
            guard let phone = viewModel.currentOutageStatus!.contactHomeNumber else { return }
            vc.viewModel.phoneNumber.value = phone
        } else if let vc = segue.destination as? OutageMapViewController {
            navigationController?.setNavigationBarHidden(false, animated: false)
            vc.hasPressedStreetlightOutageMapButton = false
        } else if let vc = segue.destination as? BillViewController {
            vc.shouldHideNavigationBar = false
            navigationController?.setNavigationBarHidden(false, animated: false)
        } else if let vc = segue.destination as? MoreViewController {
            vc.shouldHideNavigationBar = false
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
}


// MARK: - Delegate Actions

extension StormModeHomeViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        getOutageStatus()
    }
    
}

extension StormModeHomeViewController: OutageStatusButtonDelegate {
    
    func outageStatusButtonWasTapped(_ outageStatusButton: OutageStatusButton) {
        Analytics.log(event: .outageStatusDetails)
        
        if let message = viewModel.currentOutageStatus!.outageDescription {
            presentAlert(title: nil, message: message, style: .alert, actions: [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)])
        }
    }
    
}

extension StormModeHomeViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        Analytics.log(event: .outageAuthEmergencyCall)
    }
    
}
