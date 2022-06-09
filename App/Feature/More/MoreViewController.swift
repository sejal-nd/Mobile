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
import AuthenticationServices

class MoreViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var superviewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var safeAreaTopConstraint: NSLayoutConstraint!


    @IBOutlet weak var signOutButton: UIButton! {
        didSet {
            signOutButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
            signOutButton.setTitleColor(.white, for: .normal)
        }
    }
    
    @IBOutlet private weak var versionLabel: UILabel! {
        didSet {
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                switch Configuration.shared.environmentName {
                case .release, .rc:
                    versionLabel.text = String(format: NSLocalizedString("Version %@", comment: ""), version)
                default:
                    versionLabel.text = String(format: NSLocalizedString("Version %@ - Tier %@", comment: ""), version, Configuration.shared.environmentName.rawValue)
                }
            } else {
                versionLabel.text = nil
            }
            
            versionLabel.font = OpenSans.regular.of(textStyle: .footnote)
            versionLabel.textColor = .white
        }
    }

    let viewModel = MoreViewModel()
    
    private var biometricsPasswordRetryCount = 0
    
    private let disposeBag = DisposeBag()

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("More", comment: "")
        
        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)
        tableView.register(UINib(nibName: ToggleTableViewCell.className, bundle: nil), forCellReuseIdentifier: ToggleTableViewCell.className)
        tableView.accessibilityLabel = "moreTableView"
        
        // Constraint stuff: In Storm Mode, we want the tableView top constrained to superview top
        // for smooth large title nav collapsing. Outside of Storm Mode there is no nav bar, so we
        // constrain to the safe area so that content does not overlap the status bar
        if StormModeStatus.shared.isOn {
            view.backgroundColor = .stormModeBlack
            view.removeConstraint(safeAreaTopConstraint)
            view.addConstraint(superviewTopConstraint)
        } else {
            view.backgroundColor = .primaryColor
            view.removeConstraint(superviewTopConstraint)
            view.addConstraint(safeAreaTopConstraint)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseUtility.logScreenView(.moreView(className: self.className))
        
        navigationController?.setNavigationBarHidden(!StormModeStatus.shared.isOn, animated: true)

        if AccountsStore.shared.accounts == nil {
            fetchAccounts()
        }
        
        // Edge case: if user navigates to More before game data loads, we want the
        // Energy Buddy row to appear the next time they come back
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppRating.present()
    }
    
    
    // MARK: - Actions
    
    @objc func toggleBiometrics(_ sender: UISwitch) {
        FirebaseUtility.logEvent(.biometricsToggle(parameters: [sender.isOn ? .true : .false]))
        
        FirebaseUtility.setUserProperty(.isBiometricsEnabled, value: sender.isOn.description)
        
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
        FirebaseUtility.logEvent(.more(parameters: [.sign_out]))
            
        AuthenticationService.logout(sendToLogin: false)
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
        case let vc as GameOptInOutViewController:
            vc.delegate = self
        default:
            break
        }
    }
}

extension MoreViewController: UITableViewDataSource, UITableViewDelegate {
    
