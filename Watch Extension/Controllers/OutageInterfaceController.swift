//
//  OutageInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class OutageInterfaceController: WKInterfaceController {
 
    @IBOutlet var loadingImageGroup: WKInterfaceGroup!
    
    @IBOutlet var accountGroup: WKInterfaceGroup! {
        didSet {
            accountGroup.setHidden(true)
        }
    }
    @IBOutlet var accountImage: WKInterfaceImage!
    @IBOutlet var accountTitleLabel: WKInterfaceLabel!
    
    @IBOutlet var reportOutageTapGesture: WKTapGestureRecognizer!
    @IBOutlet var statusGroup: WKInterfaceGroup! {
        didSet {
            statusGroup.setHidden(true)
        }
    }
    @IBOutlet var powerStatusLabel: WKInterfaceLabel!
    @IBOutlet var etrGroup: WKInterfaceGroup!
    @IBOutlet var etrTitleLabel: WKInterfaceLabel!
    @IBOutlet var etrDetailLabel: WKInterfaceLabel!
    @IBOutlet var powerStatusImage: WKInterfaceImage! {
        didSet {
            powerStatusImage.setHidden(true)
        }
    }

    @IBOutlet var errorGroup: WKInterfaceGroup! {
        didSet {
            errorGroup.setHidden(true)
        }
    }
    @IBOutlet var errorImage: WKInterfaceImage!
    @IBOutlet var errorTitleLabel: WKInterfaceLabel!
    @IBOutlet var errorDetailLabel: WKInterfaceLabel!

    enum State {
        case loaded(OutageState)
        case loading
        case error(ServiceError)
        case maintenanceMode
        case passwordProtected
    }
    
    enum OutageState {
        case powerOn
        case powerOut
        case gasOnly
        case unavilable
    }
    
    // Changes the Interface for error states
    var state = State.loading {
        didSet {
            switch state {
            case .loaded(let outageState):
                loadingImageGroup.setHidden(true)
                reportOutageTapGesture.isEnabled = true
                self.outageState = outageState
                dLog("Loaded")
            case .loading:
                loadingImageGroup.setHidden(false)
                reportOutageTapGesture.isEnabled = false
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                etrGroup.setHidden(true)
                errorGroup.setHidden(true)
                shouldAnimateStatusImage = false
                dLog("Loading")
            case .error(let error):
                try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate : true])
                loadingImageGroup.setHidden(true)

                reportOutageTapGesture.isEnabled = false
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                errorGroup.setHidden(false)
                shouldAnimateStatusImage = false

                errorImage.setImageNamed(AppImage.error.name)
                errorTitleLabel.setHidden(true)
                errorDetailLabel.setText("Unable to retrieve data. Please open the PECO app on your iPhone to sync your data or try again later.")
                dLog("Error: \(error.localizedDescription)")
            case .maintenanceMode:
                loadingImageGroup.setHidden(true)

                reportOutageTapGesture.isEnabled = false
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                errorGroup.setHidden(false)
                shouldAnimateStatusImage = false
                
                errorImage.setImageNamed(AppImage.maintenanceMode.name)
                errorTitleLabel.setText("Scheduled Maintenance")
                errorDetailLabel.setText("Outage is currently unavailable due to scheduled maintenance.")
                dLog("Maintenance Mode")
            case .passwordProtected:
                loadingImageGroup.setHidden(true)
                
                reportOutageTapGesture.isEnabled = false
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                shouldAnimateStatusImage = false

                errorGroup.setHidden(false)
                
                errorImage.setImageNamed(AppImage.passwordProtected.name)
                errorTitleLabel.setText("Password Protected")
                errorDetailLabel.setText("Your account cannot be accessed through this app.")
                dLog("Password Protected")
            }
        }
    }
    
    // Changes UI for different power states
    var outageState: OutageState? {
        didSet {
            guard let outageState = outageState else { return }

            switch outageState {
            case .powerOn:
                statusGroup.setHidden(false)
                powerStatusImage.setHidden(false)
                etrGroup.setHidden(false)
                etrTitleLabel.setHidden(true)
                etrDetailLabel.setHidden(true)
                errorGroup.setHidden(true)
                
                powerStatusImage.setImageNamed(AppImage.onAnimation.name)

                shouldAnimateStatusImage = true

                powerStatusLabel.setText("POWER IS ON")
                dLog("Outage Status: power on")
            case .powerOut:
                statusGroup.setHidden(false)
                powerStatusImage.setHidden(false)
                etrGroup.setHidden(false)
                errorGroup.setHidden(true)
                
                powerStatusImage.setImageNamed(AppImage.offAnimation.name)
                shouldAnimateStatusImage = true

                powerStatusLabel.setText("POWER IS OUT")
                guard let etr = NetworkingUtility.shared.outageStatus?.etr else {
                    etrTitleLabel.setHidden(true)
                    etrDetailLabel.setHidden(true)
                    return
                }
                etrDetailLabel.setText(DateFormatter.outageOpcoDateFormatter.string(from: etr))
                dLog("Outage Status: power out")
            case .gasOnly:
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                errorGroup.setHidden(false)
                shouldAnimateStatusImage = false
                
                errorImage.setImageNamed(AppImage.gasOnly.name)
                errorTitleLabel.setText("Gas Only Account")
                errorDetailLabel.setText("Reporting of issues for gas only accounts not allowed online.")
                dLog("Outage Status: Gas Only")
            case .unavilable:
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                errorGroup.setHidden(false)
                shouldAnimateStatusImage = false
                
                errorImage.setImageNamed(AppImage.outageUnavailable.name)
                errorTitleLabel.setText("Outage Unavailable")
                errorDetailLabel.setText("Outage Status and Outage Reporting are not available for this account.")
                dLog("Outage Unavailable")
            }
        }
    }
    
    /// Determines animation + repeat count + start/stop
    private var shouldAnimateStatusImage = true {
        didSet {
            guard shouldAnimateStatusImage, let outageState = outageState else {
                powerStatusImage.stopAnimating()
                return
            }
            
            if outageState == .powerOn {
                powerStatusImage.startAnimatingWithImages(in: NSMakeRange(0, 119), duration: 0, repeatCount: 0)
            } else if outageState == .powerOut {
                powerStatusImage.startAnimatingWithImages(in: NSMakeRange(0, 119), duration: 0, repeatCount: 1)
            } else {
                powerStatusImage.stopAnimating()
            }
        }
    }
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        NotificationCenter.default.addObserver(self, selector: #selector(outageReportedFromPhone), name: Notification.Name.outageReported, object: nil)
        
        // Clear Default Account Info
        accountTitleLabel.setText(nil)
        
        // Populate Account Info
        if let _ = AccountsStore.shared.currentIndex {
            updateAccountInterface(AccountsStore.shared.currentAccount)
        }

        // Set Delegate
        NetworkingUtility.shared.addNetworkUtilityUpdateDelegate(self)
        
        // Perform Network Request
        NetworkingUtility.shared.fetchData()
    }
    
    override func didAppear() {
        super.didAppear()

        // Log Analytics
        WatchAnalyticUtility.logScreenView(.account_list_screen_view)
        
        // If outage state loads without being on the outage screen
        shouldAnimateStatusImage = true
    }
    
    override func willDisappear() {
        super.willDisappear()
        
        shouldAnimateStatusImage = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Action
    
    @IBAction func presentReportOutage(_ sender: Any) {
        presentController(withName: ReportOutageInterfaceController.className, context: nil)
    }
    
    
    // MARK: - Helper
    
    @objc private func presentAccountList() {
        presentController(withName: AccountListInterfaceController.className, context: nil)
    }
    
    private func updateAccountInterface(_ account: Account, animationDuration: TimeInterval? = nil) {
        accountTitleLabel.setText(account.accountNumber)
        accountImage.setImageNamed(account.isResidential ? AppImage.residential_mini_white.name : AppImage.commercial_mini_white.name)
        
        // Animate
        guard let animationDuration = animationDuration else { return }
        
        animate(withDuration: animationDuration, animations: { [weak self] in
            self?.accountGroup.setBackgroundColor(UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5))
            }, completion: { [weak self] in
                self?.animate(withDuration: animationDuration, animations: {
                    self?.accountGroup.setBackgroundColor(UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2))
                })
        })
    }
    
    @objc func outageReportedFromPhone() {
        self.state = .loaded(.powerOut)
    }
}


