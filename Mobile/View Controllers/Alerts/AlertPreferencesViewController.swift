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
    
    private let disposeBag = DisposeBag()
    
    private var saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: nil, action: nil)
    private let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    
    weak var delegate: AlertPreferencesViewControllerDelegate?
    
    let viewModel = AlertPreferencesViewModel(alertsService: ServiceFactory.createAlertsService(),
                                              billService: ServiceFactory.createBillService(),
                                              accountService: ServiceFactory.createAccountService())
    
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
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
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
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }

    private func bindViewModel() {
        viewModel.saveButtonEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.prefsChanged.filter { $0 }.take(1)
            .subscribe(onNext: { _ in Analytics.log(event: .alertsPrefCenterOffer) })
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.prefsChanged)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.onCancelPress(prefsChanged: $0) })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in self?.onSavePress() })
            .disposed(by: disposeBag)
    }
    
    @objc func onSavePress() {
        Analytics.log(event: .alertsPrefCenterSave)
        
        LoadingView.show()
        viewModel.saveChanges(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            self.delegate?.alertPreferencesViewControllerDidSavePreferences()
            self.navigationController?.popViewController(animated: true)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
        })
        
    }
    
    func onCancelPress(prefsChanged: Bool) {
        if prefsChanged {
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
    
    func showBillIsReadyToggleAlert(isOn: Bool) {
        if isOn {
            if !viewModel.accountDetail.isEBillEnrollment {
                let alertTitle = NSLocalizedString("Go Paperless", comment: "")
                let alertMessage = NSLocalizedString("By selecting this alert, you will be enrolled in paperless billing and you will no longer receive a paper bill in the mail. Paperless billing will begin with your next billing cycle.", comment: "")
                Analytics.log(event: .alertseBillEnrollPush)
                
                let alertVc = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { [weak self] _ in
                    if isOn {
                        Analytics.log(event: .alertseBillEnrollPushCancel)
                    } else {
                        Analytics.log(event: .alertseBillUnenrollPushCancel)
                    }
                    self?.viewModel.billReady.value = !isOn // Need to manually set this because .setOn does not trigger rx binding
                }))
                
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: { [weak self] _ in
                    if isOn {
                        Analytics.log(event: .alertseBillEnrollPushContinue)
                    } else {
                        Analytics.log(event: .alertseBillUnenrollPushContinue)
                    }
                    self?.viewModel.billReady.value = true
                }))
                
                present(alertVc, animated: true, completion: nil)
            } else {
                viewModel.billReady.value = true
            }
        } else {
            let alertTitle = NSLocalizedString("Paperless eBill", comment: "")
            let alertMessage = NSLocalizedString("Your Paperless eBill enrollment status will not be affected. If you are enrolled in Paperless eBill, to completely unsubscribe, please update your Paperless eBill preference.", comment: "")
            
            let alertVc = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            
            alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [weak self] _ in
                self?.viewModel.billReady.value = false
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
            let offset = viewModel.showTopSection ? 1 : 0
            return viewModel.sections[section - offset].1.count
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
        let option = viewModel.sections[indexPath.section - offset].1[indexPath.row]
        
        var toggleVariable: Variable<Bool>?
        var pickerButtonText: Driver<String>?
        switch option {
        case .outage:
            toggleVariable = viewModel.outage
        case .scheduledMaintenanceOutage:
            toggleVariable = viewModel.scheduledMaint
        case .severeWeather:
            toggleVariable = viewModel.severeWeather
        case .billIsReady:
            switch Environment.shared.opco {
            case .bge:
                toggleVariable = viewModel.billReady
            case .comEd, .peco:
                cell.toggle.rx.isOn.asDriver()
                    .skip(1)
                    .drive(onNext: { [weak self] in self?.showBillIsReadyToggleAlert(isOn: $0) })
                    .disposed(by: cell.disposeBag)
            }
        case .paymentDueReminder:
            toggleVariable = viewModel.paymentDue
            pickerButtonText = viewModel.paymentDueDaysBeforeButtonText
            cell.pickerButton.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    guard let self = self else { return }
                    
                    Analytics.log(event: .alertsPayRemind)
                    let upperRange = Environment.shared.opco == .bge ? 14 : 7
                    PickerView.showStringPicker(withTitle: NSLocalizedString("Payment Due Reminder", comment: ""),
                                                data: (1...upperRange).map { $0 == 1 ? "\($0) Day" : "\($0) Days" },
                                                selectedIndex: self.viewModel.paymentDueDaysBefore.value - 1,
                                                onDone: { [weak self] value, index in
                                                    guard let self = self else { return }
                                                    if self.viewModel.paymentDueDaysBefore.value != index + 1 {
                                                        self.viewModel.paymentDueDaysBefore.value = index + 1
                                                    }
                        },
                                                onCancel: nil)
                    UIAccessibility.post(notification: .layoutChanged, argument: NSLocalizedString("Please select number of days", comment: ""))
                })
                .disposed(by: cell.disposeBag)
        case .budgetBillingReview:
            toggleVariable = viewModel.budgetBilling
        case .appointmentTracking:
            toggleVariable = viewModel.appointmentTracking
        case .forYourInformation:
            toggleVariable = viewModel.forYourInfo
        }
        
        if let toggleVariable = toggleVariable {
            toggleVariable.asDriver().distinctUntilChanged().drive(cell.toggle.rx.isOn).disposed(by: cell.disposeBag)
            cell.toggle.rx.isOn.asDriver().skip(1).drive(toggleVariable).disposed(by: cell.disposeBag)
        }
        
        cell.configure(withPreferenceOption: option,
                       pickerButtonText: pickerButtonText)
    }
    
}

extension AlertPreferencesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && viewModel.showTopSection {
            return 0.01
        } else if section == numberOfSections(in: tableView) - 1 && viewModel.showLanguageSection {
            return 0.01
        } else {
            return 73
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
        view.configure(withTitle: viewModel.sections[section - offset].0)
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
}
