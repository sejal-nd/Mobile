//
//  MoreViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import Toast_Swift

class MoreViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton! {
        didSet {
            signOutButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
            signOutButton.setTitleColor(.white, for: .normal)
        }
    }
    
    @IBOutlet private weak var versionLabel: UILabel! {
        didSet {
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                switch Environment.shared.environmentName {
                case .prod, .prodbeta:
                    versionLabel.text = String(format: NSLocalizedString("Version %@", comment: ""), version)
                default:
                    versionLabel.text = String(format: NSLocalizedString("Version %@ - MBE %@", comment: ""), version, Environment.shared.mcsInstanceName)
                }
            } else {
                versionLabel.text = nil
            }
            
            versionLabel.font = OpenSans.regular.of(textStyle: .footnote)
            versionLabel.textColor = .white
        }
    }

    let viewModel = MoreViewModel(authService: ServiceFactory.createAuthenticationService(), biometricsService: ServiceFactory.createBiometricsService(), accountService: ServiceFactory.createAccountService())
    
    var shouldHideNavigationBar = true
    
    private var biometricsPasswordRetryCount = 0
    
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("More", comment: "")
        
        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)
        tableView.register(UINib(nibName: ToggleTableViewCell.className, bundle: nil), forCellReuseIdentifier: ToggleTableViewCell.className)
        
        if StormModeStatus.shared.isOn {
            view.backgroundColor = .stormModeBlack
        } else {
            view.backgroundColor = .primaryColor
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if shouldHideNavigationBar {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
        
        if AccountsStore.shared.accounts == nil {
            fetchAccounts()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        AppRating.present()
    }
    
    
    // MARK: - Actions
    
    @objc func toggleBiometrics(_ sender: UISwitch) {
        if sender.isOn {
            presentPasswordAlert(message: viewModel.getConfirmPasswordMessage(), toggle: sender)
            GoogleAnalytics.log(event: .touchIDEnable)
        } else {
            viewModel.disableBiometrics()
            GoogleAnalytics.log(event: .touchIDDisable)
        }
    }
    
    @IBAction func signOutPress(_ sender: Any) {
        presentAlert(title: NSLocalizedString("Sign Out", comment: ""),
                     message: NSLocalizedString("Are you sure you want to sign out?", comment: ""),
                     style: .alert,
                     actions: [UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil),
                               UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: logout)])
    }
    
    
    // MARK: - Helper
    
    private func fetchAccounts() {
        viewModel.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
    }
    
    private func presentPasswordAlert(message: String, toggle: UISwitch) {
        let indexPath = IndexPath(row: toggle.tag, section: 1)
        guard let cell = tableView.cellForRow(at: indexPath) as? ToggleTableViewCell else { return }
        
        let pwAlert = UIAlertController(title: NSLocalizedString("Confirm Password", comment: ""), message: message, preferredStyle: .alert)
        pwAlert.addTextField(configurationHandler: { [weak self] (textField) in
            guard let self = self else { return }
            textField.placeholder = NSLocalizedString("Password", comment: "")
            textField.isSecureTextEntry = true
            textField.rx.text.orEmpty.bind(to: self.viewModel.password).disposed(by: self.disposeBag)
        })
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) -> Void in
            toggle.setOn(false, animated: true)
            cell.toggleCheckImageView.isHidden = true
        }))
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) -> Void in
            LoadingView.show()
            self?.viewModel.validateCredentials(onSuccess: { [weak self] in
                guard let self = self else { return }
                LoadingView.hide()
                self.view.showToast(String(format: NSLocalizedString("%@ Enabled", comment: ""), self.viewModel.biometricsString()!))
                }, onError: { [weak self] (error) in
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.biometricsPasswordRetryCount += 1
                    if self.biometricsPasswordRetryCount < 3 {
                        self.presentPasswordAlert(message: NSLocalizedString("Error", comment: "") + ": \(error)", toggle: toggle)
                    } else {
                        self.biometricsPasswordRetryCount = 0
                        toggle.setOn(false, animated: true)
                        cell.toggleCheckImageView.isHidden = true
                    }
            })
        }))
        present(pwAlert, animated: true, completion: nil)
    }
    
    private func logout(action: UIAlertAction) {
        if Environment.shared.opco == .peco {
            // Sign out of Apple Watch App
            try? WatchSessionManager.shared.updateApplicationContext(applicationContext: ["clearAuthToken" : true])
        }
            
        let authService = ServiceFactory.createAuthenticationService()
        authService.logout()
        
        RxNotifications.shared.configureQuickActions.onNext(false)
        UserDefaults.standard.set(false, forKey: UserDefaultKeys.isKeepMeSignedInChecked)
        (UIApplication.shared.delegate as? AppDelegate)?.resetNavigation()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as ChangePasswordViewController:
            vc.delegate = self
        case let vc as PECOReleaseOfInfoViewController:
            vc.delegate = self
        case let vc as SetDefaultAccountViewController:
            vc.delegate = self
        default:
            break
        }
    }
    
}