    /// We need to insert a section on Moving for BGE before Help Section, hence the last 2 sections and their respective rows would need to be conditional.
    func numberOfSections(in tableView: UITableView) -> Int {
        return FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) ? 4 : 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return Configuration.shared.opco.isPHI ? 2 : 3
        case 1:
            return 7
        case 2:
            return 3
        case 3:
            return FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) ? 3 : 0
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
            case 2:
                return Configuration.shared.opco.isPHI ? .zero : 60
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
                return (FeatureFlagUtility.shared.bool(forKey: .hasDefaultAccount) && AccountsStore.shared.accounts.count > 1) ? 60 : 0
            case 3:
                return Configuration.shared.opco == .peco ? 60 : 0
            case 4:
                return Configuration.shared.opco == .bge ? 60 : 0
            case 5:
                let isGameUser = UserDefaults.standard.string(forKey: UserDefaultKeys.gameAccountNumber) != nil && FeatureFlagUtility.shared.bool(forKey: .isGamificationEnabled)
                return isGameUser ? 60 : 0
            case 6:
                return Configuration.shared.opco.isPHI ? 60 : .zero
            default:
                return 60
            }
        case 2:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM)
                {
                    return 60
                } else {
                    return Configuration.shared.opco.isPHI && viewModel.billingVideosUrl == nil ? .zero : 60
                }
            case 2:
                return 60
            default:
                return 60
            }
        case 3:
            switch indexPath.row {
            case 0:
                return 60
            case 1:
                return Configuration.shared.opco.isPHI && viewModel.billingVideosUrl == nil ? .zero : 60
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
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_moreappointments"), text: NSLocalizedString("Appointments", comment: ""))
            default:
                return UITableViewCell()
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.configure(image: #imageLiteral(resourceName: FeatureFlagUtility.shared.bool(forKey: .isPkceAuthentication) ? "ic_moremysecurity" : "ic_morepassword"), text: NSLocalizedString(FeatureFlagUtility.shared.bool(forKey: .isPkceAuthentication) ? "My Security" : "Change Password", comment: ""))
            case 1:
                guard let toggleCell = tableView.dequeueReusableCell(withIdentifier: ToggleTableViewCell.className) as? ToggleTableViewCell else { return UITableViewCell() }
                
                toggleCell.configure(viewModel: viewModel, tag: indexPath.row)
                toggleCell.toggle.addTarget(self, action: #selector(toggleBiometrics), for: .valueChanged)
                return toggleCell
            case 2:
                cell.configure(image: #imageLiteral(resourceName: "ic_moredefault"), text: NSLocalizedString("Set Default Account", comment: ""))
            case 3:
                cell.configure(image: #imageLiteral(resourceName: "ic_morerelease"), text: NSLocalizedString("Release of Information", comment: ""))
            case 4:
                cell.configure(image: #imageLiteral(resourceName: "ic_morechoiceid"), text: NSLocalizedString("Choice ID", comment: ""))
            case 5:
                cell.configure(image: #imageLiteral(resourceName: "ic_more_gamification"), text: NSLocalizedString("BGE's Play-n-Save Pilot", comment: ""))
            case 6:
                cell.configure(image: #imageLiteral(resourceName: "ic_edit_nickname"), text: NSLocalizedString("Edit Account Nickname", comment: ""))
                
            default:
                return UITableViewCell()
            }
        case 2:
            switch indexPath.row {
            case 0:
                if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                    cell.configure(image: #imageLiteral (resourceName: "ic_isummoveservice"), text: NSLocalizedString("Move Service", comment: ""))
                } else {
                    cell.configure(image: #imageLiteral(resourceName: "ic_morecontact"), text: NSLocalizedString("Contact Us", comment: ""))
                }
            case 1:
                if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                    cell.configure(image: #imageLiteral (resourceName: "ic_morestopservice"), text: NSLocalizedString("Stop Service", comment: ""))
                } else {
                    cell.configure(image: #imageLiteral(resourceName: "ic_morevideo"), text: NSLocalizedString("Billing Videos", comment: ""))
                }
            case 2:
                if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                    cell.configure(image: #imageLiteral (resourceName: "ic_morestartservice"), text: NSLocalizedString("Start Service", comment: ""))
                } else {
                    cell.configure(image: #imageLiteral(resourceName: "ic_moretos"), text: NSLocalizedString("Policies and Terms", comment: ""))
                }
            default:
                return UITableViewCell()
            }
            
        case 3:
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
        
        cell.accessibilityElementsHidden = self.tableView(tableView, heightForRowAt: indexPath) == 0
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "alertsSegue", sender: nil)
            case 1:
                performSegue(withIdentifier: "updatesSegue", sender: nil)
            case 2:
                performSegue(withIdentifier: "appointmentsSegue", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                GoogleAnalytics.log(event: .changePasswordOffer)
                FirebaseUtility.logScreenView(.mySecurityView(className: self.className))
                
                if FeatureFlagUtility.shared.bool(forKey: .isPkceAuthentication) {
                    PKCEAuthenticationService.default.presentMySecurityForm { result in
                        switch (result) {
                        case .success(let token):
                            FirebaseUtility.logEvent(.more(parameters: [.change_my_security_complete]))
                            if let json = TokenResponse.decodeToJson(token: token),
                               let editAction = json["profileEditActionTaken"] as? String {
                                
                                if editAction == "PasswordUpdate" {
                                    self.view.showToast("Password changed")
                                    GoogleAnalytics.log(event: .changePasswordComplete)
                                    FirebaseUtility.logEvent(.more(parameters: [.change_password_complete]))
                                } else {
                                    self.view.showToast("Two-Step Verification settings updated")
                                }
                            }
                        case .failure(let error):
                            let sessionError = ASWebAuthenticationSessionError.Code(rawValue: (error as NSError).code)
                            if sessionError != ASWebAuthenticationSessionError.canceledLogin {
                                self.view.showToast("Error updating security credentials.")
                            }
                        }
                    }
                } else {
                    performSegue(withIdentifier: "changePasswordSegue", sender: nil)
                }
            case 2:
                performSegue(withIdentifier: "defaultAccountSegue", sender: nil)
            case 3:
                performSegue(withIdentifier: "releaseOfInfoSegue", sender: nil)
            case 4:
                performSegue(withIdentifier: "choiceIdSegue", sender: nil)
            case 5:
                performSegue(withIdentifier: "energyBuddySegue", sender: nil)
            case 6:
                performSegue(withIdentifier: "editAccountNicknameSegue", sender: nil)
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                    if Configuration.shared.opco == .bge {
                        performSegue(withIdentifier: "moveServiceSegue", sender: nil)
                    } else {
                        UIApplication.shared.openUrlIfCan(viewModel.moveServiceWebURL)
                    }
                } else {
                    performSegue(withIdentifier: "contactUsSegue", sender: nil)
                }
            case 1:
                if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                    if Configuration.shared.opco == .bge {
                        performSegue(withIdentifier: "stopServiceSegue", sender: nil)
                    } else {
                        UIApplication.shared.openUrlIfCan(viewModel.stopServiceWebURL)
                    }
                } else {
                    FirebaseUtility.logEvent(.more(parameters: [.billing_videos]))
                    UIApplication.shared.openUrlIfCan(viewModel.billingVideosUrl)
                }
            case 2:
                if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                    /// Redirect to Start Service web experience for this Nov-21 release.
                    UIApplication.shared.openUrlIfCan(viewModel.startServiceWebURL)
                } else {
                    performSegue(withIdentifier: "termsPoliciesSegue", sender: nil)
                }
            default:
                break
            }
            
        case 3:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "contactUsSegue", sender: nil)
            case 1:
                FirebaseUtility.logEvent(.more(parameters: [.billing_videos]))
                
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
            if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                headerView.configure(text: NSLocalizedString("Moving", comment: ""))
            } else {
                headerView.configure(text: NSLocalizedString("Help & Support", comment: ""))
            }
        case 3:
            if FeatureFlagUtility.shared.bool(forKey: .hasAuthenticatedISUM) {
                headerView.configure(text: NSLocalizedString("Help & Support", comment: ""))
            }
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
    
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Password changed", comment: ""))
            //GoogleAnalytics.log(event: .changePasswordComplete)
           // FirebaseUtility.logEvent(.more(parameters: [.change_password_complete]))
           // print("======password changed===============")
            
        })
    }
    
}


// MARK: - Change PECO Release

extension MoreViewController: PECOReleaseOfInfoViewControllerDelegate {
    
    func pecoReleaseOfInfoViewControllerDidUpdate(_ vc: PECOReleaseOfInfoViewController) {
        DispatchQueue.main.asyncAfter(deadline:  .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Release of Information updated", comment: ""))
            GoogleAnalytics.log(event: .releaseInfoComplete)
        })
    }
    
}

// MARK: - Set Default Account

extension MoreViewController: SetDefaultAccountViewControllerDelegate {
    
    func setDefaultAccountViewControllerDidFinish(_ setDefaultAccountViewController: SetDefaultAccountViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Default account changed", comment: ""))
            FirebaseUtility.logEvent(.more(parameters: [.set_default_account_complete]))
        })
    }
}

// MARK: - Game Opt In/Out

extension MoreViewController: GameOptInOutViewControllerDelegate {
    
    func gameOptInOutViewController(_ gameOptInOutViewController: GameOptInOutViewController, didOptOut: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            let toastString = String.localizedStringWithFormat("The feature has been turned %@", didOptOut ? "off" : "on")
            self.view.showToast(toastString)
        })
    }
}
