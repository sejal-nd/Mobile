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
    
    @IBOutlet private weak var languageSelectionView: UIView?
    @IBOutlet private weak var languageSelectionLabel: UILabel?
    @IBOutlet private weak var englishRadioControl: RadioSelectControl?
    @IBOutlet private weak var spanishRadioControl: RadioSelectControl?
    
    private let disposeBag = DisposeBag()
    
    private var saveButton: UIBarButtonItem!
    private let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    
    weak var delegate: AlertPreferencesViewControllerDelegate?
    
    let viewModel = AlertPreferencesViewModel(alertsService: ServiceFactory.createAlertsService(),
                                              billService: ServiceFactory.createBillService(),
                                              accountService: ServiceFactory.createAccountService())
    
    var hasMadeAnalyticsOffer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: AlertPreferencesTableViewCell.className, bundle: nil),
                           forCellReuseIdentifier: AlertPreferencesTableViewCell.className)
        
        saveButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""), style: .done, target: self, action: #selector(onSavePress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        styleViews()
        bindViewModel()
        
        if Environment.shared.opco == .bge {
            accountInfoBar?.isHidden = true
            accountInfoBar?.removeFromSuperview()
            accountInfoBar = nil
            tableView.tableHeaderView?.removeFromSuperview()
            tableView.tableHeaderView = nil
        }
        
        if Environment.shared.opco != .comEd {
            languageSelectionView?.isHidden = true
            languageSelectionView?.removeFromSuperview()
            languageSelectionView = nil
            tableView.tableFooterView?.removeFromSuperview()
            tableView.tableFooterView = nil
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
            self?.tableView.reloadData()
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
        
//        notificationsDisabledView.backgroundColor = .softGray
//        notificationsDisabledLabel.textColor = .blackText
//        notificationsDisabledLabel.font = SystemFont.regular.of(textStyle: .subheadline)
//        notificationsDisabledLabel.text = String(format: NSLocalizedString("Your notifications are currently disabled on your device. Please visit your device settings to allow %@ to send notifications.", comment: ""), Environment.shared.opco.displayString)
//        notificationsDisabledButton.setTitleColor(.actionBlue, for: .normal)
//        notificationsDisabledButton.titleLabel?.font = SystemFont.medium.of(textStyle: .headline)
//        notificationsDisabledButton.titleLabel?.text = NSLocalizedString("Go to Settings", comment: "")

        languageSelectionLabel?.textColor = .blackText
        languageSelectionLabel?.font = SystemFont.bold.of(textStyle: .subheadline)
        languageSelectionLabel?.text = NSLocalizedString("I would like to receive my Notifications in", comment: "")
    }

    private func bindViewModel() {
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.isError.asDriver().not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.saveButtonEnabled.drive(saveButton.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.english.asObservable().subscribe(onNext: { [weak self] english in
            self?.englishRadioControl?.isSelected = english
            self?.spanishRadioControl?.isSelected = !english
            self?.englishRadioControl?.accessibilityLabel = String(format: NSLocalizedString("English, option 1 of 2, %@", comment: ""), english ? "selected" : "")
            self?.spanishRadioControl?.accessibilityLabel = String(format: NSLocalizedString("Spanish, option 2 of 2, %@", comment: ""), !english ? "selected" : "")
        }).disposed(by: disposeBag)
        
        viewModel.prefsChanged.filter { $0 }.take(1)
            .subscribe(onNext: { _ in Analytics.log(event: .alertsPrefCenterOffer) })
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap.asObservable()
            .withLatestFrom(viewModel.prefsChanged)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in self?.onCancelPress(prefsChanged: $0) })
            .disposed(by: disposeBag)
    }
    
    @IBAction func onLanguageRadioControlPress(_ sender: RadioSelectControl) {
        if sender == englishRadioControl {
            Analytics.log(event: .alertsEnglish)
        } else if sender == spanishRadioControl {
            Analytics.log(event: .alertsSpanish)
        }
        
        viewModel.english.value = sender == englishRadioControl
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

extension AlertPreferencesTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].1.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlertPreferencesTableViewCell.className) as? AlertPreferencesTableViewCell else {
            return UITableViewCell()
        }
        
        let option = viewModel.sections[indexPath.section].1[indexPath.row]
        
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
        case .forYourInformation:
            toggleVariable = viewModel.forYourInfo
        }
        
        if let toggleVariable = toggleVariable {
            toggleVariable.asDriver().distinctUntilChanged().drive(cell.toggle.rx.isOn).disposed(by: cell.disposeBag)
            cell.toggle.rx.isOn.asDriver().drive(toggleVariable).disposed(by: cell.disposeBag)
        }
        
        cell.configure(withPreferenceOption: option,
                       pickerButtonText: pickerButtonText)
        
        return cell
    }
    
    
}
