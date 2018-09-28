//
//  AlertPreferencesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol AlertPreferencesViewControllerDelegate: class {
    func alertPreferencesViewControllerDidSavePreferences()
}

class AlertPreferencesViewController: UIViewController {
    
    weak var delegate: AlertPreferencesViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    @IBOutlet weak var notificationsDisabledView: UIView!
    @IBOutlet weak var notificationsDisabledLabel: UILabel!
    @IBOutlet weak var notificationsDisabledButton: UIButton!
    
    @IBOutlet weak var contentStackView: UIStackView!
    
    @IBOutlet weak var outageTitleLabel: UILabel!
    @IBOutlet weak var outageDetailLabel: UILabel!
    @IBOutlet weak var outageSwitch: Switch!
    
    @IBOutlet weak var scheduledMaintView: UIView!
    @IBOutlet weak var scheduledMaintTitleLabel: UILabel!
    @IBOutlet weak var scheduledMaintDetailLabel: UILabel!
    @IBOutlet weak var scheduledMaintSwitch: Switch!
    
    @IBOutlet weak var severeWeatherTitleLabel: UILabel!
    @IBOutlet weak var severeWeatherDetailLabel: UILabel!
    @IBOutlet weak var severeWeatherSwitch: Switch!
    
    @IBOutlet weak var billReadyView: UIView!
    @IBOutlet weak var billReadyTitleLabel: UILabel!
    @IBOutlet weak var billReadyDetailLabel: UILabel!
    @IBOutlet weak var billReadySwitch: Switch!
    
    @IBOutlet weak var paymentDueTitleLabel: UILabel!
    @IBOutlet weak var paymentDueDetailLabel: UILabel!
    @IBOutlet weak var paymentDueSwitch: Switch!
    @IBOutlet weak var paymentDueRemindMeLabel: UILabel!
    @IBOutlet weak var paymentDueDaysBeforeButton: UIButton!
    
    @IBOutlet weak var budgetBillingView: UIView!
    @IBOutlet weak var budgetBillingTitleLabel: UILabel!
    @IBOutlet weak var budgetBillingDetailLabel: UILabel!
    @IBOutlet weak var budgetBillingSwitch: Switch!
    
    @IBOutlet weak var forYourInfoTitleLabel: UILabel!
    @IBOutlet weak var forYourInfoDetailLabel: UILabel!
    @IBOutlet weak var forYourInfoSwitch: Switch!
    
    @IBOutlet weak var languageSelectionView: UIView!
    @IBOutlet weak var languageSelectionLabel: UILabel!
    @IBOutlet weak var englishRadioControl: RadioSelectControl!
    @IBOutlet weak var spanishRadioControl: RadioSelectControl!
    
    @IBOutlet var dividerLineConstraints: [NSLayoutConstraint]!
    
    let viewModel = AlertPreferencesViewModel(alertsService: ServiceFactory.createAlertsService(),
                                              billService: ServiceFactory.createBillService(),
                                              accountService: ServiceFactory.createAccountService())
    
    var hasMadeAnalyticsOffer = false
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Alert Preferences", comment: "")
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        if Environment.shared.opco == .bge {
            accountInfoBar.isHidden = true
            budgetBillingView.isHidden = true
        } else {
            scheduledMaintView.isHidden = true
            if !viewModel.accountDetail.isResidential || viewModel.accountDetail.isFinaled {
                billReadyView.isHidden = true
            }
            if !viewModel.accountDetail.isEBillEligible && !viewModel.accountDetail.isEBillEnrollment {
                billReadyView.isHidden = true
            }
            if !viewModel.accountDetail.isBudgetBillEnrollment {
                budgetBillingView.isHidden = true
            }
        }
        if Environment.shared.opco != .comEd {
            languageSelectionView.isHidden = true
        }
        
        styleViews()
        makeAccessibile()
        bindViewModel()
        
