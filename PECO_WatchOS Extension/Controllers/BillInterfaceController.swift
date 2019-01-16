//
//  BillInterfaceController.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class BillInterfaceController: WKInterfaceController {
    
    @IBOutlet var loadingImageGroup: WKInterfaceGroup!
    
    @IBOutlet var accountGroup: WKInterfaceGroup!
    @IBOutlet var accountImage: WKInterfaceImage!
    @IBOutlet var accountTitleLabel: WKInterfaceLabel!
    
    @IBOutlet var errorGroup: WKInterfaceGroup!
    @IBOutlet var errorImage: WKInterfaceImage!
    @IBOutlet var errorTitleLabel: WKInterfaceLabel!
    @IBOutlet var errorDetailLabel: WKInterfaceLabel!
    
    @IBOutlet var billAlertGroup: WKInterfaceGroup!
    @IBOutlet var billAlertLabel: WKInterfaceLabel!

    @IBOutlet var billGroup: WKInterfaceGroup!

    @IBOutlet var autoPayScheduledPaymentGroup: WKInterfaceGroup!
    @IBOutlet var autoPayScheduledPaymentImage: WKInterfaceImage!
    @IBOutlet var autoPayScheduledPaymentDetailLabel: WKInterfaceLabel!
    
    @IBOutlet var billAmountGroup: WKInterfaceGroup!
    @IBOutlet var billAmountTitleLabel: WKInterfaceLabel!
    @IBOutlet var billAmountDescriptionLabel: WKInterfaceLabel!
    
    @IBOutlet var billPaidGroup: WKInterfaceGroup!
    @IBOutlet var billPaidAmountLabel: WKInterfaceLabel!

    @IBOutlet var mostRecentBillGroup: WKInterfaceGroup!
    @IBOutlet var mostRecentBillAmountLabel: WKInterfaceLabel!
    @IBOutlet var mostRecentBillDueDateLabel: WKInterfaceLabel!
    
    @IBOutlet var amountPastDueGroup: WKInterfaceGroup!
    @IBOutlet var amountPastDueLabel: WKInterfaceLabel!
    
    @IBOutlet var avoidShutoffGroup: WKInterfaceGroup!
    @IBOutlet var avoidShutoffAmountLabel: WKInterfaceLabel!
    
    @IBOutlet var catchUpOnAgreementGroup: WKInterfaceGroup!
    @IBOutlet var catchUpOnAgreementAmountLabel: WKInterfaceLabel!
    @IBOutlet var catchUpOnAgreementDateLabel: WKInterfaceLabel!
    
    @IBOutlet var remainingBalanceGroup: WKInterfaceGroup!
    @IBOutlet var remainingBalanaceAmountLabel: WKInterfaceLabel!
    @IBOutlet var remainingBalanceDescriptionLabel: WKInterfaceLabel!
    
    @IBOutlet var pendingPaymentGroup: WKInterfaceGroup!
    @IBOutlet var pendingPaymentAmountLabel: WKInterfaceLabel!
    @IBOutlet var pendingPaymentDescriptionLabel: WKInterfaceLabel!
    
    @IBOutlet var restoreServiceGroup: WKInterfaceGroup!
    @IBOutlet var restoreServiceAmountLabel: WKInterfaceLabel!
    @IBOutlet var restoreServiceDescriptionLabel: WKInterfaceLabel!
    @IBOutlet var restoreServiceDateLabel: WKInterfaceLabel!

    @IBOutlet var footerGroup: WKInterfaceGroup!

    
    // We may want to make this a global enum, if these end up being the states for all main VC's
    enum State {
        case loaded
        case loading
        case error(ServiceError)
        case maintenanceMode
        case passwordProtected
    }

    // Changes the Interface for error states
    var state = State.loading {
        didSet {
            switch state {
            case .loaded:
                billGroup.setHidden(false)
                
                loadingImageGroup.setHidden(true)
                errorGroup.setHidden(true)
                
                aLog("Loaded")
            case .loading:
                loadingImageGroup.setHidden(false)
                
                
                billGroup.setHidden(true)
                errorGroup.setHidden(true)
                
                aLog("Loading")
            case .error(let error):

                try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate : true])

                errorGroup.setHidden(false)
                errorImage.setImageNamed(AppImage.error.name)
                errorTitleLabel.setHidden(true)
                errorDetailLabel.setText("Unable to retrieve data. Please open the PECO app on your iPhone to sync your data or try again later.")

                loadingImageGroup.setHidden(true)


                billGroup.setHidden(true)

                aLog("Error: \(error.localizedDescription)")
            case .maintenanceMode:
                errorGroup.setHidden(false)
                errorImage.setImageNamed(AppImage.maintenanceMode.name)
                errorTitleLabel.setText("Scheduled Maintenance")
                errorDetailLabel.setText("Billing is currently unavailable due to scheduled maintenance.")
                
                loadingImageGroup.setHidden(true)

                
                billGroup.setHidden(true)

                aLog("Maintenance Mode")
            case .passwordProtected:
                errorGroup.setHidden(false)
                errorImage.setImageNamed(AppImage.passwordProtected.name)
                errorTitleLabel.setText("Password Protected")
                errorDetailLabel.setText("Your account cannot be accessed through this app.")
                
                loadingImageGroup.setHidden(true)
                
                billGroup.setHidden(true)

                aLog("Password Protected")
            }
        }
    }
    
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        // Clear Default Account Info
        accountTitleLabel.setText(nil)
        hideAllStates(shouldHideLoading: false)
        
        // Populate Account Info
        if let selectedAccount = AccountsStore.shared.currentAccount {
            updateAccountInformation(selectedAccount)
        }
        
        // Set Delegate
        NetworkingUtility.shared.addNetworkUtilityUpdateDelegate(self)
    }
    
    override func didAppear() {
        super.didAppear()
        
        // Log Analytics
        GATracker.shared.screenView(screenName: BillInterfaceController.className, customParameters: nil)
    }
    
    // MARK: - Helper
    
    @objc private func presentAccountList() {
        presentController(withName: AccountListInterfaceController.className, context: nil)
    }
    
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
    
    private func hideAllStates(shouldHideLoading: Bool = true) {
        shouldHideLoading ? (loadingImageGroup.setHidden(true)) : (loadingImageGroup.setHidden(false))
        
        footerGroup.setHidden(false)
        
        accountGroup.setHidden(true)
        errorGroup.setHidden(true)
        billAlertGroup.setHidden(true)
        billGroup.setHidden(true)
        autoPayScheduledPaymentGroup.setHidden(true)
        billAmountGroup.setHidden(true)
        billPaidGroup.setHidden(true)
        mostRecentBillGroup.setHidden(true)
        amountPastDueGroup.setHidden(true)
        avoidShutoffGroup.setHidden(true)
        catchUpOnAgreementGroup.setHidden(true)
        remainingBalanceGroup.setHidden(true)
        pendingPaymentGroup.setHidden(true)
        restoreServiceGroup.setHidden(true)
    }
    
}


