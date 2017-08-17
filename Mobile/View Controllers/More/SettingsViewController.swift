//
//  SettingsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import ToastSwiftFramework

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let viewModel = SettingsViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService(), accountService: ServiceFactory.createAccountService())
    
    let disposeBag = DisposeBag()
    
    var touchIdCell: SettingsTableViewCell?
    var touchIdPasswordRetryCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Settings", comment: "")
        
        view.backgroundColor = .softGray
        
        let nib = UINib(nibName: "SettingsTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        tableView.contentInset = UIEdgeInsetsMake(30, 0, 30, 0)
        tableView.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
        
        if AccountsStore.sharedInstance.accounts == nil {
            fetchAccounts()
        }
        
    }
    
    func fetchAccounts() {
        viewModel.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Touch ID Switch Handling
    
    func switchObserver(cell: SettingsTableViewCell, isOn: Bool) {
        if isOn {
            presentPasswordAlert(message: viewModel.getConfirmPasswordMessage())
            Analytics().logScreenView(AnalyticsPageView.TouchIDEnable.rawValue)
        } else {
            self.viewModel.disableTouchID()
            Analytics().logScreenView(AnalyticsPageView.TouchIDDisable.rawValue)
        }
    }
    
    func presentPasswordAlert(message: String) {
        let pwAlert = UIAlertController(title: NSLocalizedString("Confirm Password", comment: ""), message: message, preferredStyle: .alert)
        pwAlert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Password", comment: "")
            textField.isSecureTextEntry = true
            textField.rx.text.orEmpty.bind(to: self.viewModel.password).disposed(by: self.disposeBag)
        })
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) -> Void in
            self.touchIdCell?.setSwitch(on: false)
        }))
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { (action) -> Void in
            LoadingView.show()
            self.viewModel.validateCredentials(onSuccess: {
                LoadingView.hide()
                self.view.showToast(NSLocalizedString("Fingerprint Enabled", comment: ""))
            }, onError: { (error) in
                LoadingView.hide()
                self.touchIdPasswordRetryCount += 1
                if self.touchIdPasswordRetryCount < 3 {
                    self.presentPasswordAlert(message: NSLocalizedString("Error", comment: "") + ": \(error)")
                } else {
                    self.touchIdPasswordRetryCount = 0
                    self.touchIdCell?.setSwitch(on: false)
                }
            })
        }))
        self.present(pwAlert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ChangePasswordViewController {
            vc.delegate = self
        } else if let vc = segue.destination as? PECOReleaseOfInfoViewController {
            vc.delegate = self
        }
    }

}

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.section == 0 {
            performSegue(withIdentifier: "changePasswordSegue", sender: self)
        } else if indexPath.section == 1 {
            if !viewModel.isDeviceTouchIDCompatible() {
                handleOpcoCellPress()
            }
        } else if indexPath.section == 2 {
            handleOpcoCellPress()
        }
    }
    
    func handleOpcoCellPress() {
        if Environment.sharedInstance.opco == .bge {
            performSegue(withIdentifier: "defaultAccountSegue", sender: self)
        } else if Environment.sharedInstance.opco == .peco {
            performSegue(withIdentifier: "releaseOfInfoSegue", sender: self)
        }
    }
    
}

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numSections = 1
        if viewModel.isDeviceTouchIDCompatible() {
            numSections += 1
        }
        if Environment.sharedInstance.opco == .bge && AccountsStore.sharedInstance.accounts != nil && AccountsStore.sharedInstance.accounts.count > 1 {
            numSections += 1
        }
        if Environment.sharedInstance.opco == .peco {
            numSections += 1
        }
        
        return numSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SettingsTableViewCell
        
        if indexPath.section == 0 {
            cell.configureWith(label: NSLocalizedString("Change Password", comment: ""), carat: true)
        } else if indexPath.section == 1 {
            if viewModel.isDeviceTouchIDCompatible() {
                cell.configureWith(label: NSLocalizedString("Touch ID", comment: ""), switchOn: viewModel.isTouchIDEnabled(), switchObserver: { isOn in
                    self.switchObserver(cell: cell, isOn: isOn)
                })
                touchIdCell = cell
            } else {
                configureOpcoCell(cell)
            }
        } else if indexPath.section == 2 {
            configureOpcoCell(cell)
        }
        
        return cell
    }
    
    func configureOpcoCell(_ cell: SettingsTableViewCell) {
        if Environment.sharedInstance.opco == .bge {
            cell.configureWith(label: NSLocalizedString("Default Account", comment: ""), carat: true)
        } else if Environment.sharedInstance.opco == .peco {
            cell.configureWith(label: NSLocalizedString("Release of Info", comment: ""), carat: true)
        }
    }
    
}

extension SettingsViewController: ChangePasswordViewControllerDelegate {
    
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: ChangePasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Password changed", comment: ""))
        })
    }
    
}

extension SettingsViewController: PECOReleaseOfInfoViewControllerDelegate {
    
    func pecoReleaseOfInfoViewControllerDidUpdate(_ vc: PECOReleaseOfInfoViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Release of information updated", comment: ""))
            Analytics().logScreenView(AnalyticsPageView.ReleaseInfoComplete.rawValue)
        })
    }
    
}
