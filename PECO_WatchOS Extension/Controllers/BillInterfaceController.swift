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
    
    @IBOutlet var errorGroup: WKInterfaceGroup! {
        didSet {
            errorGroup.setHidden(true)
        }
    }
    @IBOutlet var errorImage: WKInterfaceImage!
    @IBOutlet var errorTitleLabel: WKInterfaceLabel!
    @IBOutlet var errorDetailLabel: WKInterfaceLabel!
    
    @IBOutlet var billAlertGroup: WKInterfaceGroup! {
        didSet {
            billAlertGroup.setHidden(true)
        }
    }
    @IBOutlet var billAlertLabel: WKInterfaceLabel!

    
    @IBOutlet var billGroup: WKInterfaceGroup! {
        didSet {
            billGroup.setHidden(true)
        }
    }

    @IBOutlet var autoPayScheduledPaymentGroup: WKInterfaceGroup! {
        didSet {
            errorGroup.setHidden(true)
        }
    }
    @IBOutlet var autoPayScheduledPaymentImage: WKInterfaceImage!
    @IBOutlet var autoPayScheduledPaymentDetailLabel: WKInterfaceLabel!
    
    @IBOutlet var billAmountGroup: WKInterfaceGroup! {
        didSet {
            billAmountGroup.setHidden(true)
        }
    }
    @IBOutlet var billAmountTitleLabel: WKInterfaceLabel!
    @IBOutlet var billAmountDescriptionLabel: WKInterfaceLabel!
    
    @IBOutlet var billPaidGroup: WKInterfaceGroup! {
        didSet {
            billPaidGroup.setHidden(true)
        }
    }
    @IBOutlet var billPaidAmountLabel: WKInterfaceLabel!

    @IBOutlet var mostRecentBillGroup: WKInterfaceGroup! {
        didSet {
            mostRecentBillGroup.setHidden(true)
        }
    }
    @IBOutlet var mostRecentBillAmountLabel: WKInterfaceLabel!
    @IBOutlet var mostRecentBillDueDateLabel: WKInterfaceLabel!
    
    @IBOutlet var amountPastDueGroup: WKInterfaceGroup! {
        didSet {
            amountPastDueGroup.setHidden(true)
        }
    }
    @IBOutlet var amountPastDueLabel: WKInterfaceLabel!
    
    @IBOutlet var avoidShutoffGroup: WKInterfaceGroup! {
        didSet {
            avoidShutoffGroup.setHidden(true)
        }
    }
    @IBOutlet var avoidShutoffAmountLabel: WKInterfaceLabel!
    
    @IBOutlet var catchUpOnAgreementGroup: WKInterfaceGroup! {
        didSet {
            catchUpOnAgreementGroup.setHidden(true)
        }
    }
    @IBOutlet var catchUpOnAgreementAmountLabel: WKInterfaceLabel!
    @IBOutlet var catchUpOnAgreementDateLabel: WKInterfaceLabel!
    
    @IBOutlet var remainingBalanceGroup: WKInterfaceGroup! {
        didSet {
            remainingBalanceGroup.setHidden(true)
        }
    }
    @IBOutlet var remainingBalanaceAmountLabel: WKInterfaceLabel!
    @IBOutlet var remainingBalanceDescriptionLabel: WKInterfaceLabel!
    @IBOutlet var remainingBalanceDateLabel: WKInterfaceLabel!
    
    @IBOutlet var pendingPaymentGroup: WKInterfaceGroup! {
        didSet {
            pendingPaymentGroup.setHidden(true)
        }
    }
    @IBOutlet var pendingPaymentAmountLabel: WKInterfaceLabel!
    
    @IBOutlet var restoreServiceGroup: WKInterfaceGroup! {
        didSet {
            restoreServiceGroup.setHidden(true)
        }
    }
    @IBOutlet var restoreServiceAmountLabel: WKInterfaceLabel!
    @IBOutlet var restoreServiceDescriptionLabel: WKInterfaceLabel!
    @IBOutlet var restoreServiceDateLabel: WKInterfaceLabel!
    
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
                aLog("Error: \(error.localizedDescription)")
                try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.askForUpdate : true])
                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: OpenAppOnPhoneInterfaceController.className, context: [:] as AnyObject)])
//                errorGroup.setHidden(false)
//                errorImage.setImageNamed(AppImage.error.name)
//                errorTitleLabel.setHidden(true)
//                errorDetailLabel.setText("Unable to retrieve data at this time.  Please try again later.")
//
//                loadingImageGroup.setHidden(true)
//
//
//                billGroup.setHidden(true)
//
//                aLog("Error: \(error.localizedDescription)")
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
        GATracker.shared.screenView(screenName: BillInterfaceController.className, customParameters: nil)
    }
    
    // MARK: - Helper
    
    @objc private func presentAccountList() {
        presentController(withName: "AccountListInterfaceController", context: nil)
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
    
}


