//
//  StormModeHomeViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 8/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import Lottie
import UIKit

class StormModeHomeViewController: AccountPickerViewController {
        
    @IBOutlet private weak var gradientView: UIView!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet private weak var exitView: UIView! {
        didSet {
            exitView.isHidden = true
        }
    }

    @IBOutlet private weak var exitTextLabel: UILabel!
    @IBOutlet private weak var exitButton: ButtonControl! {
        didSet {
            exitButton.layer.cornerRadius = 10.0
            exitButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            exitButton.backgroundColorOnPress = .softGray
            exitButton.accessibilityLabel = NSLocalizedString("Exit storm mode", comment: "")
        }
    }
    
    @IBOutlet private weak var headerContentView: ButtonControl! {
        didSet {
            headerContentView.layer.cornerRadius = 10.0
            headerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    
    @IBOutlet private weak var headerViewTitleLabel: UILabel! {
        didSet {
            headerViewTitleLabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    @IBOutlet private weak var headerViewDescriptionLabel: UILabel! {
        didSet {
            headerViewDescriptionLabel.font = OpenSans.regular.of(textStyle: .footnote)
        }
    }
    
    @IBOutlet private weak var headerCaretImageView: UIImageView!
    
    
    @IBOutlet weak var footerStackView: UIStackView!
    @IBOutlet weak var contactGroup1StackView: UIStackView!
    @IBOutlet weak var group1Label: UILabel! {
        didSet {
            group1Label.font = OpenSans.regular.of(textStyle: .subheadline)
        }
    }
    @IBOutlet weak var phone1Button: ButtonControl! {
        didSet {
            phone1Button.roundCorners(.allCorners, radius: 12)
            phone1Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    @IBOutlet weak var phone1Label: UILabel!
    @IBOutlet weak var phone2Button: ButtonControl! {
        didSet {
            phone2Button.roundCorners(.allCorners, radius: 12)
            phone2Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            phone2Button.isHidden = Configuration.shared.opco != .bge
        }
    }
    @IBOutlet weak var phone2Label: UILabel!
    @IBOutlet weak var contactGroup2StackView: UIStackView! {
        didSet {
            contactGroup2StackView.isHidden = Configuration.shared.opco != .bge && Configuration.shared.opco != .delmarva
        }
    }
    @IBOutlet weak var group2Label: UILabel! {
        didSet {
            group2Label.font = OpenSans.regular.of(textStyle: .subheadline)
        }
    }
    @IBOutlet weak var phone3Button: ButtonControl! {
        didSet {
            phone3Button.roundCorners(.allCorners, radius: 12)
            phone3Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    @IBOutlet weak var phone3Label: UILabel!
    @IBOutlet weak var phone4Button: ButtonControl! {
        didSet {
            phone4Button.roundCorners(.allCorners, radius: 12)
            phone4Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    @IBOutlet weak var phone4Label: UILabel!
    
    @IBOutlet private weak var gasOnlyView: UIView!
    @IBOutlet private weak var gasOnlyTitleLabel: UILabel! {
        didSet {
            gasOnlyTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var gasOnlyDetailLabel: UILabel! {
        didSet {
            gasOnlyDetailLabel.font = OpenSans.regular.of(textStyle: .subheadline)
            gasOnlyDetailLabel.text = viewModel.gasOnlyMessage
        }
    }
    
    @IBOutlet private weak var gasOnlyPhone1Button: ButtonControl! {
        didSet {
            gasOnlyPhone1Button.roundCorners(.allCorners, radius: 4)
            gasOnlyPhone1Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            gasOnlyPhone1Button.isHidden = Configuration.shared.opco == .comEd
        }
    }
    @IBOutlet private weak var gasOnlyPhone1Label: UILabel!
    
    @IBOutlet private weak var gasOnlyPhone2Button: ButtonControl! {
        didSet {
            gasOnlyPhone2Button.roundCorners(.allCorners, radius: 4)
            gasOnlyPhone2Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
            gasOnlyPhone2Button.isHidden = Configuration.shared.opco != .bge
        }
    }
    @IBOutlet private weak var gasOnlyPhone2Label: UILabel!
    
    
    @IBOutlet private weak var finalPayView: UIView!
    @IBOutlet private weak var finalPayTitleLabel: UILabel! {
        didSet {
            finalPayTitleLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var finalPayTextView: ZeroInsetDataDetectorTextView! {
        didSet {
            finalPayTextView.font = OpenSans.regular.of(textStyle: .subheadline)
            finalPayTextView.tintColor = .white
        }
    }
    
    @IBOutlet private weak var finalPayButtonContainer: UIView!
    @IBOutlet private weak var finalPayButton: ButtonControl! {
        didSet {
            finalPayButton.layer.cornerRadius = 10.0
            finalPayButton.accessibilityLabel = NSLocalizedString("Pay bill", comment: "")
            finalPayButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    
    @IBOutlet private weak var finalPayButtonLabel: UILabel! {
        didSet {
            finalPayButtonLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var accountDisallowView: UIView!
    @IBOutlet private weak var accountDisallowIconImageView: UIImageView! {
        didSet {
            // Apply different colors for ADA contrast compliance (ComEd default color is already compliant)
            accountDisallowIconImageView.image = UIImage(named: "ic_lock_opco")?.withRenderingMode(.alwaysTemplate)
            if Configuration.shared.opco == .bge {
                accountDisallowIconImageView.tintColor = UIColor(red: 102/255, green: 179/255, blue: 96/255, alpha: 1)
            } else if Configuration.shared.opco == .peco {
                accountDisallowIconImageView.tintColor = UIColor(red: 0, green: 162/255, blue: 1, alpha: 1)
            }
        }
    }
    
    /// Outage Trcker
    @IBOutlet private weak var outageTrackerStackView: UIStackView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var hazardContainerView: UIView!
    @IBOutlet weak var hazardView: UIView!
    @IBOutlet weak var progressAnimationView: StateAnimationView!
    @IBOutlet weak var statusTextView: StatusTextView!
    @IBOutlet weak var whyButtonContainer: UIView!
    @IBOutlet weak var whyButtonView: UIView!
    @IBOutlet weak var whyButton: UIButton!
    @IBOutlet weak var etaContainerView: UIView!
    @IBOutlet weak var etaView: ETAView!
    @IBOutlet weak var countContainerView: UIView!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var neighborCountLabel: UILabel!
    @IBOutlet weak var outageCountLabel: UILabel!
    @IBOutlet weak var trackerStatusContainer: UIView!
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    @IBOutlet weak var surveyView: SurveyView!
    @IBOutlet weak var powerOnContainer: UIView!
    @IBOutlet weak var hazardWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var etaWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var countWidthConstraint: NSLayoutConstraint!
    
    let infoView = StatusInfoView()
    
    /// This houses both the outage status button and the loading view for the button
    @IBOutlet private weak var loadingContentView: UIView!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var loadingBackgroundView: UIView!
    @IBOutlet private weak var loadingAnimationView: UIView!
    @IBOutlet private weak var outageStatusButton: OutageStatusButton!
    @IBOutlet private weak var noNetworkConnectionView: NoNetworkConnectionView!
    
    @IBOutlet private weak var outageSectionContainer: UIView!
    @IBOutlet private weak var reportOutageButton: DisclosureCellButton!
    @IBOutlet private weak var outageMapButton: DisclosureCellButton! {
        didSet {
            outageMapButton.configure(image: #imageLiteral(resourceName: "ic_mapoutagewhite"), text: NSLocalizedString("View Outage Map", comment: ""))
        }
    }
    @IBOutlet weak var reportStreetlightOutageButton: DisclosureCellButton! {
        didSet {
            reportStreetlightOutageButton.configure(image: #imageLiteral(resourceName: "ic_streetlightoutage_white"), text: Configuration.shared.opco.isPHI ? NSLocalizedString("Report Street Light Problem", comment: "") : NSLocalizedString("Report Street Light Outage", comment: ""))
        }
    }
    
    
    @IBOutlet private weak var moreOptionsLabel: UILabel! {
        didSet {
            moreOptionsLabel.font = OpenSans.semibold.of(textStyle: .title1)
        }
    }
    
    @IBOutlet private weak var billButton: DisclosureCellButton! {
        didSet {
            billButton.configure(image: #imageLiteral(resourceName: "ic_nav_bill_white"), text: NSLocalizedString("Bill", comment: ""))
        }
    }
    
    @IBOutlet private weak var moreButton: DisclosureCellButton! {
        didSet {
            moreButton.configure(image: #imageLiteral(resourceName: "ic_nav_more_white"), text: NSLocalizedString("More", comment: ""))
        }
    }
    
    private var loadingLottieAnimation = AnimationView(name: "sm_outage_loading-Flavor\(Configuration.shared.opco.rawValue)")
    private var refreshControl: UIRefreshControl?
    
    let viewModel = StormModeHomeViewModel()
    
    let disposeBag = DisposeBag()
    var stormModePollingDisposable: Disposable?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureFeatureFlags()
        
        view.backgroundColor = .stormModeBlack
        
        let gradientColor: UIColor
        switch Configuration.shared.opco {
        case .bge:
            gradientColor = .bgeGreen
            setupBinding()
        case .ace, .comEd, .delmarva, .peco, .pepco:
            gradientColor = .primaryColor
        }
        
        gradientLayer.colors = [
            gradientColor.cgColor,
            gradientColor.withAlphaComponent(0).cgColor
        ]
        
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        outageStatusButton.delegate = self
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopMode = .loop
        loadingLottieAnimation.backgroundBehavior = .pauseAndRestore
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        
        viewModel.getStormModeUpdate()
        
        configureContactText()
        configureGasOnlyText()
        configureOutageTracker()
        
        // Events
        RxNotifications.shared.outageReported.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.updateContent(outageJustReported: true) })
            .disposed(by: disposeBag)
        
        Observable.merge(noNetworkConnectionView.reload)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.getOutageStatus() })
            .disposed(by: disposeBag)
        
        outageSectionContainer.isHidden = true
        outageStatusButton.isHidden = true
        gasOnlyView.isHidden = true
        finalPayView.isHidden = true
        accountDisallowView.isHidden = true
        footerStackView.isHidden = true
        noNetworkConnectionView.isHidden = true
        setRefreshControlEnabled(enabled: false)
        
        self.scrollView?.isHidden = true
        self.loadingIndicator.isHidden = false
        
        viewModel.stormModeUpdate.asDriver().isNil().drive(onNext: { [weak self] noUpdate in
            self?.headerCaretImageView.isHidden = noUpdate
            self?.headerContentView.accessibilityTraits = noUpdate ? .staticText : .button
        }).disposed(by: disposeBag)
        
        Driver.merge(reportOutageButton.rx.touchUpInside.asDriver().mapTo("ReportOutageSegue"),
                     outageMapButton.rx.touchUpInside.asDriver().mapTo("OutageMapSegue"),
                     billButton.rx.touchUpInside.asDriver().mapTo("BillSegue"),
                     moreButton.rx.touchUpInside.asDriver().mapTo("MoreSegue"),
                     reportStreetlightOutageButton.rx.touchUpInside.asDriver().mapTo("ReportStreetlightProblemSegue"))
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: $0, sender: nil)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.didTapOnPushNotification, object: nil)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.navigateToAlerts()
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         
        // Start polling when the home screen appears, only if storm mode hasn't ended yet
        stormModePollingDisposable?.dispose()
        if !viewModel.stormModeEnded {
            stormModePollingDisposable = viewModel.startStormModePolling()
                .drive(onNext: { [weak self] in self?.stormModeDidEnd() })
        }
       
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop polling when the home screen is left
        stormModePollingDisposable?.dispose()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = gradientView.bounds
        loadingBackgroundView.layer.cornerRadius = loadingBackgroundView.frame.height / 2
    }
    
    // MARK: Outage Tracker
    
    
    private func configureOutageTracker() {
        infoView.frame = self.view.bounds
        self.view.addSubview(infoView)
        self.infoView.delegate = self
        self.infoView.isHidden = true
        self.whyButtonContainer.isHidden = true
        
        etaView.delegate = self
        surveyView.delegate = self
        
        let whyViewRadius = whyButtonView.frame.size.height / 2
        whyButtonView.roundCorners(.allCorners, radius: whyViewRadius, borderColor: .white, borderWidth: 1.0)
        
        countView.roundCorners(.allCorners, radius: 10, borderColor: .white, borderWidth: 1.0)
        
        hazardView.roundCorners(.allCorners, radius: 10, borderColor: .clear, borderWidth: 1.0)
    }
    
    private func setupBinding() {
        self.viewModel.outageTracker
            .subscribe(onNext: { [weak self] _ in
                self?.update()
            })
            .disposed(by: self.disposeBag)
    }
    
    private func update() {
        statusTextView.isHidden = true
        etaContainerView.isHidden = true
        countContainerView.isHidden = true
        trackerStatusContainer.isHidden = true
        surveyView.isHidden = true
        hazardContainerView.isHidden = true
        hazardWidthConstraint.constant = headerContentView.frame.width
        etaWidthConstraint.constant = headerContentView.frame.width
        countWidthConstraint.constant = headerContentView.frame.width

        if let tracker = viewModel.outageTracker.value {
            var show = tracker.isSafetyHazard ?? false
            if viewModel.status == .restored {
                show = false
            }
            hazardContainerView.isHidden = !show
        }
        
        if viewModel.isActiveOutage == false {
            powerOnContainer.isHidden = false
            progressAnimationView.configure(withStatus: .restored)
        } else {
            powerOnContainer.isHidden = true
            progressAnimationView.configure(withStatus: viewModel.status)
            
            statusTextView.isHidden = false
            statusTextView.configure(tracker: viewModel.outageTracker.value, status: viewModel.status)
            
            if viewModel.status != .none {
                etaContainerView.isHidden = false
                countContainerView.isHidden = false
                trackerStatusContainer.isHidden = false
                surveyView.isHidden = false
                
                surveyView.configure(status: viewModel.status)
                
                if viewModel.status == .restored {
                    countContainerView.isHidden = true
                }
                
                whyButtonContainer.isHidden = viewModel.hideWhyButton
                whyButton.setTitle(viewModel.whyButtonText, for: .normal)
                neighborCountLabel.text = viewModel.neighborCount
                outageCountLabel.text = viewModel.outageCount
                updateETA()
                
                if viewModel.events.isEmpty {
                    trackerStatusContainer.isHidden = true
                } else {
                    trackerStatusContainer.isHidden = false
                    trackerStatusView.configure(withEvents: viewModel.events, lastUpdated: viewModel.lastUpdated, isPaused: viewModel.isPaused)
                }
            }
        }
        
        scrollView?.isHidden = false
        loadingIndicator.isHidden = true
    }
    
    private func updateETA() {
        guard let tracker = viewModel.outageTracker.value else { return }
        etaView.configure(tracker: tracker, status: viewModel.status)
    }
    
    @IBAction func showHazardPressed(_ sender: Any) {
        let info = StatusInfoMessage.hazardMessage
        infoView.configure(withInfo: info)
        infoView.isHidden = false
    }
    
    @IBAction func whyButtonPressed(_ sender: Any) {
        guard let tracker = viewModel.outageTracker.value else { return }
        guard let isCrewLeftSite = tracker.isCrewLeftSite,
              let isCrewDiverted = tracker.isCrewDiverted else {
                  return
              }
        
        var info = StatusInfoMessage.none
        
        if isCrewDiverted {
            info = StatusInfoMessage.rerouted
        }
        if isCrewLeftSite {
            info = StatusInfoMessage.whyStop
        }
        if viewModel.status == .restored {
            info = viewModel.isDefinitive ? StatusInfoMessage.hasOutageDef : StatusInfoMessage.hasOutageNondef
        }
        if info != .none {
            infoView.configure(withInfo: info)
            infoView.isHidden = false
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func showStormModeDetails(_ sender: Any) {
        if viewModel.stormModeUpdate.value != nil {
            performSegue(withIdentifier: "UpdatesDetailSegue", sender: nil)
            FirebaseUtility.logEvent(.stormOutage(parameters: [.view_details]))

        }
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
    
    @IBAction func onPhoneNumberPress(_ sender: ButtonControl) {
        let phone: String?
        switch sender {
        case phone1Button:
            phone = phone1Label.text
        case phone2Button:
            phone = phone2Label.text
        case phone3Button:
            phone = phone3Label.text
        case phone4Button:
            phone = phone4Label.text
        case gasOnlyPhone1Button:
            phone = gasOnlyPhone1Label.text
        case gasOnlyPhone2Button:
            phone = gasOnlyPhone2Label.text
        default:
            phone = nil // Won't happen
        }
        
        if let phone = phone, let url = URL(string: "telprompt://\(phone)"), UIApplication.shared.canOpenURL(url) {
            GoogleAnalytics.log(event: .outageAuthEmergencyCall)
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Helper
    
    private func configureContactText() {
        switch Configuration.shared.opco {
        case .bge:
            group1Label.text = NSLocalizedString("If you smell natural gas, leave the area immediately and call", comment: "")
            group2Label.text = NSLocalizedString("For downed or sparking power lines, please call", comment: "")
            phone1Label.text = "1-800-685-0123"
            phone2Label.text = "1-877-778-7798"
            phone3Label.text = "1-800-685-0123"
            phone4Label.text = "1-877-778-2222"
        case .comEd:
            group1Label.text = NSLocalizedString("To report a downed or sparking power line, please call", comment: "")
            phone1Label.text = "1-800-334-7661"
        case .peco:
            group1Label.text = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call", comment: "")
            phone1Label.text = "1-800-841-4141"
        case .ace, .delmarva, .pepco:
            if AccountsStore.shared.accountOpco == .ace {
                group1Label.text = NSLocalizedString("If you see downed power lines, leave the area immediately and call \(Configuration.shared.opco.displayString) at ", comment: "")
                phone1Label.text = "1-800-833-7476"
                
                group2Label.isHidden = true
                phone2Label.isHidden = true
                phone3Label.isHidden = true
                phone4Label.isHidden = true
                phone2Button.isHidden = true
                phone3Button.isHidden = true
                phone3Button.isHidden = true
                phone4Button.isHidden = true

            } else if AccountsStore.shared.accountOpco == .delmarva {
                group1Label.text = NSLocalizedString("If you smell natural gas, leave the area immediately and then call ", comment: "")
                
                group2Label.text = NSLocalizedString("If you see downed power lines, leave the area immediately and call \(Configuration.shared.opco.displayString) at ", comment: "")
                phone1Label.text = "302-454-0317"
                phone3Label.text = "1-800-898-8042"
                
                group2Label.isHidden = false
                phone2Label.isHidden = true
                phone3Label.isHidden = false
                phone4Label.isHidden = true
                phone2Button.isHidden = true
                phone3Button.isHidden = false
                phone4Button.isHidden = true

            } else if AccountsStore.shared.accountOpco == .pepco {
                group1Label.text = NSLocalizedString("If you see downed power lines, leave the area immediately and call \(Configuration.shared.opco.displayString) at ", comment: "")
                phone1Label.text = "1-877-737-2662"
               
                group2Label.isHidden = true
                phone2Label.isHidden = true
                phone3Label.isHidden = true
                phone4Label.isHidden = true
                phone2Button.isHidden = true
                phone3Button.isHidden = true
                phone3Button.isHidden = true
                phone4Button.isHidden = true
            }
        }
        
        phone1Button.accessibilityLabel = phone1Label.text
        phone2Button.accessibilityLabel = phone2Label.text
        phone3Button.accessibilityLabel = phone3Label.text
        phone4Button.accessibilityLabel = phone4Label.text
    }
    
    private func configureGasOnlyText() {
        switch Configuration.shared.opco {
        case .bge:
            gasOnlyPhone1Label.text = "1-800-685-0123"
            gasOnlyPhone2Label.text = "1-877-778-7798"
        case .comEd:
            gasOnlyPhone1Label.text = ""
        case .peco:
            gasOnlyPhone1Label.text = "1-800-841-4141"
        case .ace, .pepco, .delmarva:
            if AccountsStore.shared.accountOpco == .ace || AccountsStore.shared.accountOpco == .pepco {
                gasOnlyPhone1Label.text = ""
                gasOnlyPhone1Button.isHidden = true
            } else {
                gasOnlyPhone1Label.text = "302-454-0317"
                gasOnlyPhone1Button.isHidden = false
            }
        }
        
        gasOnlyPhone1Button.accessibilityLabel = gasOnlyPhone1Label.text
        gasOnlyPhone2Button.accessibilityLabel = gasOnlyPhone2Label.text
    }
    
    override func setupUpdatedData() {
        super.setupUpdatedData()
        configureGasOnlyText()
        configureContactText()
    }
    
    private func configureFeatureFlags() {
        FeatureFlagUtility.shared.loadingDoneCallback = { [weak self] in
            self?.viewModel.outageMapURLString = FeatureFlagUtility.shared.string(forKey: .outageMapURL)
            FirebaseUtility.logEvent(.stormOutage(parameters: [.map]))

            if self?.viewModel.outageMapURLString.isEmpty ?? true {
                self?.outageMapButton.isHidden = true
            } else {
                self?.outageMapButton.isHidden = false
            }
        }
    }
    
    private func stormModeDidEnd() {
        let yesAction = UIAlertAction(title: NSLocalizedString("Exit Storm Mode", comment: ""), style: .default)
        { [weak self] _ in
            self?.returnToMainApp()
        }
        
        let noAction = UIAlertAction(title: NSLocalizedString("No, Thanks", comment: ""), style: .cancel)
        { [weak self] _ in
            self?.exitView.isHidden = false
        }
        
        presentAlert(title: NSLocalizedString("Exit Storm Mode", comment: ""),
                     message: NSLocalizedString("All features are now available. Would you like to exit storm mode? You can also do this from the home screen.", comment: ""),
                     style: .alert,
                     actions: [yesAction, noAction])
    }
    
    private func getOutageStatus(didPullToRefresh: Bool = false) {
        self.scrollView?.isHidden = true
        self.loadingIndicator.isHidden = false
        
        if !didPullToRefresh {
            loadingContentView.isHidden = false
            outageSectionContainer.isHidden = true
            outageStatusButton.isHidden = true
            footerStackView.isHidden = true
            noNetworkConnectionView.isHidden = true
            gasOnlyView.isHidden = true
            billButton.isHidden = false
            finalPayView.isHidden = true
            accountDisallowView.isHidden = true
            loadingView.isHidden = false
            setRefreshControlEnabled(enabled: false)
        } else {
            FeatureFlagUtility.shared.fetchCloudValues()
        }
        
        viewModel.fetchData(onSuccess: { [weak self] in
            guard let self = self else { return }
            if didPullToRefresh {
                self.refreshControl?.endRefreshing()
            }

            UIAccessibility.post(notification: .screenChanged, argument: nil)
            self.outageSectionContainer.isHidden = false
            self.noNetworkConnectionView.isHidden = true
            self.loadingView.isHidden = true
            self.finalPayTitleLabel.isHidden = false
            self.setRefreshControlEnabled(enabled: true)
            self.update()
            self.updateContent(outageJustReported: false)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            
            if didPullToRefresh {
                self.refreshControl?.endRefreshing()
            }
            
            UIAccessibility.post(notification: .screenChanged, argument: nil)
            if error == .noNetwork {
                self.scrollView?.isHidden = true
                self.noNetworkConnectionView.isHidden = false
            } else {
                self.scrollView?.isHidden = false
                self.noNetworkConnectionView.isHidden = true
            }
            self.outageSectionContainer.isHidden = true

            if error == .blockAccount {
                self.accountDisallowView.isHidden = false
                self.finalPayView.isHidden = true
                self.billButton.isHidden = true
            } else if error == .inactive {
                self.accountDisallowView.isHidden = true
                self.finalPayView.isHidden = false
                self.finalPayTitleLabel.isHidden = false
                self.finalPayTitleLabel.text = NSLocalizedString("Account Inactive", comment: "")
                self.finalPayTextView.text = NSLocalizedString("Outage Status and Outage reporting are not available for this account.", comment: "")
                self.billButton.isHidden = false
                self.outageSectionContainer.isHidden = false
                self.reportOutageButton.configure(image: #imageLiteral(resourceName:  "ic_reportoutagewhite"), text: NSLocalizedString("Report Outage", comment: ""), enabled: false)
            } else {
                self.accountDisallowView.isHidden = true
                self.finalPayView.isHidden = false
                self.finalPayTitleLabel.isHidden = !Configuration.shared.opco.isPHI
                self.finalPayTitleLabel.text = NSLocalizedString("Outage Unavailable", comment: "")
                self.finalPayTextView.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
                self.billButton.isHidden = false
            }
            
            self.loadingContentView.isHidden = true
            self.finalPayButtonContainer.isHidden = true
            
            self.footerStackView.isHidden = false
            self.loadingView.isHidden = true
            self.setRefreshControlEnabled(enabled: true)
        })
    }
    
    @IBAction func accountpress(_ sender: Any) {
        guard let vc = UIStoryboard(name: "AccountSheet", bundle: .main).instantiateInitialViewController() else { return }
        vc.modalPresentationStyle = .overCurrentContext
        present(vc, animated: false, completion: nil)
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
        if currentOutageStatus.isGasOnly {
            gasOnlyView.isHidden = false
            footerStackView.isHidden = true
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            outageSectionContainer.isHidden = true
            outageTrackerStackView.isHidden = true
        } else {
            finalPayView.isHidden = true
            gasOnlyView.isHidden = true
            footerStackView.isHidden = false
            outageSectionContainer.isHidden = false
            
            if viewModel.showOutageTracker {
                loadingContentView.isHidden = true
                outageStatusButton.isHidden = true
                outageTrackerStackView.isHidden = false
            } else {
                outageStatusButton.onLottieAnimation?.currentProgress = 0.0
                outageStatusButton.onLottieAnimation?.play()
                outageTrackerStackView.isHidden = true
                loadingContentView.isHidden = false
                outageStatusButton.isHidden = false
                scrollView?.isHidden = false
                loadingIndicator.isHidden = true
            }
        }
        
        headerContentView.accessibilityLabel = viewModel.headerContentText
        headerViewDescriptionLabel.text = viewModel.headerContentText
        
        if viewModel.reportedOutage != nil {
            // Reported State
            reportOutageButton.configure(image: #imageLiteral(resourceName: "ic_check_outage_white"), text: NSLocalizedString("Report Outage", comment: ""), detailText: viewModel.outageReportedDateString)
        } else {
            // Regular State
            reportOutageButton.configure(image: #imageLiteral(resourceName:  "ic_reportoutagewhite"), text: NSLocalizedString("Report Outage", comment: ""), enabled: viewModel.reportOutageEnabled)
        }
        
        layoutBigButtonContent(outageJustReported: outageJustReported)
    }
    
    private func layoutBigButtonContent(outageJustReported: Bool) {
        let currentOutageStatus = viewModel.currentOutageStatus!
        
        if outageJustReported && viewModel.reportedOutage != nil {
            outageStatusButton.setReportedState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
            FirebaseUtility.logEvent(.stormOutage(parameters: [.report_complete]))
        } else if currentOutageStatus.isFinaled || currentOutageStatus.isNoPay || currentOutageStatus.isNonService {
            loadingContentView.isHidden = true
            outageStatusButton.isHidden = true
            finalPayView.isHidden = false
            finalPayTextView.text = viewModel.accountNonPayFinaledMessage
            finalPayButtonContainer.isHidden = !currentOutageStatus.isNoPay
        } else if currentOutageStatus.isActiveOutage {
            outageStatusButton.setOutageState(estimatedRestorationDateString: viewModel.estimatedRestorationDateString)
        } else { // Power is on
            outageStatusButton.setPowerOnState()
        }
    }
    
    private func setRefreshControlEnabled(enabled: Bool) {
        if let rc = refreshControl {
            rc.endRefreshing()
            rc.removeFromSuperview()
            refreshControl = nil
        }
        
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl?.tintColor = .white
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            scrollView!.insertSubview(refreshControl!, at: 0)
            scrollView!.alwaysBounceVertical = true
        } else {
            scrollView!.alwaysBounceVertical = false
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UpdatesDetailViewController, let stormUpdate = viewModel.stormModeUpdate.value {
            vc.opcoUpdate = stormUpdate
        } else if let vc = segue.destination as? ReportOutageViewController,
            let outageStatus = viewModel.currentOutageStatus {
            vc.viewModel.outageStatus = outageStatus
            vc.viewModel.phoneNumber.accept(outageStatus.contactHomeNumber ?? "")
        } else if let vc = segue.destination as? OutageMapViewController {
            vc.hasPressedStreetlightOutageMapButton = segue.identifier == "ReportStreetlightProblemSegue" ? true : false
                if segue.identifier == "ReportStreetlightProblemSegue" {
                    FirebaseUtility.logEvent(.stormOutage(parameters: [.streetlight_map]))
             }

        }
    }
    
    func navigateToAlerts() {
        let moreStoryboard = UIStoryboard(name: "More", bundle: nil)
        let alertsStoryboard = UIStoryboard(name: "Alerts", bundle: nil)
        
        guard let moreVC = moreStoryboard.instantiateInitialViewController() as? MoreViewController,
            let alertsVC = alertsStoryboard.instantiateInitialViewController()
            else { return }
        
        navigationController?.viewControllers = [self, moreVC, alertsVC]
    }
        
    func navigateToAlertPreferences() {
        let moreStoryboard = UIStoryboard(name: "More", bundle: nil)
        let alertsStoryboard = UIStoryboard(name: "Alerts", bundle: nil)
        
        guard let navCtl = navigationController,
            let moreVC = moreStoryboard.instantiateInitialViewController() as? MoreViewController,
            let alertsVC = alertsStoryboard.instantiateInitialViewController() as? AlertsViewController
            else { return }
        
        alertsVC.shortcutToPrefs = true
        navCtl.viewControllers = [self, moreVC, alertsVC]
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
        GoogleAnalytics.log(event: .outageStatusDetails)
        
        if let message = viewModel.currentOutageStatus!.outageDescription {
            presentAlert(title: nil, message: message, style: .alert, actions: [UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)])
        }
    }
    
}

extension StormModeHomeViewController: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        GoogleAnalytics.log(event: .outageAuthEmergencyCall)
    }
}

extension StormModeHomeViewController: StatusInfoViewDelegate {
    func dismissInfoView() {
        infoView.isHidden = true
    }
    func reportOutagePressed() {
        self.performSegue(withIdentifier: "ReportOutageSegue", sender: nil)
        FirebaseUtility.logEvent(.stormOutage(parameters: [.report_outage]))

    }
}

extension StormModeHomeViewController: ETAViewDelegate {
    func showInfoView() {
        let info = StatusInfoMessage.etrToolTip
        infoView.configure(withInfo: info)
        infoView.isHidden = false
    }
}

extension StormModeHomeViewController: SurveyViewDelegate {
    func surveySelected(url: URL) {
        let survey = WebViewController(title: NSLocalizedString("", comment: ""),
                                       url: url)
        navigationController?.present(survey, animated: true, completion: nil)
    }
}
