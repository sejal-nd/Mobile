//
//  AlertPreferencesViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 9/25/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import UserNotifications

protocol AlertPreferencesViewControllerDelegate: class {
    func alertPreferencesViewControllerDidSavePreferences()
}

class AlertPreferencesViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loadingIndicator: LoadingIndicator!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet weak var saveButton: PrimaryButton!
    
    private let disposeBag = DisposeBag()
        
    weak var delegate: AlertPreferencesViewControllerDelegate?
    
    let viewModel = AlertPreferencesViewModel(alertsService: ServiceFactory.createAlertsService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: AlertPreferencesTableViewCell.className, bundle: nil),
                           forCellReuseIdentifier: AlertPreferencesTableViewCell.className)
        tableView.register(UINib(nibName: AlertPreferencesNotificationsSettingsCell.className, bundle: nil),
                           forCellReuseIdentifier: AlertPreferencesNotificationsSettingsCell.className)
        tableView.register(UINib(nibName: AlertPreferencesLanguageCell.className, bundle: nil),
                           forCellReuseIdentifier: AlertPreferencesLanguageCell.className)
        tableView.register(UINib(nibName: AccountInfoBarCell.className, bundle: nil),
                           forCellReuseIdentifier: AccountInfoBarCell.className)
        
        // Add X Button
        let closeButton = UIBarButtonItem(image: UIImage(named: "ic_close"), style: .plain, target: self, action: #selector(onCancelPress))
                        
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        navigationItem.setLeftBarButton(closeButton, animated: false)
        
        styleViews()
        bindViewModel()
        
        checkForNotificationsPermissions()
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification, object: nil)
            .subscribe(onNext: { [weak self] _ in
                self?.checkForNotificationsPermissions()
            })
            .disposed(by: disposeBag)
        
        errorLabel.isHidden = true
        tableView.isHidden = true
        viewModel.fetchData(onCompletion: { [weak self] in
            guard let self = self else { return }
            
            self.loadingIndicator.isHidden = true
            
            if self.viewModel.isError.value {
                self.tableView.isHidden = true
                self.errorLabel.isHidden = false
            } else {
                self.tableView.isHidden = false
                self.errorLabel.isHidden = true
                
                self.tableView.reloadData()
                UIAccessibility.post(notification: .screenChanged, argument: self.view)
            }
        })
    }
    
    private func checkForNotificationsPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let enabled = settings.authorizationStatus != .denied
                if enabled != self.viewModel.devicePushNotificationsEnabled {
                    self.viewModel.devicePushNotificationsEnabled = enabled
                    switch (self.viewModel.showAccountInfoBar, self.viewModel.showNotificationSettingsView) {
                    case (true, true):
                        self.tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .bottom)
                    case (true, false):
                        self.tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .bottom)
                    case (false, true):
                        self.tableView.insertSections(IndexSet([0]), with: .bottom)
                    case (false, false):
                        self.tableView.deleteSections(IndexSet([0]), with: .bottom)
                    }
                }
            }
        }
    }

    private func styleViews() {
        errorLabel.font = OpenSans.regular.of(textStyle: .body)
        errorLabel.textColor = .deepGray
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }

    private func bindViewModel() {
        viewModel.saveButtonEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.prefsChanged.subscribe(onNext: { [weak self] value in
            self?.viewModel.hasPreferencesChanged = BehaviorRelay(value: value)
            
            // iOS 13 modal
            if #available(iOS 13.0, *) {
                self?.isModalInPresentation = value
            }
        })
        .disposed(by: disposeBag)

        viewModel.prefsChanged.filter { $0 }.take(1)
            .subscribe(onNext: { _ in GoogleAnalytics.log(event: .alertsPrefCenterOffer) })
            .disposed(by: disposeBag)

        saveButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in self?.onSavePress() })
            .disposed(by: disposeBag)
    }
    
    @objc func onSavePress() {
        guard saveButton.isEnabled else { return }
        GoogleAnalytics.log(event: .alertsPrefCenterSave)
        
        LoadingView.show()
        viewModel.saveChanges(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            
            FirebaseUtility.logEvent(.more, parameters: [EventParameter(parameterName: .action, value: .alert_preferences_complete)])
            
            self.delegate?.alertPreferencesViewControllerDidSavePreferences()
            self.dismiss(animated: true, completion: nil)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
        })
        
    }
    
    @objc
    func onCancelPress() {
        if viewModel.hasPreferencesChanged.value {
            let alertVc = UIAlertController(title: NSLocalizedString("Exit Notification Preferences", comment: ""),
                                            message: NSLocalizedString("Are you sure you want to leave without saving your changes?", comment: ""),
                                            preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .destructive, handler: { [weak self] _ in
                self?.dismissModal()
            }))
            present(alertVc, animated: true, completion: nil)
        } else {
            dismissModal()
        }
    }
    
    func showBillIsReadyToggleAlert(isOn: Bool) {
        if isOn {
            if !viewModel.accountDetail.isEBillEnrollment {
                let alertTitle = NSLocalizedString("Go Paperless", comment: "")
                let alertMessage = NSLocalizedString("By selecting this alert, you will be enrolled in paperless billing and you will no longer receive a paper bill in the mail. Paperless billing will begin with your next billing cycle.", comment: "")
                GoogleAnalytics.log(event: .alertseBillEnrollPush)
                
                let alertVc = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { [weak self] _ in
                    FirebaseUtility.logEvent(.alerts, parameters: [EventParameter(parameterName: .action, value: .bill_enroll_push_cancel)])
                    GoogleAnalytics.log(event: .alertseBillEnrollPushCancel)
                    
                    self?.viewModel.billReady.accept(!isOn) // Need to manually set this because .setOn does not trigger rx binding
                }))
                
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { [weak self] _ in
                    FirebaseUtility.logEvent(.alerts, parameters: [EventParameter(parameterName: .action, value: .bill_enroll_push_continue)])
                    GoogleAnalytics.log(event: .alertseBillEnrollPushContinue)
                    
                    self?.viewModel.billReady.accept(true)
                }))
                
                present(alertVc, animated: true, completion: nil)
            } else {
                viewModel.billReady.accept(true)
            }
        } else {
            let alertTitle = NSLocalizedString("Paperless eBill", comment: "")
            let alertMessage = NSLocalizedString("Your Paperless eBill enrollment status will not be affected. If you are enrolled in Paperless eBill, to completely unsubscribe, please update your Paperless eBill preference.", comment: "")
            
            let alertVc = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [weak self] _ in
                
                FirebaseUtility.logEvent(.alerts, parameters: [EventParameter(parameterName: .action, value: .bill_unenroll_push_continue)])

                GoogleAnalytics.log(event: .alertseBillUnenrollPushContinue)

                self?.viewModel.billReady.accept(false)
            }))
            
            present(alertVc, animated: true, completion: nil)
        }
    }
}