// MARK: - Networking Delegate

extension BillInterfaceController: NetworkingDelegate {

    func currentAccountDidUpdate(_ account: Account) {
        updateAccountInformation(account)
        
        accountChangeAnimation(duration: 1.0)
    }
    
    func accountDetailDidUpdate(_ accountDetail: AccountDetail) {
        state = .loaded
        
        aLog("Account detail did update")
        
        // Pay States, perhaps in the future we could refactor the below code to a utlity class
        
        // Auto Pay
        if accountDetail.billingInfo.netDueAmount ?? 0 > 0, accountDetail.isAutoPay {
            billAmountGroup.setHidden(true)
            
            autoPayScheduledPaymentGroup.setHidden(false)
            autoPayScheduledPaymentImage.setImageNamed(AppImage.autoPay.name)
            autoPayScheduledPaymentDetailLabel.setText("You are enrolled in Autopay")
        } else {
            billAmountGroup.setHidden(false)
            autoPayScheduledPaymentGroup.setHidden(true)
        }
        
        // Scheduled Payment
        if let scheduledPayment = accountDetail.billingInfo.scheduledPayment, scheduledPayment.amount > 0 {
            billAmountGroup.setHidden(true)
            
            autoPayScheduledPaymentGroup.setHidden(false)
            autoPayScheduledPaymentImage.setImageNamed(AppImage.scheduledPayment.name)
            autoPayScheduledPaymentDetailLabel.setText("Thank you for scheduling your \(scheduledPayment.amount.currencyString ?? "--") payment for \(scheduledPayment.date?.mmDdYyyyString ?? "--")")
        } else {
            billAmountGroup.setHidden(false)
            autoPayScheduledPaymentGroup.setHidden(true)
        }
        
        // Net Amount Due
        if let amount = accountDetail.billingInfo.netDueAmount, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate {
            billAmountGroup.setHidden(false)
            billAmountTitleLabel.setAttributedText((amount.currencyString ?? "--").textWithColorInRange(color: .primaryColor, range: NSRange(location: 0, length: 1)))
            billAmountDescriptionLabel.setText("Amount due \(dueDate.dueBy())")
            
            billPaidGroup.setHidden(true)
        } else if let billDate = accountDetail.billingInfo.billDate, let lastPaymentDate = accountDetail.billingInfo.lastPaymentDate, accountDetail.billingInfo.lastPaymentAmount ?? 0 > 0, billDate < lastPaymentDate {
            // Bill Paid
            billAmountGroup.setHidden(true)
            
            billPaidGroup.setHidden(false)
            billPaidAmountLabel.setText(accountDetail.billingInfo.lastPaymentAmount?.currencyString ?? "--")
        } else {
            // Bill Not Ready
            billAmountGroup.setHidden(true)

            autoPayScheduledPaymentGroup.setHidden(false)
            autoPayScheduledPaymentImage.setImageNamed(AppImage.billNotReady.name)
            autoPayScheduledPaymentDetailLabel.setText("Your bill will be available here once it is ready")
        }

        // Pending Payment
        if accountDetail.billingInfo.pendingPayments.first?.amount ?? 0 > 0 {
            let pendingPaymentSum = accountDetail.billingInfo.pendingPayments.reduce(0) { $0 + $1.amount }
            
            if pendingPaymentSum > 0.0 {
                pendingPaymentGroup.setHidden(false)
                
                let italicHeadlineFont =
                    UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline).italic()
                let fontAttribute = [NSAttributedString.Key.font : italicHeadlineFont]
                let attributedString = NSAttributedString(string: "-\(pendingPaymentSum.currencyString ?? "--")", attributes: fontAttribute)
                pendingPaymentAmountLabel.setAttributedText(attributedString)
            } else {
                pendingPaymentGroup.setHidden(true)
            }
        } else {
            pendingPaymentGroup.setHidden(true)
        }

        // Remaining Balance
        if let amount = accountDetail.billingInfo.remainingBalanceDue, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate {
            remainingBalanceGroup.setHidden(false)
            remainingBalanaceAmountLabel.setText(amount.currencyString ?? "--")
            remainingBalanceDateLabel.setText("Due by \(dueDate.mmDdYyyyString)")
        } else {
            remainingBalanceGroup.setHidden(true)
        }

        // Most Recent Bill
        if let amount = accountDetail.billingInfo.currentDueAmount, amount > 0, let dueDate = accountDetail.billingInfo.dueByDate {
            mostRecentBillGroup.setHidden(false)
            mostRecentBillAmountLabel.setText(amount.currencyString ?? "--")
            mostRecentBillDueDateLabel.setText("Due by \(dueDate.mmDdYyyyString)")
        } else {
            mostRecentBillGroup.setHidden(true)
        }

