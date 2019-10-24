//
//  UsageInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class UsageInterfaceController: WKInterfaceController {
    
    @IBOutlet var loadingImageGroup: WKInterfaceGroup!
    
    @IBOutlet var accountGroup: WKInterfaceGroup! {
        didSet {
            accountGroup.setHidden(true)
        }
    }
    @IBOutlet var accountImage: WKInterfaceImage!
    @IBOutlet var accountTitleLabel: WKInterfaceLabel!
    
    @IBOutlet var errorGroup: WKInterfaceGroup! {
        didSet {
            errorGroup.setHidden(true)
        }
    }
    @IBOutlet var errorImage: WKInterfaceImage!
    @IBOutlet var errorTitleLabel: WKInterfaceLabel!
    
    @IBOutlet var nextForecastGroup: WKInterfaceGroup! {
        didSet {
            nextForecastGroup.setHidden(true)
        }
    }
    @IBOutlet var nextForecastImage: WKInterfaceImage!
    @IBOutlet var nextForecastTitleLabel: WKInterfaceLabel!
    @IBOutlet var nextForecastDetailLabel: WKInterfaceLabel!
    
    @IBOutlet var mainGroup: WKInterfaceGroup! {
        didSet {
            mainGroup.setHidden(true)
        }
    }
    @IBOutlet var mainImageGroup: WKInterfaceGroup!
    @IBOutlet var mainUnitImage: WKInterfaceImage!
    @IBOutlet var mainTitleLabel: WKInterfaceLabel!
    @IBOutlet var mainSpentSoFarValueLabel: WKInterfaceLabel!
    @IBOutlet var mainprojectedBillValueLabel: WKInterfaceLabel!
    @IBOutlet var mainbillPeriodValueLabel: WKInterfaceLabel!
    
    
    enum State {
        case loaded(BillForecast)
        case nextForecast(Int)
        case loading
        case maintenanceMode
        case passwordProtected
        case unavailable
        case error(NetworkError)
    }
    
    private var electricForecast: BillForecast?
    private var gasForecast: BillForecast?
    
    private var isElectricSelected = true
    private var isModeledForOpower = true
    private var hasError = false
    
    private var state = State.loading {
        didSet {
            switch state {
            case .loaded(let billForecast):
                // Hide other groups
                errorGroup.setHidden(true)
                nextForecastGroup.setHidden(true)
                loadingImageGroup.setHidden(true)
                
                // Show Main Group
                mainGroup.setHidden(false)

                // Spent so far cost
                if isModeledForOpower, let toDateCost = billForecast.toDateCost {
                    mainSpentSoFarValueLabel.setText("\(toDateCost.currencyString)")
                } else if let toDateUsage = billForecast.toDateUsage {
                    mainSpentSoFarValueLabel.setText("\(Int(toDateUsage)) \(billForecast.meterUnit)")
                }
                
                // Projected Bill Cost
                if isModeledForOpower, let projectedBillCost = billForecast.projectedCost {
                    mainprojectedBillValueLabel.setText("\(projectedBillCost.currencyString)")
                } else if let projectedUsage = billForecast.projectedUsage {
                    mainprojectedBillValueLabel.setText("\(Int(projectedUsage)) \(billForecast.meterUnit)")
                }
                
                // Set Date Labels
                if let billingStartDate = billForecast.billingStartDate, let billingEndDate = billForecast.billingEndDate {
                    mainbillPeriodValueLabel.setText("\(billingStartDate.shortMonthAndDayString) - \(billingEndDate.shortMonthAndDayString)")
                }
                
                // Set gas/electric image
                mainUnitImage.setImageNamed(isElectricSelected ? (AppImage.electric.name) : (AppImage.gas.name))
                
                // Populate Unit label
                if isModeledForOpower, let toDateCost = billForecast.toDateCost, let projectedCost = billForecast.projectedCost {
                    
                    // Set Image
                    let progress = toDateCost / projectedCost
                    setImageForProgress(progress.isNaN ? 0.0 : progress) // handle division by 0
                    
                    mainTitleLabel.setText("\(toDateCost.currencyString)")
                } else if let toDateUsage = billForecast.toDateUsage, let projectedUsage = billForecast.projectedUsage {
                    
                    // Set Image
                    let progress = toDateUsage / projectedUsage
                    setImageForProgress(progress.isNaN ? 0.0 : progress) // handle division by 0
                    
                    mainTitleLabel.setText("\(Int(toDateUsage)) \(billForecast.meterUnit)")
                }
                
            case .nextForecast(let numberOfDays):
                // Hide all other groups
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show nextForecast group
                nextForecastGroup.setHidden(false)
                nextForecastTitleLabel.setHidden(false)

                
                // set nextForecast data
                nextForecastImage.setImageNamed(AppImage.usage.name)
                
                if numberOfDays == 1 {
                    nextForecastTitleLabel.setText("\(numberOfDays) day")
                } else {
                    nextForecastTitleLabel.setText("\(numberOfDays) days")
                }
                
                nextForecastDetailLabel.setText("until next forecast")
            case .loading:
                // Hide all other groups
                errorGroup.setHidden(true)
                nextForecastGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show loading group
                loadingImageGroup.setHidden(false)
                
                dLog("Loading State")
            case .maintenanceMode:
                // Hide all other groups
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                nextForecastGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show error group
                errorGroup.setHidden(false)
                
                // set error data
                errorImage.setImageNamed(AppImage.maintenanceMode.name)
                errorTitleLabel.setText("Scheduled Maintenance")
            case .passwordProtected:
                // Hide all other groups
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                nextForecastGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show error group
                errorGroup.setHidden(false)
                
                // set error data
                errorImage.setImageNamed(AppImage.passwordProtected.name)
                errorTitleLabel.setText("Password protected accounts cannot be accessed via app.")
            case .unavailable:
                // Hide all other groups
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show error group
                nextForecastGroup.setHidden(false)
                nextForecastTitleLabel.setHidden(true)

                // set error data
                nextForecastImage.setImageNamed(AppImage.usage.name)
                nextForecastDetailLabel.setText("Usage is not available for this account.")
            case .error(let serviceError):
                try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate : true])
                // Hide all other groups
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                nextForecastGroup.setHidden(true)
                mainGroup.setHidden(true)

                // show error group
                errorGroup.setHidden(false)

                // set error data
                errorImage.setImageNamed(AppImage.error.name)
                errorTitleLabel.setText("Unable to retrieve data. Please open the PECO app on your iPhone to sync your data or try again later.")

                dLog("Usage Error State: \(serviceError.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        NotificationCenter.default.addObserver(self, selector: #selector(currentAccountDidUpdate(_:)), name: Notification.Name.currentAccountUpdated, object: nil)
        
        // Clear Default Account Info
        accountTitleLabel.setText(nil)
        
        // Populate Account Info
        if let _ = AccountsStore.shared.currentIndex {
            updateAccountInterface(AccountsStore.shared.currentAccount, animationDuration: 1.0)
        }
        
    }
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        WatchAnalyticUtility.logScreenView(.usage_screen_view)
    }
    
    
    // MARK: - Actions
    
    @objc private func presentAccountList() {
        presentController(withName: AccountListInterfaceController.className, context: nil)
    }
    
    @objc private func selectElectricMenuItem() {
        guard let electric = electricForecast, let startDate = electric.billingStartDate else { return }
        
        isElectricSelected = true
        
        setElectricState(electric: electric, startDate: startDate)
    }
    
    @objc private func selectGasMenuItem() {
        guard let gas = gasForecast, let startDate = gas.billingStartDate else { return }
        
        isElectricSelected = false
        
        setGasState(gas: gas, startDate: startDate)
    }
    
    
    // MARK: - Helper
    
    private func configureNetworkActions() {
        NetworkUtilityNew.shared.maintenanceModeDidUpdate = { [weak self] maintenance, feature in
            self?.configureMaintenanceMode(maintenance, feature: feature)
        }
        
        NetworkUtilityNew.shared.errorDidOccur = { [weak self] error, feature in
            self?.configureError(error, feature: feature)
        }
        
        NetworkUtilityNew.shared.accountDetailDidUpdate = { [weak self] accountDetails in
            guard let accounts = AccountsStore.shared.accounts else {
                self?.state = .error(.fetchError)
                return
            }
            self?.configureAccountDetails(accountDetails, accounts: accounts)
        }
        
        NetworkUtilityNew.shared.billForecastDidUpdate = { [weak self] billForecast in
            self?.configureBillForecast(billForecast)
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
    
    private func setImageForProgress(_ progress: Double) {
        let cleanedProgress = Int(floor(progress * 100))
        
        if cleanedProgress >= 100 {
            // 100
            mainImageGroup.setBackgroundImageNamed(AppImage.usageProgress(99).name)
        } else if cleanedProgress < 100 && cleanedProgress >= 0 {
            // use the actual number
            mainImageGroup.setBackgroundImageNamed(AppImage.usageProgress(cleanedProgress).name)
        } else {
            // 0
            mainImageGroup.setBackgroundImageNamed(AppImage.usageProgress(0).name)
        }
    }
    
    private func setElectricState(electric: BillForecast, startDate: Date) {
        let today = Calendar.opCo.startOfDay(for: Date())
        let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
        if daysSinceBillingStart < 7 {
            electricForecast = electric

            let daysRemaining = 7 - daysSinceBillingStart
            state = .nextForecast(daysRemaining)
        } else {
            // Set State
            electricForecast = electric
            
            state = .loaded(electric)
        }
    }
    
    private func setGasState(gas: BillForecast, startDate: Date) {
        let today = Calendar.opCo.startOfDay(for: Date())
        let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
        if daysSinceBillingStart < 7 {
            gasForecast = gas
            
            let daysRemaining = 7 - daysSinceBillingStart
            state = .nextForecast(daysRemaining)
        } else {
            // Set State
            gasForecast = gas
            
            state = .loaded(gas)
        }
    }
    
}


// MARK: - Network Action Configuration

extension UsageInterfaceController {

    @objc private func currentAccountDidUpdate(_ notification: NSNotification) {
        guard let account = notification.object as? Account,
            account.isResidential else {
                state = .error(.invalidAccount)
                return
        }
        
        updateAccountInterface(account, animationDuration: 1.0)
    }
    
    private func configureAccountDetails(_ accountDetails: AccountDetail, accounts: [Account]) {
        isModeledForOpower = accountDetails.isModeledForOpower
        
        guard !accountDetails.isPasswordProtected else {
            state = .passwordProtected
            return
        }
        
        if !accountDetails.isAMIAccount {
            state = .unavailable
        }
        
        clearAllMenuItems()
        
        guard accounts.count > 1 else { return }
        addMenuItem(withImageNamed: AppImage.residential.name, title: "Select Account", action: #selector(presentAccountList))

        // Set electric image. gas / electric menu items
        if let serviceType = accountDetails.serviceType {
            if serviceType.uppercased() == "GAS" {
                isElectricSelected = false
            } else if serviceType.uppercased() == "ELECTRIC" {
                isElectricSelected = true
            } else if serviceType.uppercased() == "GAS/ELECTRIC" {
                isElectricSelected = true
                
                addMenuItem(withImageNamed: AppImage.gasMenuItem.name, title: "Gas", action: #selector(selectGasMenuItem))
                addMenuItem(withImageNamed: AppImage.electricMenuItem.name, title: "Electric", action: #selector(selectElectricMenuItem))
            }
        }
    }
    
    private func configureBillForecast(_ billForecast: BillForecastResult) {
        accountGroup.setHidden(false)
        
        // Determine if data is avilable
        if billForecast.electric == nil, billForecast.gas == nil {
            state = .unavailable
        }
        
        // Gas
        if let gas = billForecast.gas, let startDate = gas.billingStartDate {
            setGasState(gas: gas, startDate: startDate)
        }

        // Electric
        if let electric = billForecast.electric, let startDate = electric.billingStartDate {
            setElectricState(electric: electric, startDate: startDate)
        }

        dLog("Usage Status Did Update: \(billForecast)")
    }
    
    private func configureMaintenanceMode(_ maintenanceMode: Maintenance, feature: Feature) {
        
        guard feature == .all || feature == .usage else { return }
        
        accountGroup.setHidden(false)
        
        state = .maintenanceMode
    }
    
    private func configureError(_ error: NetworkError, feature: Feature) {
        
        guard feature == .all || feature == .usage else { return }
        
        accountGroup.setHidden(false)
        
        hasError = true
        clearAllMenuItems() // todo double check this
        
        guard error == .passwordProtected else {
            state = .error(error)
            return
        }
        state = .passwordProtected
    }
    
}