        checkForNotificationsPermissions()
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification, object: nil)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.checkForNotificationsPermissions()
            })
            .disposed(by: disposeBag)
        
        viewModel.fetchData(onCompletion: { [weak self] in
            UIAccessibility.post(notification: .screenChanged, argument: self?.view)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setColoredNavBar()
    }
    
    override func updateViewConstraints() {
        for constraint in dividerLineConstraints {
            constraint.constant = 1.0 / UIScreen.main.scale
        }
        super.updateViewConstraints()
    }
    
    func checkForNotificationsPermissions() {
        if let notificationSettings = UIApplication.shared.currentUserNotificationSettings {
            viewModel.devicePushNotificationsEnabled.value = !notificationSettings.types.isEmpty
        }
    }
    
    private func styleViews() {
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        
        notificationsDisabledView.backgroundColor = .softGray
        notificationsDisabledLabel.textColor = .blackText
        notificationsDisabledLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        notificationsDisabledLabel.text = String(format: NSLocalizedString("Your notifications are currently disabled on your device. Please visit your device settings to allow %@ to send notifications.", comment: ""), Environment.shared.opco.displayString)
        notificationsDisabledButton.setTitleColor(.actionBlue, for: .normal)
        notificationsDisabledButton.titleLabel?.font = SystemFont.medium.of(textStyle: .headline)
        notificationsDisabledButton.titleLabel?.text = NSLocalizedString("Go to Settings", comment: "")
        
        outageTitleLabel.textColor = .blackText
        outageTitleLabel.font = SystemFont.regular.of(textStyle: .title1)
        outageTitleLabel.text = NSLocalizedString("Outage", comment: "")
        outageDetailLabel.textColor = .deepGray
        outageDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        scheduledMaintTitleLabel.textColor = .blackText
        scheduledMaintTitleLabel.font = SystemFont.regular.of(textStyle: .title1)
        scheduledMaintTitleLabel.text = NSLocalizedString("Scheduled Maintenance Outage", comment: "")
        scheduledMaintDetailLabel.textColor = .deepGray
        scheduledMaintDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        severeWeatherTitleLabel.textColor = .blackText
        severeWeatherTitleLabel.font = SystemFont.regular.of(textStyle: .title1)
        severeWeatherTitleLabel.text = NSLocalizedString("Severe Weather", comment: "")
        severeWeatherDetailLabel.textColor = .deepGray
        severeWeatherDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        billReadyTitleLabel.textColor = .blackText
        billReadyTitleLabel.font = SystemFont.regular.of(textStyle: .title1)
        billReadyTitleLabel.text = NSLocalizedString("Bill is Ready", comment: "")
        billReadyDetailLabel.textColor = .deepGray
        billReadyDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        paymentDueTitleLabel.textColor = .blackText
        paymentDueTitleLabel.font = SystemFont.regular.of(textStyle: .title1)
        paymentDueTitleLabel.text = NSLocalizedString("Payment Due Reminder", comment: "")
        paymentDueRemindMeLabel.textColor = .deepGray
        paymentDueRemindMeLabel.font = SystemFont.regular.of(textStyle: .headline)
        paymentDueRemindMeLabel.text = NSLocalizedString("Remind me", comment: "")
        paymentDueDaysBeforeButton.setTitleColor(.actionBlue, for: .normal)
        paymentDueDaysBeforeButton.titleLabel?.font = SystemFont.regular.of(textStyle: .headline)
        paymentDueDetailLabel.textColor = .deepGray
        paymentDueDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        budgetBillingTitleLabel.textColor = .blackText
        budgetBillingTitleLabel.font = SystemFont.regular.of(textStyle: .title1)
        budgetBillingTitleLabel.text = NSLocalizedString("Budget Billing Review", comment: "")
        budgetBillingDetailLabel.textColor = .deepGray
        budgetBillingDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        forYourInfoTitleLabel.textColor = .blackText
        forYourInfoTitleLabel.font = SystemFont.regular.of(textStyle: .title1)
        forYourInfoTitleLabel.text = NSLocalizedString("For Your Information", comment: "")
        forYourInfoDetailLabel.textColor = .deepGray
        forYourInfoDetailLabel.font = SystemFont.regular.of(textStyle: .footnote)
    
        languageSelectionLabel.textColor = .blackText
        languageSelectionLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        languageSelectionLabel.text = NSLocalizedString("I would like to receive my Notifications in", comment: "")
    }
    
    private func makeAccessibile() {
        outageTitleLabel.isAccessibilityElement = false
        outageSwitch.accessibilityLabel = outageTitleLabel.text
        scheduledMaintTitleLabel.isAccessibilityElement = false
        scheduledMaintSwitch.accessibilityLabel = scheduledMaintTitleLabel.text
        severeWeatherTitleLabel.isAccessibilityElement = false
        severeWeatherSwitch.accessibilityLabel = severeWeatherTitleLabel.text
        billReadyTitleLabel.isAccessibilityElement = false
        billReadySwitch.accessibilityLabel = billReadyTitleLabel.text
        paymentDueTitleLabel.isAccessibilityElement = false
        paymentDueSwitch.accessibilityLabel = paymentDueTitleLabel.text
        budgetBillingTitleLabel.isAccessibilityElement = false
        budgetBillingSwitch.accessibilityLabel = budgetBillingTitleLabel.text
        forYourInfoTitleLabel.isAccessibilityElement = false
        forYourInfoSwitch.accessibilityLabel = forYourInfoTitleLabel.text
    }
    
    private func bindViewModel() {
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.devicePushNotificationsEnabled.asDriver().drive(notificationsDisabledView.rx.isHidden).disposed(by: disposeBag)
        
        // Pain in the butt code to make VoiceOver not read this stuff when it's hidden:
        viewModel.devicePushNotificationsEnabled.asDriver().not().drive(notificationsDisabledLabel.rx.isAccessibilityElement).disposed(by: disposeBag)
        viewModel.devicePushNotificationsEnabled.asDriver().not().drive(notificationsDisabledButton.rx.isAccessibilityElement).disposed(by: disposeBag)
        viewModel.devicePushNotificationsEnabled.asDriver().not().drive(notificationsDisabledButton.titleLabel!.rx.isAccessibilityElement).disposed(by: disposeBag)
        viewModel.devicePushNotificationsEnabled.asDriver().drive(notificationsDisabledButton.rx.accessibilityElementsHidden).disposed(by: disposeBag)

        viewModel.shouldShowContent.not().drive(contentStackView.rx.isHidden).disposed(by: disposeBag)
        viewModel.saveButtonEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
        
        // Detail Label Text
        outageDetailLabel.text = viewModel.outageDetailLabelText
        scheduledMaintDetailLabel.text = viewModel.scheduledMaintDetailLabelText
        severeWeatherDetailLabel.text = viewModel.severeWeatherDetailLabelText
        billReadyDetailLabel.text = viewModel.billReadyDetailLabelText
        paymentDueDetailLabel.text = viewModel.paymentDueDetailLabelText
        budgetBillingDetailLabel.text = viewModel.budgetBillingDetailLabelText
        forYourInfoDetailLabel.text = viewModel.forYourInfoDetailLabelText
        
        // Switch States
        outageSwitch.rx.isOn.bind(to: viewModel.outage).disposed(by: disposeBag)
        viewModel.outage.asObservable().bind(to: outageSwitch.rx.isOn).disposed(by: disposeBag)
        scheduledMaintSwitch.rx.isOn.bind(to: viewModel.scheduledMaint).disposed(by: disposeBag)
        viewModel.scheduledMaint.asObservable().bind(to: scheduledMaintSwitch.rx.isOn).disposed(by: disposeBag)
        severeWeatherSwitch.rx.isOn.bind(to: viewModel.severeWeather).disposed(by: disposeBag)
        viewModel.severeWeather.asObservable().bind(to: severeWeatherSwitch.rx.isOn).disposed(by: disposeBag)
        billReadySwitch.rx.isOn.bind(to: viewModel.billReady).disposed(by: disposeBag)
        viewModel.billReady.asObservable().bind(to: billReadySwitch.rx.isOn).disposed(by: disposeBag)
        paymentDueSwitch.rx.isOn.bind(to: viewModel.paymentDue).disposed(by: disposeBag)
        viewModel.paymentDue.asObservable().bind(to: paymentDueSwitch.rx.isOn).disposed(by: disposeBag)
        budgetBillingSwitch.rx.isOn.bind(to: viewModel.budgetBilling).disposed(by: disposeBag)
        viewModel.budgetBilling.asObservable().bind(to: budgetBillingSwitch.rx.isOn).disposed(by: disposeBag)
        forYourInfoSwitch.rx.isOn.bind(to: viewModel.forYourInfo).disposed(by: disposeBag)
        viewModel.forYourInfo.asObservable().bind(to: forYourInfoSwitch.rx.isOn).disposed(by: disposeBag)
        
        viewModel.paymentDueDaysBeforeButtonText.asObservable().subscribe(onNext: { [weak self] buttonText in
            UIView.performWithoutAnimation { // Prevents ugly setTitle animation
                self?.paymentDueDaysBeforeButton.setTitle(buttonText, for: .normal)
                self?.paymentDueDaysBeforeButton.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)
        
        viewModel.english.asObservable().subscribe(onNext: { [weak self] english in
            self?.englishRadioControl.isSelected = english
            self?.spanishRadioControl.isSelected = !english
            self?.englishRadioControl.accessibilityLabel = String(format: NSLocalizedString("English, option 1 of 2, %@", comment: ""), english ? "selected" : "")
            self?.spanishRadioControl.accessibilityLabel = String(format: NSLocalizedString("Spanish, option 2 of 2, %@", comment: ""), !english ? "selected" : "")
        }).disposed(by: disposeBag)
    }
    
    @IBAction func onNotificationsDisabledButtonPress(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Analytics.log(event: .alertsDevSet)
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func onPaymentDueDaysBeforeButtonPress(_ sender: Any) {
        Analytics.log(event: .alertsPayRemind)
        let upperRange = Environment.shared.opco == .bge ? 14 : 7
        PickerView.showStringPicker(withTitle: NSLocalizedString("Payment Due Reminder", comment: ""),
            data: (1...upperRange).map { $0 == 1 ? "\($0) Day" : "\($0) Days" },
            selectedIndex: viewModel.paymentDueDaysBefore.value - 1,
            onDone: { [weak self] value, index in
                guard let `self` = self else { return }
                if self.viewModel.paymentDueDaysBefore.value != index + 1 {
                    if self.viewModel.paymentDue.value {
                        self.makeAnalyticsOffer()
//                        self.viewModel.userChangedPrefs.value = true
                    }
                    self.viewModel.paymentDueDaysBefore.value = index + 1
                }
            },
            onCancel: nil)
        UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select number of days", comment: ""))
    }
    
    @IBAction func onSwitchToggle(_ sender: Switch) {
        if sender == billReadySwitch && Environment.shared.opco != .bge { // ComEd/PECO only requirement
            if sender.isOn {
                if !viewModel.accountDetail.isEBillEnrollment {
                    let alertTitle = NSLocalizedString("Go Paperless", comment: "")
                    let alertMessage = NSLocalizedString("By selecting this alert, you will be enrolled in paperless billing and you will no longer receive a paper bill in the mail. Paperless billing will begin with your next billing cycle.", comment: "")
                    Analytics.log(event: .alertseBillEnrollPush)
                    
                    let alertVc = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { [weak self, weak sender] _ in
                        if sender?.isOn ?? false {
                            Analytics.log(event: .alertseBillEnrollPushCancel)
                        } else {
                            Analytics.log(event: .alertseBillUnenrollPushCancel)
                        }
                        self?.viewModel.billReady.value = !(sender?.isOn ?? false) // Need to manually set this because .setOn does not trigger rx binding
                    }))
                    alertVc.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { [weak self, weak sender] _ in
                        if sender?.isOn ?? false {
                            Analytics.log(event: .alertseBillEnrollPushContinue)
                        } else {
                            Analytics.log(event: .alertseBillUnenrollPushContinue)
                        }
                        self?.makeAnalyticsOffer()
//                        self?.viewModel.userChangedPrefs.value = true
                    }))
                    
                    present(alertVc, animated: true, completion: nil)
                } else {
                    makeAnalyticsOffer()
//                    viewModel.userChangedPrefs.value = true
                }
            } else {
                let alertTitle = NSLocalizedString("Paperless eBill", comment: "")
                let alertMessage = NSLocalizedString("Your Paperless eBill enrollment status will not be affected. If you are enrolled in Paperless eBill, to completely unsubscribe, please update your Paperless eBill preference.", comment: "")
                
                let alertVc = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [weak self] _ in
                    self?.makeAnalyticsOffer()
//                    self?.viewModel.userChangedPrefs.value = true
                }))
                
                present(alertVc, animated: true, completion: nil)
            }
        } else {
            makeAnalyticsOffer()
//            viewModel.userChangedPrefs.value = true
        }
    }
    
    @IBAction func onLanguageRadioControlPress(_ sender: RadioSelectControl) {
        if sender == englishRadioControl {
            Analytics.log(event: .alertsEnglish)
        } else if sender == spanishRadioControl {
            Analytics.log(event: .alertsSpanish)
        }
        
        let newVal = sender == englishRadioControl
        if newVal != viewModel.english.value {
            makeAnalyticsOffer()
//            viewModel.userChangedPrefs.value = true
            viewModel.english.value = newVal
        }
    }
    
    @objc func onCancelPress() {
//        if viewModel.userChangedPrefs.value {
//            let alertVc = UIAlertController(title: NSLocalizedString("Exit Notification Preferences", comment: ""),
//                                            message: NSLocalizedString("Are you sure you want to leave without saving your changes?", comment: ""),
//                                            preferredStyle: .alert)
//            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
//            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .destructive, handler: { [weak self] _ in
//                self?.navigationController?.popViewController(animated: true)
//            }))
//            present(alertVc, animated: true, completion: nil)
//        } else {
//            navigationController?.popViewController(animated: true)
//        }
    }
    
    @objc func onSavePress() {
        Analytics.log(event: .alertsPrefCenterSave)
        
        LoadingView.show()
        viewModel.saveChanges(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let `self` = self else { return }
            self.delegate?.alertPreferencesViewControllerDidSavePreferences()
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errMessage in
            LoadingView.hide()
            let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertVc, animated: true, completion: nil)
        })

    }
    
    private func makeAnalyticsOffer() {
        if !hasMadeAnalyticsOffer {
            hasMadeAnalyticsOffer = true
            Analytics.log(event: .alertsPrefCenterOffer)
        }
    }
    

}