extension AlertPreferencesViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count +
            (viewModel.showTopSection ? 1 : 0) +
            (viewModel.showLanguageSection ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && viewModel.showTopSection {
            return (viewModel.showNotificationSettingsView ? 1 : 0) + (viewModel.showAccountInfoBar ? 1 : 0)
        } else if section == numberOfSections(in: tableView) - 1 && viewModel.showLanguageSection {
            return 1
        } else {
            if viewModel.shownSections.contains(section) {
                let offset = viewModel.showTopSection ? 1 : 0
                return viewModel.sections[section - offset].1.count
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !(indexPath.section == 0 && viewModel.showTopSection) else {
            if indexPath.row == 0 && viewModel.showAccountInfoBar {
                return tableView.dequeueReusableCell(withIdentifier: AccountInfoBarCell.className) ?? UITableViewCell()
            } else {
                return tableView.dequeueReusableCell(withIdentifier: AlertPreferencesNotificationsSettingsCell.className) ?? UITableViewCell()
            }
        }
        
        guard !(indexPath.section == numberOfSections(in: tableView) - 1 && viewModel.showLanguageSection) else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AlertPreferencesLanguageCell.className) as? AlertPreferencesLanguageCell else {
                return UITableViewCell()
            }
            
            configureLanguageCell(cell)
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlertPreferencesTableViewCell.className) as? AlertPreferencesTableViewCell else {
            return UITableViewCell()
        }
        
        configureToggleCell(cell, forIndexPath: indexPath)
        return cell
    }
    
    private func configureLanguageCell(_ cell: AlertPreferencesLanguageCell) {
        cell.englishRadioSelectControl.rx.touchUpInside.mapTo(true).bind(to: viewModel.english).disposed(by: cell.disposeBag)
        cell.spanishRadioSelectControl.rx.touchUpInside.mapTo(false).bind(to: viewModel.english).disposed(by: cell.disposeBag)

        cell.spanishRadioSelectControl.rx.touchUpInside.asDriver().drive(onNext: {
            FirebaseUtility.logEvent(.alerts, parameters: [EventParameter(parameterName: .action, value: .english)])
        })
        .disposed(by: cell.disposeBag)
        
        cell.spanishRadioSelectControl.rx.touchUpInside.asDriver().drive(onNext: {
            FirebaseUtility.logEvent(.alerts, parameters: [EventParameter(parameterName: .action, value: .spanish)])
        })
        .disposed(by: cell.disposeBag)

        viewModel.english.asDriver()
            .drive(onNext: { [weak cell] english in
                guard let cell = cell else { return }
                
                cell.englishRadioSelectControl.isSelected = english
                cell.spanishRadioSelectControl.isSelected = !english
                cell.englishRadioSelectControl.accessibilityLabel = String(format: NSLocalizedString("English, option 1 of 2, %@", comment: ""), english ? "selected" : "")
                cell.spanishRadioSelectControl.accessibilityLabel = String(format: NSLocalizedString("Spanish, option 2 of 2, %@", comment: ""), !english ? "selected" : "")
            })
            .disposed(by: cell.disposeBag)
    }
    
    private func configureToggleCell(_ cell: AlertPreferencesTableViewCell, forIndexPath indexPath: IndexPath) {
        let offset = viewModel.showTopSection ? 1 : 0
        let options = viewModel.sections[indexPath.section - offset].1
        let option = options[indexPath.row]
        
        var toggleVariable: BehaviorRelay<Bool>?
        var pickerButtonText: Driver<String>?
        var textFieldOptions: AlertPreferencesViewModel.AlertPrefTextFieldOptions?
        
        switch option {
        case .highUsage:
            toggleVariable = viewModel.highUsage
            
            if viewModel.shouldShowHUABillThreshold {
                var thresholdStr: String? = nil
                if let thresholdValue = viewModel.billThreshold.value {
                    thresholdStr = "$\(thresholdValue)"
                }
                textFieldOptions = AlertPreferencesViewModel.AlertPrefTextFieldOptions(text: thresholdStr, placeHolder: viewModel.billThresholdPlacheHolder.value, showToolTip: true, textFieldType: .currency)
                                
                cell.toolTipTapped = { () in
                    let alertViewController = InfoAlertController(title: NSLocalizedString("Bill Threshold", comment: ""),
                                                                  message: self.viewModel.billThresholdToolTipText)
                    self.present(alertViewController, animated: true)
                }
                cell.checkbox.rx.isChecked.asDriver()
                    .distinctUntilChanged()
                    .drive(onNext: { cell.textField.setEnabled($0) })
                    .disposed(by: cell.disposeBag)
            }
        case .peakTimeSavings:
            toggleVariable = viewModel.peakTimeSavings
        case .smartEnergyRewards:
            toggleVariable = viewModel.smartEnergyRewards
        case .energySavingsDayResults:
            toggleVariable = viewModel.energySavingsDayResults
        case .outage:
            toggleVariable = viewModel.outage
        case .scheduledMaintenanceOutage:
            toggleVariable = viewModel.scheduledMaint
        case .severeWeather:
            toggleVariable = viewModel.severeWeather
        case .billIsReady:
            toggleVariable = viewModel.billReady
            switch Environment.shared.opco {
            case .bge:
                break
            case .comEd, .peco:
                cell.checkbox.rx.isChecked.asDriver()
                    .distinctUntilChanged()
                    .skip(1)
                    .drive(onNext: { [weak self] in self?.showBillIsReadyToggleAlert(isOn: $0) })
                    .disposed(by: cell.disposeBag)
           case .pepco:
                break // todo
            case .ace:
                break // todo
            case .delmarva:
                break // todo
            }
        case .paymentDueReminder:
            toggleVariable = viewModel.paymentDue
            pickerButtonText = viewModel.paymentDueDaysBeforeButtonText
            cell.pickerButton.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    guard let self = self else { return }
                    FirebaseUtility.logEvent(.alerts, parameters: [EventParameter(parameterName: .action, value: .days_before_due_press)])
                    GoogleAnalytics.log(event: .alertsPayRemind)
                    let upperRange = Environment.shared.opco == .bge ? 14 : 7
                    PickerView.showStringPicker(withTitle: NSLocalizedString("Payment Due Reminder", comment: ""),
                                                data: (1...upperRange).map { $0 == 1 ? "\($0) Day" : "\($0) Days" },
                                                selectedIndex: self.viewModel.paymentDueDaysBefore.value - 1,
                                                onDone: { [weak self] value, index in
                                                    guard let self = self else { return }
                                                    if self.viewModel.paymentDueDaysBefore.value != index + 1 {
                                                        self.viewModel.paymentDueDaysBefore.accept(index + 1)
                                                    }
                        },
                                                onCancel: nil)
                    UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select number of days", comment: ""))
                })
                .disposed(by: cell.disposeBag)
        case .paymentPosted:
            toggleVariable = viewModel.paymentPosted
        case .paymentPastDue:
            toggleVariable = viewModel.paymentPastDue
        case .budgetBillingReview:
            toggleVariable = viewModel.budgetBilling
        case .appointmentTracking:
            toggleVariable = viewModel.appointmentTracking
        case .forYourInformation:
            toggleVariable = viewModel.forYourInfo
        case .energyBuddyUpdates:
            toggleVariable = viewModel.energyBuddyUpdates
        }
        
        if let toggleVariable = toggleVariable {
            toggleVariable.asDriver().distinctUntilChanged().drive(cell.checkbox.rx.isChecked).disposed(by: cell.disposeBag)
            cell.checkbox.rx.isChecked.asDriver().skip(1).drive(toggleVariable).disposed(by: cell.disposeBag)
            cell.textField.textField.rx.text.asDriver().skip(1)
                .map { $0?.filter { "0123456789".contains($0) } }
                .drive(onNext: {
                    self.viewModel.billThreshold.accept($0)
                })
                .disposed(by: cell.disposeBag)
            
            viewModel.billThreshold.asDriver().drive(onNext: {
                var amount: Double?
                amount = Double($0 ?? "")
                
                if amount < 1 {
                    amount = nil
                }
                
                if amount > 10000 {
                    cell.textField.setError(NSLocalizedString("Value must be less than or equal to $10,000.", comment: ""))
                }
                else {
                    cell.textField.setError(nil)
                }
                
                cell.textField.textField.text = amount?.currencyNoDecimalString ?? nil
            }).disposed(by: disposeBag)
        }
        
        cell.configure(withPreferenceOption: option,
                       pickerButtonText: pickerButtonText,
                       textFieldOptions: textFieldOptions,
                       isLastItem: options.count - 1 == indexPath.row)
    }
    
}