        // Restore Service
        if let amount = accountDetail.billingInfo.restorationAmount, amount > 0, accountDetail.isCutOutNonPay {

            // Bill $ Label Color
            if let amount = accountDetail.billingInfo.netDueAmount, amount > 0 {
                billAmountTitleLabel.setAttributedText((amount.currencyString ?? "--").textWithColorInRange(color: .white, range: NSRange(location: 0, length: 1)))
            }
            
            restoreServiceGroup.setHidden(false)
            restoreServiceAmountLabel.setText(amount.currencyString ?? "--")
            
            avoidShutoffGroup.setHidden(true)
            
            // Alert Banner
            billAlertGroup.setHidden(false)
            billAlertLabel.setText("\(amount.currencyString ?? "--") is due immediately to restore service.")
        } else {
            restoreServiceGroup.setHidden(true)
            billAlertGroup.setHidden(true)
            
            // Avoid Shutoff
            if let amount = accountDetail.billingInfo.disconnectNoticeArrears, amount > 0, accountDetail.billingInfo.isDisconnectNotice {
                avoidShutoffGroup.setHidden(false)
                avoidShutoffAmountLabel.setText(amount.currencyString ?? "--")
                
                // Alert Banner
                billAlertGroup.setHidden(false)
                billAlertLabel.setText("\(amount.currencyString ?? "--") is due immediately to avoid shutoff.")
                
                // Bill $ Label Color
                if let amount = accountDetail.billingInfo.netDueAmount, amount > 0 {
                    billAmountTitleLabel.setAttributedText((amount.currencyString ?? "--").textWithColorInRange(color: .white, range: NSRange(location: 0, length: 1)))
                }
            } else {
                avoidShutoffGroup.setHidden(true)
            }
            
            // Catch up on Agreement
            if let amount = accountDetail.billingInfo.amtDpaReinst, amount > 0, let date = accountDetail.billingInfo.dueByDate {
                catchUpOnAgreementGroup.setHidden(false)
                catchUpOnAgreementAmountLabel.setText(amount.currencyString ?? "--")
                catchUpOnAgreementDateLabel.setText("Due by \(date.mmDdYyyyString)")
                
                // Alert Banner
                billAlertGroup.setHidden(false)
                billAlertLabel.setText("\(amount.currencyString ?? "--") is due by \(date.mmDdYyyyString) to catch up on your DPA.")
                
                // Bill $ Label Color
                if let amount = accountDetail.billingInfo.netDueAmount, amount > 0 {
                    billAmountTitleLabel.setAttributedText((amount.currencyString ?? "--").textWithColorInRange(color: .white, range: NSRange(location: 0, length: 1)))
                }
            } else {
                catchUpOnAgreementGroup.setHidden(true)
            }

            // Amount Past Due
            if let amount = accountDetail.billingInfo.pastDueAmount, amount > 0 {
                amountPastDueGroup.setHidden(false)
                amountPastDueLabel.setText(amount.currencyString ?? "--")
                
                // Alert Banner
                billAlertGroup.setHidden(false)
                
                // Bill $ Label Color
                if let amount = accountDetail.billingInfo.netDueAmount, amount > 0 {
                    billAmountTitleLabel.setAttributedText((amount.currencyString ?? "--").textWithColorInRange(color: .white, range: NSRange(location: 0, length: 1)))
                }
                
                if let netDueAmount = accountDetail.billingInfo.netDueAmount, netDueAmount == amount {
                    billAlertLabel.setText("Your bill is past due.")
                } else {
                    billAlertLabel.setText("\(amount.currencyString ?? "--") is due immediately.")
                }
            } else {
                amountPastDueGroup.setHidden(true)
            }
        }

    }
    
    func accountListDidUpdate(_ accounts: [Account]) {
        clearAllMenuItems()
        
        guard accounts.count > 1 else { return }
        addMenuItem(withImageNamed: AppImage.residential.name, title: "Select Account", action: #selector(presentAccountList))
    }
    
    func maintenanceMode(feature: MainFeature) {
        guard feature == .all || feature == .bill else { return }
        state = .maintenanceMode
    }
    
    func loading(feature: MainFeature) {
        guard feature == .all || feature == .bill else { return }
        state = .loading
    }
    
    func error(_ serviceError: ServiceError, feature: MainFeature) {
        guard feature == .all || feature == .bill else { return }
        guard serviceError.serviceCode == Errors.Code.passwordProtected else {
            state = .error(serviceError)
            return
        }
        state = .passwordProtected
    }
    
    func outageStatusDidUpdate(_ outageStatus: OutageStatus) { }
    
    func usageStatusDidUpdate(_ billForecast: BillForecastResult) { }

}