extension MoreViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 5
        case 2:
            return 3
        default:
            return 0
        }
    }
    
    /// We Use row height to show/hide cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return 60
            default:
                return 60
            }
        case 1:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return viewModel.isDeviceBiometricCompatible() ? 60 : 0
            case 2:
                guard AccountsStore.shared.accounts != nil else { return 0 }
                return (Environment.shared.opco == .bge && AccountsStore.shared.accounts.count > 1) ? 60 : 0
            case 3:
                return Environment.shared.opco == .peco ? 60 : 0
            case 4:
                return Environment.shared.opco == .bge ? 60 : 0
            default:
                return 60
            }
        case 2:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return 60
            case 2:
                return 60
            default:
                return 60
            }
        default:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleTableViewCell.className) as? TitleTableViewCell else { return UITableViewCell() }
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_morealerts"), text: NSLocalizedString("My Alerts", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_moreupdates"), text: NSLocalizedString("News and Updates", comment: ""))
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_morepassword"), text: NSLocalizedString("Change Password", comment: ""))
            case 1:
                guard let toggleCell = tableView.dequeueReusableCell(withIdentifier: ToggleTableViewCell.className) as? ToggleTableViewCell else { return UITableViewCell() }
                
                toggleCell.configure(viewModel: viewModel, tag: indexPath.row)
                toggleCell.toggle.addTarget(self, action: #selector(toggleBiometrics), for: .valueChanged)
                return toggleCell
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_moredefault"), text: NSLocalizedString("Set Default Account", comment: ""))
            case 3:
                cell.configure(image: #imageLiteral(resourceName: "ic_morerelease"), text: NSLocalizedString("Release of Info", comment: ""))
            case 4:
                cell.configure(image: #imageLiteral(resourceName: "ic_morechoiceid"), text: NSLocalizedString("Choice ID", comment: ""))
            default:
                return UITableViewCell()
            }
        case 2:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: "ic_morecontact"), text: NSLocalizedString("Contact Us", comment: ""))
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_morevideo"), text: NSLocalizedString("Billing Videos", comment: ""))
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_moretos"), text: NSLocalizedString("Policies and Terms", comment: ""))
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
        
        cell.contentContainerView.rx.touchUpInside.asDriver().drive(onNext: { [weak self] _ in
            self?.tableViewDidSelectRow(at: indexPath)
        }).disposed(by: cell.disposeBag)
        
        cell.accessibilityElementsHidden = self.tableView(tableView, heightForRowAt: indexPath) == 0
        return cell
    }
    
    func tableViewDidSelectRow(at indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "alertsSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "updatesSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "changePasswordSegue", sender: nil)
            case 2:
                performSegue(withIdentifier: "defaultAccountSegue", sender: nil)
            case 3:
                performSegue(withIdentifier: "releaseOfInfoSegue", sender: nil)
            case 4:
                performSegue(withIdentifier: "choiceIdSegue", sender: nil)
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "contactUsSegue", sender: nil)
            case 1:
                UIApplication.shared.openUrlIfCan(viewModel.billingVideosUrl)
            case 2:
                performSegue(withIdentifier: "termsPoliciesSegue", sender: nil)
            default:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TitleTableViewHeaderView.className) as? TitleTableViewHeaderView else { return nil }
        
        switch section {
        case 0:
            headerView.configure(text: NSLocalizedString("Notifications", comment: ""))
        case 1:
            headerView.configure(text: NSLocalizedString("Account & Settings", comment: ""))
        case 2:
            headerView.configure(text: NSLocalizedString("Help & Support", comment: ""))
        default:
            break
        }
        
        if StormModeStatus.shared.isOn {
            headerView.colorView.backgroundColor = .stormModeBlack
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 21
    }
    
}


// MARK: - Change Password

extension MoreViewController: ChangePasswordViewControllerDelegate {
    
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: ChangePasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Password changed", comment: ""))
            GoogleAnalytics.log(event: .changePasswordComplete)
        })
    }
    
}


// MARK: - Change PECO Release

extension MoreViewController: PECOReleaseOfInfoViewControllerDelegate {
    
    func pecoReleaseOfInfoViewControllerDidUpdate(_ vc: PECOReleaseOfInfoViewController) {
        DispatchQueue.main.asyncAfter(deadline:  .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Release of information updated", comment: ""))
            GoogleAnalytics.log(event: .releaseInfoComplete)
        })
    }
    
}

extension MoreViewController: SetDefaultAccountViewControllerDelegate {
    
    func setDefaultAccountViewControllerDidFinish(_ setDefaultAccountViewController: SetDefaultAccountViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Default account changed", comment: ""))
            FirebaseUtility.logEvent(.more, parameters: [.init(parameterName: .action, value: .set_default_account_complete)])
        })
    }
}