extension AlertPreferencesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && viewModel.showTopSection {
            return 0.01
        } else if section == numberOfSections(in: tableView) - 1 && viewModel.showLanguageSection {
            return 0.01
        } else {
            return 59
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == numberOfSections(in: tableView) - 1 {
            return 32 // bottom scroll padding without the language radio selection
        } else {
            return 0.01
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !(section == 0 && viewModel.showTopSection) else {
            return UIView(frame: .zero)
        }
        
        guard !(section == numberOfSections(in: tableView) - 1 && viewModel.showLanguageSection) else {
            return UIView(frame: .zero)
        }
        
        let view = AlertPreferencesSectionHeaderView()
        let offset = viewModel.showTopSection ? 1 : 0
        view.configure(withTitle: viewModel.sections[section - offset].0,
                       isExpanded: viewModel.shownSections.contains(section))
        view.tapped = { [weak self] in
            self?.sectionTapped(section)
        }
        
        return view
    }
    
    @objc func sectionTapped(_ section: Int) {
        viewModel.toggleSectionVisibility(section)
        tableView.reloadSections(IndexSet(arrayLiteral: section), with: .fade)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
}


// MARK: - iOS 13 Modal (Swipe to Dismiss)

extension AlertPreferencesViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        
        onCancelPress()
    }
}
