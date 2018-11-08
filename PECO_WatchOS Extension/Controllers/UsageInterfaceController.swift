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
    
    @IBOutlet var accountGroup: WKInterfaceGroup!
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
        case error(ServiceError)
    }
    
    private var electricForecast: BillForecast?
    private var gasForecast: BillForecast?
    
    private var isElectricSelected = true
    private var isModeledForOpower = true
    
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
                if let toDateCost = billForecast.toDateCost {
                    mainSpentSoFarValueLabel.setText("\(toDateCost.currencyString ?? "")")
                }
                
                // Projected Bill Cost
                if let projectedBillCost = billForecast.projectedCost {
                    mainprojectedBillValueLabel.setText("\(projectedBillCost.currencyString ?? "")")
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
                    setImageForProgress(progress)
                    
                    mainTitleLabel.setText("\((billForecast.toDateCost ?? 0).currencyString ?? "")")
                } else if let toDateUsage = billForecast.toDateUsage, let projectedUsage = billForecast.projectedUsage {
                    
                    // Set Image
                    let progress = toDateUsage / projectedUsage
                    setImageForProgress(progress)
                    
                    mainTitleLabel.setText("\(billForecast.toDateUsage ?? 0) \(billForecast.meterUnit)")
                }
                
            case .nextForecast(let numberOfDays):
                // Hide all other groups
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show nextForecast group
                nextForecastGroup.setHidden(false)
                
                // set nextForecast data
                nextForecastImage.setImageNamed(AppImage.usage.name)
                nextForecastTitleLabel.setText("\(numberOfDays) days")
                nextForecastDetailLabel.setText("until next forecast")
            case .loading:
                // Hide all other groups
                errorGroup.setHidden(true)
                nextForecastGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show loading group
                loadingImageGroup.setHidden(false)
                
                aLog("Loading State")
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
                nextForecastGroup.setHidden(true)
                mainGroup.setHidden(true)
                
                // show error group
                errorGroup.setHidden(false)
                
                // set error data
                errorImage.setImageNamed(AppImage.usage.name)
                errorTitleLabel.setText("Usage is not available for this account.")
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

                aLog("Usage Error State: \(serviceError.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Clear Default Account Info
        accountTitleLabel.setText(nil)
        
        // Populate Account Info
        if let selectedAccount = AccountsStore.shared.getSelectedAccount() {
            updateAccountInformation(selectedAccount)
        }

        // Set Delegate
        NetworkingUtility.shared.addNetworkUtilityUpdateDelegate(self)
    }
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        GATracker.shared.screenView(screenName: UsageInterfaceController.className, customParameters: nil)
    }
    
    
    // MARK: - Actions
    
    @objc private func presentAccountList() {
        presentController(withName: "AccountListInterfaceController", context: nil)
    }
    
    @objc private func selectElectricMenuItem() {
        guard let electric = electricForecast else { return }
        
        isElectricSelected = true
        
        state = .loaded(electric)
    }
    
    @objc private func selectGasMenuItem() {
        guard let gas = gasForecast else { return }
        
        isElectricSelected = true
        
        state = .loaded(gas)
    }
    
    
    // MARK: - Helper
    
    private func updateAccountInformation(_ account: Account) {
        accountTitleLabel.setText(account.accountNumber)
        accountImage.setImageNamed(account.isResidential ? AppImage.residential_mini_white.name : AppImage.commercial_mini_white.name)
    }
    
    private func accountChangeAnimation(duration: TimeInterval) {
        animate(withDuration: duration, animations: { [weak self] in
            self?.accountGroup.setBackgroundColor(UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5))
            }, completion: { [weak self] in
                self?.animate(withDuration: duration, animations: {
                    self?.accountGroup.setBackgroundColor(UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2))
                })
        })
    }
    
    private func setImageForProgress(_ progress: Double) {
        let cleanedProgress = Int(floor(progress * 100)) // we will need to double check this, because it may be a floating point between 0-1 (0-100)
        
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
    
}


// MARK: - Networking Delegate

extension UsageInterfaceController: NetworkingDelegate {
    
    func usageStatusDidUpdate(_ billForecast: BillForecastResult) {
        
        // Determine if data is avilable - we need to double check this is the correct logic to determine unavailable
        if billForecast.electric == nil, billForecast.gas == nil {
            state = .unavailable
        }
        
        
        
        
        // todo, figure out what data looks like if the user doesnt have 2 full months of usage
        
        // Determine if after first 7 days of billing period
        
        // todo: does setting the nextForecast state here leave problems due to order of exectuion? user state switching?
        
        // Gas
        if let gas = billForecast.gas, let startDate = gas.billingStartDate {
            let today = Calendar.opCo.startOfDay(for: Date())
            let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
            if daysSinceBillingStart < 7 {
                state = .nextForecast(daysSinceBillingStart)
            }
        }
        if let gas = billForecast.gas {
            gasForecast = gas
            
            addMenuItem(withImageNamed: AppImage.gas.name, title: "Gas", action: #selector(selectGasMenuItem))
        }
        
        // Electric
        if let electric = billForecast.electric, let startDate = electric.billingStartDate {
            let today = Calendar.opCo.startOfDay(for: Date())
            let daysSinceBillingStart = abs(startDate.interval(ofComponent: .day, fromDate: today))
            if daysSinceBillingStart < 7 {
                state = .nextForecast(daysSinceBillingStart)
            }
        }
        if let electric = billForecast.electric {
            // Add Menu Items & Set State
            
            electricForecast = electric
            
            state = .loaded(electric)
            
            addMenuItem(withImageNamed: AppImage.electric.name, title: "Electric", action: #selector(selectElectricMenuItem))
        }
        
        // todo: we may need to rethink this logic, because the gas and electric state sort of live side by side of each other rather than one or the other due to how a user is able to switch between the two.
        
        aLog("Usage Status Did Update: \(billForecast)")
    }
    
    func accountListDidUpdate(_ accounts: [Account]) {
        clearAllMenuItems()
        
        guard accounts.count > 1 else { return }
        addMenuItem(withImageNamed: AppImage.residential.name, title: "Select Account", action: #selector(presentAccountList))
    }
    
    func currentAccountDidUpdate(_ account: Account) {
        updateAccountInformation(account)
        
        accountChangeAnimation(duration: 1.0)
    }
    
    func accountDetailDidUpdate(_ accountDetail: AccountDetail) {
        guard accountDetail.isPasswordProtected else { return }
        
        isModeledForOpower = accountDetail.isModeledForOpower
        
        state = .passwordProtected
    }
    
    func error(_ serviceError: ServiceError, feature: MainFeature) {
        guard feature == .all || feature == .usage else { return }
        guard serviceError.serviceCode == Errors.Code.passwordProtected else {
            state = .error(serviceError)
            return
        }
        state = .passwordProtected
    }
    
    func loading(feature: MainFeature) {
        guard feature == .all || feature == .usage else { return }
        state = .loading
    }
    
    func maintenanceMode(feature: MainFeature) {
        guard feature == .all || feature == .usage else { return }
        state = .maintenanceMode
    }
    
    func outageStatusDidUpdate(_ outageStatus: OutageStatus) { }
    
}
