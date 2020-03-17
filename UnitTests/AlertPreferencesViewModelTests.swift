//
//  AlertPreferencesViewModelTests.swift
//  MobileTests
//
//  Created by Marc Shilling on 12/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import XCTest
import RxSwift

class AlertPreferencesViewModelTests: XCTestCase {
    
    var viewModel: AlertPreferencesViewModel!
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        MockUser.current = .default
        MockAccountService.loadAccountsSync()
    }
    
    func testShouldEnrollPaperlessEBill() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        if Environment.shared.opco == .bge {
            XCTAssertFalse(viewModel.shouldEnrollPaperlessEBill, "shouldEnrollPaperlessEBill should always be false for BGE users")
        } else {
            viewModel.billReady.accept(true)
            XCTAssert(viewModel.shouldEnrollPaperlessEBill, "shouldEnrollPaperlessEBill should be true when initialBillReadyValue = false and billReady = true")
        }
    }
    
    func testFetchData() {
        if Environment.shared.opco != .comEd { // BGE/PECO logic
            viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                                  billService: MockBillService(),
                                                  accountService: MockAccountService())
            viewModel.accountDetail = .default
            
            let expect = expectation(description: "callback")
            viewModel.fetchData(onCompletion: {
                // Assert that all our view model vars were set from the Mock AlertPreferences object
                XCTAssert(self.viewModel.outage.value)
                XCTAssert(self.viewModel.scheduledMaint.value)
                XCTAssert(self.viewModel.severeWeather.value)
                XCTAssert(self.viewModel.billReady.value)
                XCTAssert(self.viewModel.paymentDue.value)
                XCTAssert(self.viewModel.paymentDueDaysBefore.value == 99)
                XCTAssert(self.viewModel.budgetBilling.value)
                XCTAssert(self.viewModel.forYourInfo.value)
                expect.fulfill()
            })
            
            waitForExpectations(timeout: 2, handler: { error in
                XCTAssertNil(error, "timeout")
            })
        } else { // ComEd also fetches language preference
            viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                                  billService: MockBillService(),
                                                  accountService: MockAccountService())
            viewModel.accountDetail = .default
            
            let expect = expectation(description: "callback")
            viewModel.fetchData(onCompletion: {
                // Assert that all our view model vars were set from the Mock AlertPreferences object
                XCTAssert(self.viewModel.outage.value)
                XCTAssert(self.viewModel.scheduledMaint.value)
                XCTAssert(self.viewModel.severeWeather.value)
                XCTAssert(self.viewModel.billReady.value)
                XCTAssert(self.viewModel.paymentDue.value)
                XCTAssert(self.viewModel.paymentDueDaysBefore.value == 99)
                XCTAssert(self.viewModel.budgetBilling.value)
                XCTAssert(self.viewModel.forYourInfo.value)
                XCTAssert(self.viewModel.initialEnglishValue)
                XCTAssert(self.viewModel.english.value)
                expect.fulfill()
            })
            
            waitForExpectations(timeout: 2, handler: { error in
                XCTAssertNil(error, "timeout")
            })
            
        }
    }
    
    func testSaveChanges() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        viewModel.accountDetail = .default
        
        let expect = expectation(description: "callback")
        viewModel.saveChanges(onSuccess: { 
            expect.fulfill()
        }, onError: { err in
            XCTFail("Unexpected onError response")
        })
        
        waitForExpectations(timeout: 3, handler: { error in
            XCTAssertNil(error, "timeout")
        })
    }
    
    func testSaveChangesWithLanguageChange() {
        if Environment.shared.opco == .comEd { // Only ComEd has the language preference
            viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                                  billService: MockBillService(),
                                                  accountService: MockAccountService())
            viewModel.accountDetail = .default
            viewModel.initialEnglishValue = false
            viewModel.english.accept(true)
            
            let expect = expectation(description: "callback")
            viewModel.saveChanges(onSuccess: {
                expect.fulfill()
            }, onError: { err in
                XCTFail("Unexpected onError response")
            })
            
            waitForExpectations(timeout: 3, handler: { error in
                XCTAssertNil(error, "timeout")
            })
        }
    }
    
    func testSaveChangesWithEbillEnroll() {
        if Environment.shared.opco != .bge { // Only ComEd/PECO perform eBill changes
            viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                                  billService: MockBillService(),
                                                  accountService: MockAccountService())
            viewModel.accountDetail = .default
            viewModel.initialBillReadyValue = false
            viewModel.billReady.accept(true)
            
            let expect = expectation(description: "callback")
            viewModel.saveChanges(onSuccess: {
                expect.fulfill()
            }, onError: { err in
                XCTFail("Unexpected onError response")
            })
            
            waitForExpectations(timeout: 3, handler: { error in
                XCTAssertNil(error, "timeout")
            })
        }
    }
    
    func testSaveButtonEnabled() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expect = expectation(description: "callback")
        
        viewModel.fetchData { [weak self] in
            guard let self = self else { return }
            self.viewModel.outage.value.toggle()
            self.viewModel.saveButtonEnabled.asObservable().skip(1).take(1).subscribe(onNext: { enabled in
                XCTAssertTrue(enabled, "Save button should be enabled")
                expect.fulfill()
            }).disposed(by: self.disposeBag)
        }
        
        waitForExpectations(timeout: 1, handler: { error in
            XCTAssertNil(error, "timeout")
        })
    }
    
    // MARK: Detail Label Strings
    
    func testOutageDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = NSLocalizedString("Receive updates on unplanned outages due to storms.", comment: "")
        case .comEd:
            expectedString = NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.\n\nNOTE: Outage Notifications will be provided by ComEd on a 24/7 basis. You may be updated with outage information during the overnight hours or over holidays where applicable.", comment: "")
        case .peco:
            expectedString = NSLocalizedString("Receive updates on outages affecting your account, including emergent (storm, accidental) outages and planned outages.", comment: "")
        }
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.outage.detailText,
                       expectedString)
    }
    
    func testScheduledMaintDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = NSLocalizedString("From time to time, BGE must temporarily stop service in order to perform system maintenance or repairs. BGE typically informs customers of planned outages in their area by letter, however, in emergency situations we can inform customers by push notification. Planned outage information will also be available on the planned outages web page on BGE.com.", comment: "")
        case .comEd, .peco:
            expectedString = ""
        }
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.scheduledMaintenanceOutage.detailText,
                       expectedString)
    }
    
    func testSevereWeatherDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = NSLocalizedString("BGE may choose to contact you if a severe-impact storm, such as a hurricane or blizzard, is imminent in our service area to encourage you to prepare for potential outages.", comment: "")
        case .comEd:
            expectedString = NSLocalizedString("Receive an alert about weather conditions that could potentially impact ComEd service in your area.", comment: "")
        case .peco:
            expectedString = NSLocalizedString("Receive an alert about weather conditions that could potentially impact PECO service in your area.", comment: "")
        }
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.severeWeather.detailText,
                       expectedString)
    }
    
    func testBillReadyDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = NSLocalizedString("Receive an alert when your bill is ready to be viewed online. This alert will contain the bill due date and total amount due.", comment: "")
        case .comEd, .peco:
            expectedString = NSLocalizedString("Receive an alert when your monthly bill is ready to be viewed online. By choosing to receive this notification, you will no longer receive a paper bill through the mail.", comment: "")
        }
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.billIsReady.detailText,
                       expectedString)
    }
    
    func testPaymentDueDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = NSLocalizedString("Choose to receive an alert 1 to 14 days before your payment due date. Customers are responsible for payment for the total amount due on their account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
        case .comEd, .peco:
            expectedString = NSLocalizedString("Receive an alert 1 to 7 days before your payment due date. If enrolled in AutoPay, the alert will notify you of when a payment will be deducted from your bank account.\n\nNOTE: You are responsible for payment of the total amount due on your account. Failure to receive this reminder for any reason, such as technical issues, does not extend or release the payment due date.", comment: "")
        }
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.paymentDueReminder.detailText,
                       expectedString)
    }
    
    func testPaymentPostedDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString = NSLocalizedString("Receive a confirmation when your payment has posted to your account. We will include the date and the amount of the posting, as well as your updated total account balance.", comment: "")
        
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.paymentPosted.detailText,
                       expectedString)
    }
    
    func testPaymentPastDueDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString = NSLocalizedString("Receive a friendly reminder 1 day after your due date when you are late in making a payment.", comment: "")
        
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.paymentPastDue.detailText,
                       expectedString)
    }
    
    func testBudgetBillingDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = ""
        case .comEd:
            expectedString = NSLocalizedString("Your monthly Budget Bill Payment may be adjusted every six months to keep your account current with your actual electricity usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
        case .peco:
            expectedString = NSLocalizedString("Your monthly Budget Bill payment may be adjusted every four months to keep your account current with your actual energy usage. Receive a notification when there is an adjustment made to your budget bill plan.", comment: "")
        }
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.budgetBillingReview.detailText,
                       expectedString)
    }
    
    func testAppointmentTrackingDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString = NSLocalizedString("Receive notifications such as confirmations, reminders, and relevant status updates for your scheduled service appointment.", comment: "")
        
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.appointmentTracking.detailText,
                       expectedString)
    }

    
    func testForYourInfoDetailLabelText() {
        viewModel = AlertPreferencesViewModel(alertsService: MockAlertsService(),
                                              billService: MockBillService(),
                                              accountService: MockAccountService())
        let expectedString: String
        switch Environment.shared.opco {
        case .bge:
            expectedString = NSLocalizedString("Occasionally, BGE may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
        case .comEd:
            expectedString = NSLocalizedString("Occasionally, ComEd may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
        case .peco:
            expectedString = NSLocalizedString("Occasionally, PECO may contact you with general information such as tips for saving energy or company-sponsored events occurring in your neighborhood.", comment: "")
        }
        XCTAssertEqual(AlertPreferencesViewModel.AlertPreferencesOptions.forYourInformation.detailText,
                       expectedString)
    }
    
}
