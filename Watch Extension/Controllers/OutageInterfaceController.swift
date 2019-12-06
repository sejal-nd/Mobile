//
//  OutageInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class OutageInterfaceController: WKInterfaceController {
    
    enum State {
        case loaded(OutageState)
        case loading
        case error(NetworkError)
        case maintenanceMode
        case passwordProtected
    }
    
    enum OutageState {
        case powerOn
        case powerOut(OutageStatus?)
        case gasOnly
        case unavilable
    }
    
    @IBOutlet var loadingImageGroup: WKInterfaceGroup!
    
    @IBOutlet var accountGroup: WKInterfaceGroup!
    @IBOutlet var accountImage: WKInterfaceImage!
    @IBOutlet var accountTitleLabel: WKInterfaceLabel!
    
    @IBOutlet var reportOutageTapGesture: WKTapGestureRecognizer!
    @IBOutlet var statusGroup: WKInterfaceGroup!
    @IBOutlet var powerStatusLabel: WKInterfaceLabel!
    @IBOutlet var etrGroup: WKInterfaceGroup!
    @IBOutlet var etrTitleLabel: WKInterfaceLabel!
    @IBOutlet var etrDetailLabel: WKInterfaceLabel!
    @IBOutlet var powerStatusImage: WKInterfaceImage!
    
    @IBOutlet var errorGroup: WKInterfaceGroup!
    @IBOutlet var errorImage: WKInterfaceImage!
    @IBOutlet var errorTitleLabel: WKInterfaceLabel!
    @IBOutlet var errorDetailLabel: WKInterfaceLabel!
        
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
                errorDetailLabel.setText("Unable to retrieve data. Please open the \(Environment.shared.opco.displayString) app on your iPhone to sync your data or try again later.")
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
            case .powerOut(let outageStatus):
                statusGroup.setHidden(false)
                powerStatusImage.setHidden(false)
                etrGroup.setHidden(false)
                errorGroup.setHidden(true)
                
                powerStatusImage.setImageNamed(AppImage.offAnimation.name)
                shouldAnimateStatusImage = true
                
                powerStatusLabel.setText("POWER IS OUT")
                guard let etr = outageStatus?.etr else {
                    etrDetailLabel.setText("Assessing Damage")
                    return
                }
                etrDetailLabel.setText(DateFormatter.outageOpcoDateFormatter.string(from: etr))
                dLog("Outage Status: power out")
            case .gasOnly:
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                errorGroup.setHidden(false)
                shouldAnimateStatusImage = false
                reportOutageTapGesture.isEnabled = false
                
                errorImage.setImageNamed(AppImage.gas.name)
                errorTitleLabel.setText("Gas Only Account")
                errorDetailLabel.setText("Reporting of issues for gas only accounts not allowed online.")
                dLog("Outage Status: Gas Only")
            case .unavilable:
                statusGroup.setHidden(true)
                powerStatusImage.setHidden(true)
                errorGroup.setHidden(false)
                shouldAnimateStatusImage = false
                reportOutageTapGesture.isEnabled = false
                
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
            
            if case .powerOn = outageState {
                powerStatusImage.startAnimatingWithImages(in: NSMakeRange(0, 119), duration: 0, repeatCount: 0)
            } else if case .powerOut(_) = outageState {
                powerStatusImage.startAnimatingWithImages(in: NSMakeRange(0, 119), duration: 0, repeatCount: 1)
            } else {
                powerStatusImage.stopAnimating()
            }
        }
    }
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(outageReportedFromPhone),
                                               name: Notification.Name.outageReported,
                                               object: nil)
        
        configureInitialState()
        
        configureNetworkActions()
        
        // Clear Default Account Info
        accountTitleLabel.setText(nil)
        
        // Populate Account Info
        if let _ = AccountsStore.shared.currentIndex {
            updateAccountInterface(AccountsStore.shared.currentAccount)
        }
        
        // Perform Network Request
        NetworkUtility.shared.fetchData(shouldLoadAccountList: true)
        
        loadData()        
    }
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        AnalyticUtility.logScreenView(.outage_screen_view)
        
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
    
    @IBAction private func presentReportOutage(_ sender: Any) {
        presentController(withName: ReportOutageInterfaceController.className, context: nil)
    }
    
    @objc private func presentAccountList() {
        presentController(withName: AccountListInterfaceController.className, context: nil)
    }
    
    
    // MARK: - Helper

    private func configureInitialState() {
        accountGroup.setHidden(true)
        statusGroup.setHidden(true)
        powerStatusImage.setHidden(true)
        errorGroup.setHidden(true)        
    }
    
    @objc
    private func outageReportedFromPhone() {
        self.state = .loaded(.powerOut(nil))
    }

    private func configureNetworkActions() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self,
                                       selector: #selector(currentAccountDidUpdate(_:)),
                                       name: .currentAccountUpdated,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleNotification(_:)),
                                       name: .maintenanceModeDidUpdate,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleNotification(_:)),
                                       name: .errorDidOccur,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleNotification(_:)),
                                       name: .accountListDidUpdate,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleNotification(_:)),
                                       name: .defaultAccountDidUpdate,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleNotification(_:)),
                                       name: .outageStatusDidUpdate,
                                       object: nil)
    }
    
    private func loadData() {
        let networkUtility = NetworkUtility.shared
        
        if !networkUtility.maintenanceModeStatuses.isEmpty {
            networkUtility.maintenanceModeStatuses.forEach { maintenanceModeStatus in
                configureMaintenanceModeStatus(maintenanceModeStatus)
            }
        }
        
        if let error = networkUtility.error {
            configureError(error.0, feature: error.1)
        }
        
        if !networkUtility.accounts.isEmpty {
           configureAccountList(networkUtility.accounts)
        }
        
        if let defaultAccount = networkUtility.defaultAccount {
            updateAccountInterface(defaultAccount, animationDuration: 1.0)
        }
        
        if let outageStatus = networkUtility.outageStatus {
            configureOutageStatus(outageStatus)
        }
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

    @objc
    private func handleNotification(_ notification: NSNotification) {
        if let accounts = notification.object as? [Account] {
            configureAccountList(accounts)
        } else if let account = notification.object as? Account {
            updateAccountInterface(account, animationDuration: 1.0)
        } else if let outageStatus = notification.object as? OutageStatus {
                configureOutageStatus(outageStatus)
        } else if let maintenanceModeStatus = notification.object as? MaintenanceModeStatus {
            configureMaintenanceModeStatus(maintenanceModeStatus)
        } else if let tuple = notification.object as? (NetworkError, Feature) {
            configureError(tuple.0, feature: tuple.1)
        } else {
            assertionFailure("Invalid Notification")
        }
    }
    
}