// MARK: - Networking Delegate

extension OutageInterfaceController: NetworkingDelegate {

    func currentAccountDidUpdate(_ account: Account) {
        updateAccountInterface(account, animationDuration: 1)
    }
    
    func accountListDidUpdate(_ accounts: [Account]) {
        clearAllMenuItems()
        
        guard accounts.count > 1 else { return }
        addMenuItem(withImageNamed: AppImage.residential.name, title: "Select Account", action: #selector(presentAccountList))
    }
    
    func outageStatusDidUpdate(_ outageStatus: OutageStatus) {
        
        accountGroup.setHidden(false)
        
        guard !outageStatus.flagGasOnly else {
            state = .loaded(.gasOnly)
            return
        }
        
        if outageStatus.activeOutage {
            state = .loaded(.powerOut)
        } else if outageStatus.flagNoPay || outageStatus.flagFinaled || outageStatus.flagNonService {
            state = .loaded(.unavilable)
        } else {
            state = .loaded(.powerOn)
        }
    }
    
    func maintenanceMode(feature: MainFeature) {
        guard feature == .all || feature == .outage else { return }
        
        accountGroup.setHidden(false)
        
        state = .maintenanceMode
    }
    
    func loading(feature: MainFeature) {
        guard feature == .all || feature == .outage else { return }

        state = .loading
    }
    
    func error(_ serviceError: ServiceError, feature: MainFeature) {
        guard feature == .all || feature == .outage else { return }
        
        accountGroup.setHidden(false)
        
        guard serviceError.serviceCode == Errors.Code.passwordProtected else {
            state = .error(serviceError)
            return
        }
        state = .passwordProtected
    }
        
}