// MARK: - Networking Delegate

extension BillInterfaceController: NetworkingDelegate {
    
    func newAccountDidUpdate(_ account: Account) {
        updateAccountInformation(account)
    }
    
    func currentAccountDidUpdate(_ account: Account) {
        updateAccountInformation(account)
        
        accountChangeAnimation(duration: 1.0)
    }
    
    func accountDetailDidUpdate(_ accountDetail: AccountDetail) {
        
        // Hides all groups
        hideAllStates()
        
        // Resets label
        billAmountTitleLabel.setAttributedText(("--").textWithColorAndFontInRange(color: .white, font: UIFont.preferredFont(forTextStyle: .title1)))
        
        // Shows overarching bill group
        state = .loaded
        
        // Display Account Group
        accountGroup.setHidden(false)
        
        aLog("Account detail did update")
        
        // Retrieve a list of states
        let billStates = BillUtility().generateBillStates(accountDetail: accountDetail)
        
        // Set States
        for state in billStates {
            switch state {
            case .restoreService(let restoreAmount, let dpaReinstAmount):
                restoreServiceGroup.setHidden(false)
                restoreServiceAmountLabel.setText(restoreAmount.currencyString)

                // Alert Banner
                billAlertGroup.setHidden(false)

                if dpaReinstAmount > 0 {
                    billAlertLabel.setText("Your service is off due to non-payment.")
                } else {
                    billAlertLabel.setText("\(restoreAmount.currencyString) is due immediately to restore service.")
                }
                
                // Past Due
                amountPastDueLabel.setText(restoreAmount.currencyString)
            case .avoidShutoff(let amount):
                avoidShutoffGroup.setHidden(false)
                avoidShutoffAmountLabel.setText(amount.currencyString)
                
                // Alert Banner
                billAlertGroup.setHidden(false)
                billAlertLabel.setText("\(amount.currencyString) is due immediately to avoid shutoff.")
                
                // Past Due
                amountPastDueLabel.setText(amount.currencyString)
            case .catchUp(let amount, let date):
                catchUpOnAgreementGroup.setHidden(false)
                catchUpOnAgreementAmountLabel.setText(amount.currencyString)
                catchUpOnAgreementDateLabel.setAttributedText(date.dueBy(shouldColor: true, shouldIncludePrefix: true))

                // Alert Banner
                billAlertGroup.setHidden(false)
                billAlertLabel.setText("\(amount.currencyString) is due \(date.dueBy().string) to catch up on your DPA.")
                
                // Past Due
                amountPastDueLabel.setText(amount.currencyString)
            case .pastDue(let pastDueAmount, let netDueAmount, let remainingBalanceDue):
                amountPastDueGroup.setHidden(false)
                amountPastDueLabel.setText(pastDueAmount.currencyString)

                // Alert Banner
                billAlertGroup.setHidden(false)

                if netDueAmount == pastDueAmount, remainingBalanceDue <= 0 {
                    billAlertLabel.setText("Your bill is past due.")
                } else {
                    billAlertLabel.setText("\(pastDueAmount.currencyString) is due immediately.")
                }
            case .billReady(let amount, let date):
                billAmountGroup.setHidden(false)
                
                // Add Colored Dollar Sign if there is a precarious bill state
                if billStates.contains(where: { $0.isPrecariousBillSituation }) {
                    // White
                    billAmountTitleLabel.setAttributedText((amount.currencyString).textWithColorAndFontInRange(color: .white, font: UIFont.preferredFont(forTextStyle: .title1)))
                } else {
                    // Blue
                    billAmountTitleLabel.setAttributedText((amount.currencyString).textWithColorAndFontInRange(color: UIColor(red: 0.0 / 255.0, green: 162.0 / 255.0, blue: 255.0 / 255.0, alpha: 0.6), font: UIFont.preferredFont(forTextStyle: .title1)))
                }
                
                let text = "Amount due \(date.dueBy().string)"
                if text == "Amount due immediately" {
                    let attributes = [NSMutableAttributedString.Key.foregroundColor: UIColor(red: 255.0 / 255.0, green: 63.0 / 255.0, blue: 14.0 / 255.0, alpha: 1.0)]
                    let attributedText = NSAttributedString(string: text, attributes: attributes)
                    billAmountDescriptionLabel.setAttributedText(attributedText)
                } else {
                    billAmountDescriptionLabel.setText(text)
                }
                
                billPaidGroup.setHidden(true)
            case .autoPay:
                autoPayScheduledPaymentGroup.setHidden(false)
                autoPayScheduledPaymentImage.setImageNamed(AppImage.autoPay.name)
                autoPayScheduledPaymentDetailLabel.setText("You are enrolled in Autopay")
            case .billPaid(let amount):
                billPaidGroup.setHidden(false)
                billPaidAmountLabel.setText(amount.currencyString)
                
                billAmountGroup.setHidden(true)
            case .remainingBalance(let remainingBalanceAmount):
                remainingBalanceGroup.setHidden(false)
                remainingBalanaceAmountLabel.setText(remainingBalanceAmount.currencyString)
                
                // Alert Banner
                billAlertGroup.setHidden(false)
                billAlertLabel.setText("\(remainingBalanceAmount.currencyString) is due immediately.")
            case .paymentPending(let amount):
                pendingPaymentGroup.setHidden(false)
                
                let italicHeadlineFont =
                    UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline).italic()
                let fontAttribute = [NSAttributedString.Key.font : italicHeadlineFont]
                let attributedString = NSAttributedString(string: "-\(amount.currencyString)", attributes: fontAttribute)
                pendingPaymentAmountLabel.setAttributedText(attributedString)
                let italicFootnoteFont =
                    UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote).italic()
                let fontFootnoteAttribute = [NSAttributedString.Key.font : italicFootnoteFont]
                let attributedFootnoteString = NSAttributedString(string: "Pending Payment", attributes: fontFootnoteAttribute)
                pendingPaymentDescriptionLabel.setAttributedText(attributedFootnoteString)
            case .billNotReady:
                autoPayScheduledPaymentGroup.setHidden(false)
                autoPayScheduledPaymentImage.setImageNamed(AppImage.billNotReady.name)
                autoPayScheduledPaymentDetailLabel.setText("Your bill will be available here once it is ready")
                
                billAmountGroup.setHidden(true)
                footerGroup.setHidden(true)
            case .paymentScheduled(let scheduledPayment):
                autoPayScheduledPaymentGroup.setHidden(false)
                autoPayScheduledPaymentImage.setImageNamed(AppImage.scheduledPayment.name)
                autoPayScheduledPaymentDetailLabel.setText("Thank you for scheduling your \(scheduledPayment.amount.currencyString) payment for \(scheduledPayment.date?.mmDdYyyyString ?? "--")")
                
                billAmountGroup.setHidden(true)
            case .mostRecent(let amount, let date):
                guard billStates.contains(where: { $0.shouldShowRecentBill }) else { continue }
                
                mostRecentBillGroup.setHidden(false)
                mostRecentBillAmountLabel.setText(amount.currencyString)
                mostRecentBillDueDateLabel.setAttributedText(date.dueBy(shouldColor: true, shouldIncludePrefix: true))
            }
        }

    }
    
    func accountListDidUpdate(_ accounts: [Account]) {
        clearAllMenuItems()
        
        guard accounts.count > 1 else { return }
        addMenuItem(withImageNamed: AppImage.residential.name, title: "Select Account", action: #selector(presentAccountList))
    }
    
    func accountListAndAccountDetailsDidUpdate(accounts: [Account], accountDetail: AccountDetail?) { }
    
    func maintenanceMode(feature: MainFeature) {
        guard feature == .all || feature == .bill else { return }
        accountGroup.setHidden(false)
        state = .maintenanceMode
    }
    
    func loading(feature: MainFeature) {
        guard feature == .all || feature == .bill else { return }
        state = .loading
    }
    
    func error(_ serviceError: ServiceError, feature: MainFeature) {
        guard feature == .all || feature == .bill else { return }
        
        accountGroup.setHidden(false)
        
        guard serviceError.serviceCode == Errors.Code.passwordProtected else {
            state = .error(serviceError)
            return
        }
        state = .passwordProtected
    }
    
    func outageStatusDidUpdate(_ outageStatus: OutageStatus) { }
    
    func usageStatusDidUpdate(_ billForecast: BillForecastResult) { }

}