// MARK: - Network Action Configuration

extension OutageInterfaceController {
    
    @objc
    private func currentAccountDidUpdate(_ notification: NSNotification) {
        guard let account = notification.object as? Account else {
                state = .error(.invalidAccount)
                return
        }
        
        updateAccountInterface(account, animationDuration: 1.0)
        state = .loading
    }
    
    private func configureAccountList(_ accounts: [Account]) {
        clearAllMenuItems()

        guard accounts.count > 1 else { return }

        addMenuItem(withImageNamed: AppImage.residentialMenuItem.name, title: "Select Account", action: #selector(presentAccountList))
    }
    
    private func configureOutageStatus(_ outageStatus: OutageStatus) {
        accountGroup.setHidden(false)
        
        guard !outageStatus.flagGasOnly else {
            state = .loaded(.gasOnly)
            return
        }
        
        if outageStatus.activeOutage {
            state = .loaded(.powerOut(outageStatus))
        } else if outageStatus.flagNoPay || outageStatus.flagFinaled || outageStatus.flagNonService {
            state = .loaded(.unavilable) // todo: this is not getting triggered? Ticket/Bug: https://exelontfs.visualstudio.com/EU-mobile/_workitems/edit/336004
        } else {
            state = .loaded(.powerOn)
        }
    }
    
    private func configureMaintenanceModeStatus(_ maintenanceModeStatus: MaintenanceModeStatus) {
        guard maintenanceModeStatus.feature == .all || maintenanceModeStatus.feature == .outage else { return }
        
        accountGroup.setHidden(false)
        
        state = .maintenanceMode
    }
    
    // supposed to handle cut for non pay as not avail for this accocunt?
    private func configureError(_ error: NetworkError, feature: Feature) {
        guard feature == .all || feature == .outage else { return }
        
        accountGroup.setHidden(false)
        
        guard error == .passwordProtected else {
            state = .error(error)
            return
        }
        state = .passwordProtected
    }
    
}
