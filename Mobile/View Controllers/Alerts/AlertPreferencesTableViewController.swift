//
//  AlertPreferencesTableViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertPreferencesTableViewController: UIViewController {
    
    @IBOutlet private weak var accountInfoBar: AccountInfoBar?
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loadingIndicator: LoadingIndicator!
    @IBOutlet private weak var errorLabel: UILabel!
    
    @IBOutlet private weak var languageSelectionView: UIView!
    @IBOutlet private weak var languageSelectionLabel: UILabel!
    @IBOutlet private weak var englishRadioControl: RadioSelectControl!
    @IBOutlet private weak var spanishRadioControl: RadioSelectControl!
    
    private let disposeBag = DisposeBag()
    
    private var saveButton: UIBarButtonItem!
    
    weak var delegate: AlertPreferencesViewControllerDelegate?
    
    let viewModel = AlertPreferencesViewModel(alertsService: ServiceFactory.createAlertsService(), billService: ServiceFactory.createBillService())
    
    var hasMadeAnalyticsOffer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: AlertPreferencesTableViewCell.className, bundle: nil),
                           forCellReuseIdentifier: AlertPreferencesTableViewCell.className)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        styleViews()
        bindViewModel()
        
        if Environment.shared.opco == .bge {
            accountInfoBar?.isHidden = true
            accountInfoBar?.removeFromSuperview()
            accountInfoBar = nil
            //            budgetBillingView.isHidden = true
        } else {
            //            scheduledMaintView.isHidden = true
            //            if !viewModel.accountDetail.isResidential || viewModel.accountDetail.isFinaled {
            //                billReadyView.isHidden = true
            //            }
            //            if !viewModel.accountDetail.isEBillEligible && !viewModel.accountDetail.isEBillEnrollment {
            //                billReadyView.isHidden = true
            //            }
            //            if !viewModel.accountDetail.isBudgetBillEnrollment {
            //                budgetBillingView.isHidden = true
            //            }
        }
        
        if Environment.shared.opco != .comEd {
            languageSelectionView.isHidden = true
        }
        
        checkForNotificationsPermissions()
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification, object: nil)
            .subscribe(onNext: { [weak self] _ in
                self?.checkForNotificationsPermissions()
            })
            .disposed(by: disposeBag)
        
        
        tableView.isHidden = true
        viewModel.fetchData(onCompletion: { [weak self] in
            self?.tableView.isHidden = false
            UIAccessibility.post(notification: .screenChanged, argument: self?.view)
        })
    }
    
    private func checkForNotificationsPermissions() {
        if let notificationSettings = UIApplication.shared.currentUserNotificationSettings {
            viewModel.devicePushNotificationsEnabled.value = !notificationSettings.types.isEmpty
        }
    }

    private func styleViews() {
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
//
//        notificationsDisabledView.backgroundColor = .softGray
//        notificationsDisabledLabel.textColor = .blackText
//        notificationsDisabledLabel.font = SystemFont.regular.of(textStyle: .subheadline)
//        notificationsDisabledLabel.text = String(format: NSLocalizedString("Your notifications are currently disabled on your device. Please visit your device settings to allow %@ to send notifications.", comment: ""), Environment.shared.opco.displayString)
//        notificationsDisabledButton.setTitleColor(.actionBlue, for: .normal)
//        notificationsDisabledButton.titleLabel?.font = SystemFont.medium.of(textStyle: .headline)
//        notificationsDisabledButton.titleLabel?.text = NSLocalizedString("Go to Settings", comment: "")

        languageSelectionLabel.textColor = .blackText
        languageSelectionLabel.font = SystemFont.bold.of(textStyle: .subheadline)
        languageSelectionLabel.text = NSLocalizedString("I would like to receive my Notifications in", comment: "")
    }

    private func bindViewModel() {
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.saveButtonEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.english.asObservable().subscribe(onNext: { [weak self] english in
            self?.englishRadioControl.isSelected = english
            self?.spanishRadioControl.isSelected = !english
            self?.englishRadioControl.accessibilityLabel = String(format: NSLocalizedString("English, option 1 of 2, %@", comment: ""), english ? "selected" : "")
            self?.spanishRadioControl.accessibilityLabel = String(format: NSLocalizedString("Spanish, option 2 of 2, %@", comment: ""), !english ? "selected" : "")
        }).disposed(by: disposeBag)
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
            viewModel.userChangedPrefs.value = true
            viewModel.english.value = newVal
        }
    }
    
    @objc func onCancelPress() {
        if viewModel.userChangedPrefs.value {
            let alertVc = UIAlertController(title: NSLocalizedString("Exit Notification Preferences", comment: ""),
                                            message: NSLocalizedString("Are you sure you want to leave without saving your changes?", comment: ""),
                                            preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .destructive, handler: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func onSavePress() {
        Analytics.log(event: .alertsPrefCenterSave)
        
        LoadingView.show()
        viewModel.saveChanges(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
//            self.delegate?.alertPreferencesViewControllerDidSavePreferences(self)
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

extension AlertPreferencesTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlertPreferencesTableViewCell.className) as? AlertPreferencesTableViewCell else {
            return UITableViewCell()
        }
        
        let option = viewModel.sections[indexPath.section][indexPath.row]
        
        let toggleValue: Variable<Bool>
        var pickerButtonText: Driver<String>?
        var onPickerButtonPress: (() -> ())?
        switch option {
        case .outage:
            toggleValue = viewModel.outage
        case .scheduledMaintenanceOutage:
            toggleValue = viewModel.scheduledMaint
        case .severeWeather:
            toggleValue = viewModel.severeWeather
        case .billIsReady:
            toggleValue = viewModel.billReady
        case .paymentDueReminder:
            toggleValue = viewModel.paymentDue
            pickerButtonText = viewModel.paymentDueDaysBeforeButtonText
            onPickerButtonPress = { [weak self] in
                guard let self = self else { return }
                
                Analytics.log(event: .alertsPayRemind)
                let upperRange = Environment.shared.opco == .bge ? 14 : 7
                PickerView.showStringPicker(withTitle: NSLocalizedString("Payment Due Reminder", comment: ""),
                                            data: (1...upperRange).map { $0 == 1 ? "\($0) Day" : "\($0) Days" },
                                            selectedIndex: self.viewModel.paymentDueDaysBefore.value - 1,
                                            onDone: { [weak self] value, index in
                                                guard let self = self else { return }
                                                if self.viewModel.paymentDueDaysBefore.value != index + 1 {
                                                    if self.viewModel.paymentDue.value {
                                                        self.makeAnalyticsOffer()
                                                        self.viewModel.userChangedPrefs.value = true
                                                    }
                                                    self.viewModel.paymentDueDaysBefore.value = index + 1
                                                }
                    },
                                            onCancel: nil)
                UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select number of days", comment: ""))
            }
        case .budgetBillingReview:
            toggleValue = viewModel.budgetBilling
        case .forYourInformation:
            toggleValue = viewModel.forYourInfo
        }
        
        cell.configure(withPreferenceOption: option,
                       toggleValue: toggleValue,
                       pickerButtonText: pickerButtonText,
                       onPickerButtonPress: onPickerButtonPress)
        
        return cell
    }
    
    
}
