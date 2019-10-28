//
//  BillInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class BillInterfaceController: WKInterfaceController {
    
    // We may want to make this a global enum, if these end up being the states for all main VC's
    enum State {
        case loaded
        case loading
        case error(NetworkError)
        case maintenanceMode
        case passwordProtected
    }
    
    @IBOutlet var loadingImageGroup: WKInterfaceGroup!
    
    // Account
    @IBOutlet var accountGroup: WKInterfaceGroup!
    @IBOutlet var accountImage: WKInterfaceImage!
    @IBOutlet var accountTitleLabel: WKInterfaceLabel!
    
    // Error
    @IBOutlet var errorGroup: WKInterfaceGroup!
    @IBOutlet var errorImage: WKInterfaceImage!
    @IBOutlet var errorTitleLabel: WKInterfaceLabel!
    @IBOutlet var errorDetailLabel: WKInterfaceLabel!
    
    // Bill State Components
    @IBOutlet var billGroup: WKInterfaceGroup!
    
    // Alert
    @IBOutlet var billAlertGroup: WKInterfaceGroup!
    @IBOutlet var billAlertLabel: WKInterfaceLabel!
    
    // Payment Received
    @IBOutlet var paymentReceivedGroup: WKInterfaceGroup!
    @IBOutlet var paymentReceivedImage: WKInterfaceImage!
    @IBOutlet var paymentReceivedLabel: WKInterfaceLabel!
    @IBOutlet var paymentReceivedAmountLabel: WKInterfaceLabel!
    
    // Auto Pay
    @IBOutlet var autoPayScheduledPaymentGroup: WKInterfaceGroup!
    @IBOutlet var autoPayScheduledPaymentImage: WKInterfaceImage!
    @IBOutlet var autoPayScheduledPaymentDetailLabel: WKInterfaceLabel!
    
    // Total Amount Due
    @IBOutlet var totalAmountGroup: WKInterfaceGroup!
    @IBOutlet var totalAmountLabel: WKInterfaceLabel!
    @IBOutlet var totalAmountDescriptionLabel: WKInterfaceLabel!
    
    // Bill Line Items
    
    @IBOutlet var pastDueGroup: WKInterfaceGroup!
    @IBOutlet var pastDueLabel: WKInterfaceLabel!
    @IBOutlet var pastDueAmountLabel: WKInterfaceLabel!
    @IBOutlet var pastDueDateLabel: WKInterfaceLabel!
    
    @IBOutlet var currentBillGroup: WKInterfaceGroup!
    @IBOutlet var currentBillLabel: WKInterfaceLabel!
    @IBOutlet var currentBillAmountLabel: WKInterfaceLabel!
    @IBOutlet var currentBillDateLabel: WKInterfaceLabel!
    
    @IBOutlet var pendingPaymentGroup: WKInterfaceGroup!
    @IBOutlet var pendingPaymentLabel: WKInterfaceLabel!
    @IBOutlet var pendingPaymentAmountLabel: WKInterfaceLabel!
    
    @IBOutlet var remainingBalanceGroup: WKInterfaceGroup!
    @IBOutlet var remainingBalanceLabel: WKInterfaceLabel!
    @IBOutlet var remainingBalanaceAmountLabel: WKInterfaceLabel!

    // Footer
    @IBOutlet var footerGroup: WKInterfaceGroup!
    
    // Changes the Interface for error states
    var state = State.loading {
        didSet {
            switch state {
            case .loaded:
                billGroup.setHidden(false)
                
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                
                dLog("Loaded")
            case .loading:
                loadingImageGroup.setHidden(false)
                
                
                billGroup.setHidden(true)
                errorGroup.setHidden(true)
                
                dLog("Loading")
            case .error(let error):
                
                try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate : true])
                
                errorGroup.setHidden(false)
                errorImage.setImageNamed(AppImage.error.name)
                errorTitleLabel.setHidden(true)
                errorDetailLabel.setText("Unable to retrieve data. Please open the \(Environment.shared.opco.displayString) app on your iPhone to sync your data or try again later.")
                
                loadingImageGroup.setHidden(true)
                
                
                billGroup.setHidden(true)
                
                dLog("Error: \(error.localizedDescription)")
            case .maintenanceMode:
                errorGroup.setHidden(false)
                errorImage.setImageNamed(AppImage.maintenanceMode.name)
                errorTitleLabel.setText("Scheduled Maintenance")
                errorDetailLabel.setText("Billing is currently unavailable due to scheduled maintenance.")
                
                loadingImageGroup.setHidden(true)
                
                
                billGroup.setHidden(true)
                
                dLog("Maintenance Mode")
            case .passwordProtected:
                errorGroup.setHidden(false)
                errorImage.setImageNamed(AppImage.passwordProtected.name)
                errorTitleLabel.setText("Password Protected")
                errorDetailLabel.setText("Your account cannot be accessed through this app.")
                
                loadingImageGroup.setHidden(true)
                
                billGroup.setHidden(true)
                
                dLog("Password Protected")
            }
        }
    }
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        print("awake 3")
        
        configureNetworkActions()
                
        // Clear Default Account Info
        accountTitleLabel.setText(nil)
        hideAllStates(shouldHideLoading: false)
        
        // Populate Account Info
        if let _ = AccountsStore.shared.currentIndex {
            updateAccountInterface(AccountsStore.shared.currentAccount)
        }
        
        loadData()
    }
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        WatchAnalyticUtility.logScreenView(.bill_screen_view)
    }
    
    // MARK: - Actions
    
    @objc private func presentAccountList() {
        presentController(withName: AccountListInterfaceController.className, context: nil)
    }
    
    
    // MARK: - Helper
    
    private func configureNetworkActions() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: .maintenanceModeDidUpdate, object: nil)

        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: .errorDidOccur, object: nil)

        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: .accountListDidUpdate, object: nil)

        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: .defaultAccountDidUpdate, object: nil)

        notificationCenter.addObserver(self, selector: #selector(handleNotification(_:)), name: .accountDetailsDidUpdate, object: nil)
    }
    
    private func loadData() {
        let networkUtility = NetworkUtility.shared
        
        if !networkUtility.maintenanceModeStatuses.isEmpty {
            networkUtility.maintenanceModeStatuses.forEach { tuple in
                configureMaintenanceMode(tuple.0, feature: tuple.1)
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
        
        if let accountDetails = networkUtility.accountDetails {
            configureAccountDetails(accountDetails)
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
    
    private func hideAllStates(shouldHideLoading: Bool = true) {
        loadingImageGroup.setHidden(shouldHideLoading)
        
        footerGroup.setHidden(false)
        
        accountGroup.setHidden(true)
        errorGroup.setHidden(true)
        billAlertGroup.setHidden(true)
        autoPayScheduledPaymentGroup.setHidden(true)
        totalAmountGroup.setHidden(true)
        billGroup.setHidden(true)
        pastDueGroup.setHidden(true)
        currentBillGroup.setHidden(true)
        paymentReceivedGroup.setHidden(true)
        pendingPaymentGroup.setHidden(true)
        remainingBalanceGroup.setHidden(true)
    }
    
    private func configureBillingState(billUtility: BillUtility) {
        
        // Show/Hide Views
        state = .loaded
        
        billAlertGroup.setHidden(!billUtility.showAlertBanner)
        
        totalAmountGroup.setHidden(!billUtility.showTotalAmountAndLedger)
        
        paymentReceivedGroup.setHidden(!billUtility.showPaymentReceived)
        
        // auto pay & scheduled payment + bill not ready
        autoPayScheduledPaymentGroup.setHidden(billUtility.shouldHideAutoPay)
        
        pastDueGroup.setHidden(!billUtility.showPastDue)
        
        currentBillGroup.setHidden(!billUtility.showCurrentBill)
        pendingPaymentGroup.setHidden(!billUtility.showPendingPayment)
        remainingBalanceGroup.setHidden(!billUtility.showRemainingBalanceDue)
        
        // Set values
        billAlertLabel.setText(billUtility.alertBannerText)
        
        totalAmountLabel.setText(billUtility.totalAmountText)
        totalAmountDescriptionLabel.setAttributedText(billUtility.totalAmountDescriptionText)
        
        paymentReceivedAmountLabel.setText(billUtility.paymentReceivedAmountText)
        
        autoPayScheduledPaymentImage.setImage(billUtility.autoPayImage)
        autoPayScheduledPaymentDetailLabel.setText(billUtility.autoPayText)
        
        pastDueAmountLabel.setText(billUtility.pastDueAmountText)
        pastDueLabel.setText(billUtility.pastDueText)
        pastDueDateLabel.setAttributedText(billUtility.pastDueDateText)
        
        currentBillAmountLabel.setText(billUtility.currentBillAmountText)
        currentBillDateLabel.setText(billUtility.currentBillDateText)
        
        pendingPaymentAmountLabel.setText(billUtility.pendingPaymentsTotalAmountText)
        pendingPaymentLabel.setText(billUtility.pendingPaymentsText)
        
        remainingBalanaceAmountLabel.setText(billUtility.remainingBalanceDueAmountText)
        remainingBalanceLabel.setText(billUtility.remainingBalanceDueText)
    }
    
    @objc
    private func handleNotification(_ notification: NSNotification) {
        if let accounts = notification.object as? [Account] {
            configureAccountList(accounts)
        } else if let account = notification.object as? Account {
            updateAccountInterface(account, animationDuration: 1.0)
        } else if let accountDetails = notification.object as? AccountDetail {
                configureAccountDetails(accountDetails)
        } else if let tuple = notification.object as? (Maintenance, Feature) {
            configureMaintenanceMode(tuple.0, feature: tuple.1)
        } else if let tuple = notification.object as? (NetworkError, Feature) {
            configureError(tuple.0, feature: tuple.1)
        } else {
            assertionFailure("Invalid Notification")
        }
    }
    
}


// MARK: - Network Action Configuration

extension BillInterfaceController {
    
    @objc private func currentAccountDidUpdate(_ notification: NSNotification) {
        guard let account = notification.object as? Account else {
                state = .error(.invalidAccount)
                return
        }
        
        updateAccountInterface(account, animationDuration: 1.0)
    }
    
    private func configureAccountList(_ accounts: [Account]) {
        clearAllMenuItems()
        
        guard accounts.count > 1 else { return }
        addMenuItem(withImageNamed: AppImage.residential.name, title: "Select Account", action: #selector(presentAccountList))
    }
    
    private func configureAccountDetails(_ accountDetails: AccountDetail) {
        dLog("Account detail did update")
        
        // Hides all groups
        hideAllStates()
        
        // Display Account Group
        accountGroup.setHidden(false)
        
        configureBillingState(billUtility: BillUtility(accountDetails: accountDetails))
    }

    private func configureMaintenanceMode(_ maintenanceMode: Maintenance, feature: Feature) {
        guard feature == .all || feature == .bill else { return }
        accountGroup.setHidden(false)
        state = .maintenanceMode
    }
    
    private func configureError(_ error: NetworkError, feature: Feature) {
        guard feature == .all || feature == .bill else { return }
        
        accountGroup.setHidden(false)
        
        guard error == .passwordProtected else {
            state = .error(error)
            return
        }
        state = .passwordProtected
    }
    
}
