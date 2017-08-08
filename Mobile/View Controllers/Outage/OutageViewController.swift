//
//  OutageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import Lottie

class OutageViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var gradientBackground: UIView!
    @IBOutlet weak var scrollViewContentView: UIView!
    @IBOutlet weak var accountContentView: UIView!
    @IBOutlet weak var gasOnlyView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingAnimationView: UIView!
    @IBOutlet weak var loadingBigButtonView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var bigButtonShadowView: UIView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var outerCircleView: UIView!
    @IBOutlet weak var innerCircleView: UIView!
    @IBOutlet weak var bigButtonView: UIView!
    @IBOutlet weak var reportOutageButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    @IBOutlet weak var gasOnlyTextView: DataDetectorTextView!
    @IBOutlet weak var footerTextView: DataDetectorTextView!
    
    // We keep track of this constraint because AutoLayout uses it to calculate the height of the scrollView's content
    // When the gasOnlyView is hidden, we do not want it's height to impact the scrollView content size (the normal outage
    // view does not need to scroll on iPhone 7 size), so we use this to toggle active/inactive. Cannot be weak reference
    // because setting isActive = false would set to nil
    @IBOutlet var gasOnlyTextViewBottomSpaceConstraint: NSLayoutConstraint!

    var gradientLayer: CAGradientLayer!
    
    var onLottieAnimation = LOTAnimationView(name: "outage")!
    var loadingLottieAnimation = LOTAnimationView(name: "outage_loading")!
    var refreshControl: UIRefreshControl?
    
    let viewModel = OutageViewModel(accountService: ServiceFactory.createAccountService(), outageService: ServiceFactory.createOutageService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Outage", comment: "")

        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientBackground.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 244/255, green: 246/255, blue: 247/255, alpha: 1).cgColor,
            UIColor(red: 240/255, green: 242/255, blue: 243/255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientBackground.layer.addSublayer(gradientLayer)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        onLottieAnimation.frame = CGRect(x: 0, y: 0, width: animationView.frame.size.width, height: animationView.frame.size.height)
        onLottieAnimation.loopAnimation = true
        onLottieAnimation.contentMode = .scaleAspectFill
        animationView.addSubview(onLottieAnimation)
        onLottieAnimation.play()
        
        loadingLottieAnimation.frame = CGRect(x: 0, y: 0, width: loadingAnimationView.frame.size.width, height: loadingAnimationView.frame.size.height)
        loadingLottieAnimation.loopAnimation = true
        loadingLottieAnimation.contentMode = .scaleAspectFill
        loadingAnimationView.addSubview(loadingLottieAnimation)
        loadingLottieAnimation.play()
        
        outerCircleView.layer.cornerRadius = outerCircleView.bounds.size.width / 2
        innerCircleView.layer.cornerRadius = innerCircleView.bounds.size.width / 2
        
        let radius = bigButtonView.bounds.size.width / 2
        bigButtonView.layer.cornerRadius = radius
        bigButtonView.clipsToBounds = true // So text doesn't overflow
        bigButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBigButtonTap)))
        bigButtonView.isAccessibilityElement = true
        bigButtonView.accessibilityTraits = UIAccessibilityTraitButton
        
        bigButtonShadowView.layer.cornerRadius = radius
        bigButtonShadowView.addShadow(color: .black, opacity: 0.3, offset: CGSize(width: 0, height: 10), radius: 10) // Blur of 20pt
        bigButtonView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: (radius + 2) * 2, height: (radius + 2) * 2), cornerRadius: radius).cgPath // Spread of 2pt
        
        loadingBigButtonView.layer.cornerRadius = radius
        loadingBigButtonView.addShadow(color: .black, opacity: 0.3, offset: CGSize(width: 0, height: 10), radius: 10) // Blur of 20pt
        loadingBigButtonView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: (radius + 2) * 2, height: (radius + 2) * 2), cornerRadius: radius).cgPath // Spread of 2pt
        
        footerTextView.font = SystemFont.regular.of(textStyle: .headline)
        footerTextView.textContainerInset = .zero
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
        footerTextView.text = viewModel.getFooterTextViewText()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handlePhoneCallTap(_:)))
        footerTextView.addGestureRecognizer(tap)
        
        gasOnlyTextView.font = SystemFont.regular.of(textStyle: .body)
        gasOnlyTextView.textContainerInset = .zero
        gasOnlyTextView.tintColor = .actionBlue
        gasOnlyTextView.text = viewModel.getGasOnlyMessage()
        
        accountPickerViewControllerWillAppear.subscribe(onNext: { state in
            switch(state) {
            case .loadingAccounts:
                self.accountContentView.isHidden = true
                self.gasOnlyTextViewBottomSpaceConstraint.isActive = false
                self.gasOnlyView.isHidden = true
                self.errorLabel.isHidden = true
                self.loadingView.isHidden = true
                self.loadingView.accessibilityViewIsModal = false
                self.setRefreshControlEnabled(enabled: false)
            case .readyToFetchData:
                if AccountsStore.sharedInstance.currentAccount != self.accountPicker.currentAccount {
                    self.getOutageStatus()
                } else if self.viewModel.currentOutageStatus == nil {
                    self.getOutageStatus()
                }
            }
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(killRefresh), name: NSNotification.Name.DidMaintenanceModeTurnOn, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = gradientBackground.frame
    }
    
    func killRefresh() -> Void {
        self.refreshControl?.endRefreshing()
        self.scrollView.alwaysBounceVertical = false
    }
    
    func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            scrollView.insertSubview(refreshControl!, at: 0)
            scrollView.alwaysBounceVertical = true
        } else {
            if let rc = refreshControl {
                rc.endRefreshing()
                rc.removeFromSuperview()
                refreshControl = nil
            }
            scrollView.alwaysBounceVertical = false
        }
    }
    
    func updateContent() {
        layoutBigButtonContent()
        
        let currentOutageStatus = viewModel.currentOutageStatus!
        
        errorLabel.isHidden = true
        
        // Show/hide the top level container views
        if currentOutageStatus.flagGasOnly {
            gasOnlyTextViewBottomSpaceConstraint.isActive = true
            gasOnlyView.isHidden = false
            accountContentView.isHidden = true
        } else {
            gasOnlyTextViewBottomSpaceConstraint.isActive = false
            gasOnlyView.isHidden = true
            accountContentView.isHidden = false
        }
        
        // Display either the Lottie animation or draw our own border circles
        let powerIsOn = !currentOutageStatus.activeOutage && viewModel.getReportedOutage() == nil && !currentOutageStatus.flagNoPay && !currentOutageStatus.flagFinaled && !currentOutageStatus.flagNonService
        animationView.isHidden = !powerIsOn
        outerCircleView.isHidden = powerIsOn
        innerCircleView.isHidden = powerIsOn
        
        if viewModel.getReportedOutage() == nil && (currentOutageStatus.activeOutage || currentOutageStatus.flagNoPay || currentOutageStatus.flagFinaled || currentOutageStatus.flagNonService) {
            outerCircleView.backgroundColor = UIColor(red: 187/255, green: 187/255, blue: 187/255, alpha: 1) // Special case color - do not change
            innerCircleView.backgroundColor = .middleGray
        } else {
            outerCircleView.backgroundColor = UIColor.primaryColor.withAlphaComponent(0.7)
            innerCircleView.backgroundColor = .primaryColor
        }
        
        // Update the Report Outage button
        if viewModel.getReportedOutage() != nil {
            reportOutageButton.setDetailLabel(text: viewModel.getOutageReportedDateString(), checkHidden: false)
            reportOutageButton.accessibilityLabel = String(format: NSLocalizedString("Report outage. %@", comment: ""), viewModel.getOutageReportedDateString())
        } else {
            reportOutageButton.setDetailLabel(text: "", checkHidden: true)
            reportOutageButton.accessibilityLabel = NSLocalizedString("Report outage", comment: "")
        }
        
        // Disable bottom buttons if account is finaled or not paid
        let bottomButtonsEnabled = !currentOutageStatus.flagNoPay && !currentOutageStatus.flagFinaled && !currentOutageStatus.flagNonService
        reportOutageButton.isEnabled = bottomButtonsEnabled
        viewOutageMapButton.isEnabled = bottomButtonsEnabled
    }
    
    func layoutBigButtonContent() {
        for subview in bigButtonView.subviews {
            subview.removeFromSuperview()
        }
        
        let currentOutageStatus = viewModel.currentOutageStatus!
        let bigButtonWidth = bigButtonView.frame.size.width
        
        if viewModel.getReportedOutage() != nil {
            let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 19, y: 27, width: 38, height: 31))
            icon.image = #imageLiteral(resourceName: "ic_outagestatus_reported")
            
            let yourOutageIsLabel = UILabel(frame: CGRect(x: 30, y: 61, width: bigButtonWidth - 60, height: 20))
            yourOutageIsLabel.font = OpenSans.regular.of(size: 16)
            yourOutageIsLabel.textColor = .actionBlue
            yourOutageIsLabel.textAlignment = .center
            yourOutageIsLabel.text = NSLocalizedString("Your outage is", comment: "")
            
            let reportedLabel = UILabel(frame: CGRect(x: 30, y: 81, width: bigButtonWidth - 60, height: 25))
            reportedLabel.font = OpenSans.bold.of(size: 22)
            reportedLabel.textColor = .actionBlue
            reportedLabel.textAlignment = .center
            reportedLabel.text = NSLocalizedString("REPORTED", comment: "")
            
            let restRestorationLabel = UILabel(frame: CGRect(x: 30, y: 117, width: bigButtonWidth - 60, height: 14))
            restRestorationLabel.font = OpenSans.regular.of(size: 12)
            restRestorationLabel.textColor = .deepGray
            restRestorationLabel.textAlignment = .center
            restRestorationLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
            
            let timeLabel = UILabel(frame: CGRect(x: 22, y: 134, width: bigButtonWidth - 44, height: 20))
            timeLabel.font = OpenSans.bold.of(size: 15)
            timeLabel.textColor = .deepGray
            timeLabel.textAlignment = .center
            timeLabel.adjustsFontSizeToFitWidth = true
            timeLabel.minimumScaleFactor = 0.5
            timeLabel.text = viewModel.getEstimatedRestorationDateString()
            
            bigButtonView.addSubview(icon)
            bigButtonView.addSubview(yourOutageIsLabel)
            bigButtonView.addSubview(reportedLabel)
            bigButtonView.addSubview(restRestorationLabel)
            bigButtonView.addSubview(timeLabel)
            bigButtonView.accessibilityLabel = NSLocalizedString("Outage status, button. Your outage is reported. Estimated restoration \(viewModel.getEstimatedRestorationDateString()).", comment: "")
        } else if currentOutageStatus.activeOutage {
            let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 11, y: 31, width: 22, height: 28))
            icon.image = #imageLiteral(resourceName: "ic_outagestatus_out")
            
            let yourPowerIsLabel = UILabel(frame: CGRect(x: 30, y: 62, width: bigButtonWidth - 60, height: 20))
            yourPowerIsLabel.font = OpenSans.regular.of(size: 16)
            yourPowerIsLabel.textColor = .actionBlue
            yourPowerIsLabel.textAlignment = .center
            yourPowerIsLabel.text = NSLocalizedString("Your power is", comment: "")
            
            let outLabel = UILabel(frame: CGRect(x: 44, y: 82, width: bigButtonWidth - 88, height: 25))
            outLabel.font = OpenSans.bold.of(size: 22)
            outLabel.textColor = .actionBlue
            outLabel.textAlignment = .center
            outLabel.text = NSLocalizedString("OUT", comment: "")
            
            let restRestorationLabel = UILabel(frame: CGRect(x: 30, y: 117, width: bigButtonWidth - 60, height: 14))
            restRestorationLabel.font = OpenSans.regular.of(size: 12)
            restRestorationLabel.textColor = .deepGray
            restRestorationLabel.textAlignment = .center
            restRestorationLabel.text = NSLocalizedString("Estimated Restoration", comment: "")
            
            let timeLabel = UILabel(frame: CGRect(x: 22, y: 134, width: bigButtonWidth - 44, height: 20))
            timeLabel.font = OpenSans.bold.of(size: 15)
            timeLabel.textColor = .deepGray
            timeLabel.textAlignment = .center
            timeLabel.adjustsFontSizeToFitWidth = true
            timeLabel.minimumScaleFactor = 0.5
            timeLabel.text = viewModel.getEstimatedRestorationDateString()
            
            bigButtonView.addSubview(icon)
            bigButtonView.addSubview(yourPowerIsLabel)
            bigButtonView.addSubview(outLabel)
            bigButtonView.addSubview(restRestorationLabel)
            bigButtonView.addSubview(timeLabel)
            bigButtonView.accessibilityLabel = NSLocalizedString("Outage status, button. Your power is out. Estimated restoration \(viewModel.getEstimatedRestorationDateString()).", comment: "")
        } else if currentOutageStatus.flagFinaled || currentOutageStatus.flagNoPay || currentOutageStatus.flagNonService {
            let nonPayFinaledTextView = DataDetectorTextView(frame: CGRect(x: 14, y: 38, width: bigButtonWidth - 28, height: 120))
            let payBillLabel = UILabel(frame: .zero)
            if Environment.sharedInstance.opco != .bge {
                if currentOutageStatus.flagFinaled {
                    nonPayFinaledTextView.frame = CGRect(x: 14, y: 68, width: bigButtonWidth - 28, height: 84)
                } else { // accountPaid = false
                    payBillLabel.frame = CGRect(x: 23, y: 150, width: bigButtonWidth - 46, height: 19)
                    payBillLabel.font = SystemFont.semibold.of(size: 16)
                    payBillLabel.textColor = .actionBlue
                    payBillLabel.textAlignment = .center
                    payBillLabel.text = NSLocalizedString("Pay Bill", comment: "")
                    bigButtonView.addSubview(payBillLabel)
                }
            }
            nonPayFinaledTextView.textContainerInset = .zero
            nonPayFinaledTextView.font = SystemFont.light.of(size: 14)
            nonPayFinaledTextView.tintColor = .actionBlue // For the phone numbers
            nonPayFinaledTextView.textColor = .middleGray
            nonPayFinaledTextView.textAlignment = .center
            nonPayFinaledTextView.text = viewModel.getAccountNonPayFinaledMessage()

            bigButtonView.addSubview(nonPayFinaledTextView)
            bigButtonView.bringSubview(toFront: payBillLabel)
            bigButtonView.accessibilityLabel = NSLocalizedString("Outage status, button. \(viewModel.getAccountNonPayFinaledMessage()).", comment: "")
        } else { // Power is on
            let icon = UIImageView(frame: CGRect(x: bigButtonWidth / 2 - 15, y: 49, width: 30, height: 38))
            icon.image = #imageLiteral(resourceName: "ic_outagestatus_on")
            
            let yourPowerIsLabel = UILabel(frame: CGRect(x: 40, y: 89, width: bigButtonWidth - 80, height: 20))
            yourPowerIsLabel.font = OpenSans.regular.of(size: 16)
            yourPowerIsLabel.textColor = .actionBlue
            yourPowerIsLabel.textAlignment = .center
            yourPowerIsLabel.text = NSLocalizedString("Your power is", comment: "")
            
            let onLabel = UILabel(frame: CGRect(x: 40, y: 109, width: bigButtonWidth - 80, height: 25))
            onLabel.font = OpenSans.bold.of(size: 22)
            onLabel.textColor = .actionBlue
            onLabel.textAlignment = .center
            onLabel.text = NSLocalizedString("ON", comment: "")
            
            bigButtonView.addSubview(icon)
            bigButtonView.addSubview(yourPowerIsLabel)
            bigButtonView.addSubview(onLabel)
            bigButtonView.accessibilityLabel = NSLocalizedString("Outage status, Button. Your power is on.", comment: "")
        }
    }
    
    func getOutageStatus() {
        accountContentView.isHidden = true
        gasOnlyTextViewBottomSpaceConstraint.isActive = false
        gasOnlyView.isHidden = true
        errorLabel.isHidden = true
        loadingView.isHidden = false
        loadingView.accessibilityViewIsModal = true
        setRefreshControlEnabled(enabled: false)
        viewModel.getOutageStatus(onSuccess: {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            self.loadingView.isHidden = true
            self.loadingView.accessibilityViewIsModal = false
            self.setRefreshControlEnabled(enabled: true)
            self.updateContent()
        }, onError: { error in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            self.loadingView.isHidden = true
            self.loadingView.accessibilityViewIsModal = false
            self.setRefreshControlEnabled(enabled: true)
            self.errorLabel.text = error
            self.errorLabel.isHidden = false
        })
    }
    
    // MARK: - Actions
    
    func onBigButtonTap() {
        Analytics().logScreenView(AnalyticsPageView.OutageStatusDetails.rawValue)
        if viewModel.currentOutageStatus!.flagNoPay && Environment.sharedInstance.opco != .bge  {
            tabBarController?.selectedIndex = 1 // Jump to Bill tab
            Analytics().logScreenView(AnalyticsPageView.OutageStatusOfferComplete.rawValue)
        } else {
            if let message = viewModel.currentOutageStatus!.outageDescription {
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                Analytics().logScreenView(AnalyticsPageView.OutageStatusOfferComplete.rawValue)
            }
        }
    }
    
    func handlePhoneCallTap(_ sender: UITapGestureRecognizer) {
        Analytics().logScreenView(AnalyticsPageView.OutageAuthEmergencyCall.rawValue)
    }
    
    func onPullToRefresh() {
        viewModel.getOutageStatus(onSuccess: {
            self.refreshControl?.endRefreshing()
            self.updateContent()
        }, onError: { error in
            self.refreshControl?.endRefreshing()
            self.errorLabel.text = error
            self.errorLabel.isHidden = false
            
            // Hide everything else
            self.accountContentView.isHidden = true
            self.gasOnlyTextViewBottomSpaceConstraint.isActive = false
            self.gasOnlyView.isHidden = true
        })
    }
    
    @IBAction func onReportOutagePress() {
        performSegue(withIdentifier: "reportOutageSegue", sender: self)
    }
    
    @IBAction func onViewOutageMapPress() {
        Analytics().logScreenView(AnalyticsPageView.ViewMapOfferComplete.rawValue)
        self.performSegue(withIdentifier: "outageMapSegue", sender: self)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ReportOutageViewController {
            vc.viewModel.outageStatus = viewModel.currentOutageStatus!
            if let phone = viewModel.currentOutageStatus!.contactHomeNumber {
                vc.viewModel.phoneNumber.value = phone
            }
            vc.delegate = self
        }
    }
 
}

extension OutageViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        getOutageStatus()
    }
    
}

extension OutageViewController: ReportOutageViewControllerDelegate {
    
    func reportOutageViewControllerDidReportOutage(_ reportOutageViewController: ReportOutageViewController) {
        updateContent()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Outage report received", comment: ""))
            Analytics().logScreenView(AnalyticsPageView.ReportOutageAuthComplete.rawValue)
        })
    }
    
}
