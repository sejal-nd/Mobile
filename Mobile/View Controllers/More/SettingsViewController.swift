//
//  SettingsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import MBProgressHUD
import ToastSwiftFramework

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let viewModel = SettingsViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService())
    
    let disposeBag = DisposeBag()
    
    var touchIdCell: TableViewCell?
    var touchIdPasswordRetryCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Settings", comment: "")
        
        let nib = UINib(nibName: "TableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        
        tableView.backgroundColor = .whiteSmoke
        tableView.contentInset = UIEdgeInsetsMake(30, 0, 30, 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tabBarController?.tabBar.isHidden = true
        }
    }
    
    // MARK: - Touch ID Switch Handling
    
    func switchObserver(cell: TableViewCell, isOn: Bool) {
        if isOn {
            presentPasswordAlert(message: viewModel.getConfirmPasswordMessage())
        } else {
            self.viewModel.disableTouchID()
        }
    }
    
    func presentPasswordAlert(message: String) {
        let pwAlert = UIAlertController(title: NSLocalizedString("Confirm Password", comment: ""), message: message, preferredStyle: .alert)
        pwAlert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Password", comment: "")
            textField.isSecureTextEntry = true
            textField.rx.text.orEmpty.bindTo(self.viewModel.password).addDisposableTo(self.disposeBag)
        })
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) -> Void in
            self.touchIdCell?.setSwitch(on: false)
        }))
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) -> Void in
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
            hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            hud.contentColor = .white
            self.viewModel.validateCredentials(onSuccess: {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.view.makeToast(NSLocalizedString("Touch ID Enabled", comment: ""), duration: 3.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
            }, onError: { (error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                
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
        if segue.destination.isKind(of: ChangePasswordViewController.self) {
            let vc: ChangePasswordViewController = segue.destination as! ChangePasswordViewController
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
        if Environment.sharedInstance.opco == "BGE" {
            print("Default account")
        } else if Environment.sharedInstance.opco == "PECO" {
            print("Release of info")
        }
    }
    
}

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numSections = 1
        if viewModel.isDeviceTouchIDCompatible() {
            numSections += 1
        }
        if Environment.sharedInstance.opco == "BGE" || Environment.sharedInstance.opco == "PECO" {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        
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
    
    func configureOpcoCell(_ cell: TableViewCell) {
        if Environment.sharedInstance.opco == "BGE" {
            cell.configureWith(label: NSLocalizedString("Default Account", comment: ""), carat: true)
        } else if Environment.sharedInstance.opco == "PECO" {
            cell.configureWith(label: NSLocalizedString("Release of Information", comment: ""), carat: true)
        }
    }
    
}

extension SettingsViewController: ChangePasswordViewControllerDelegate {
    
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: ChangePasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            // iPad shows tab bar, iPhone does not
            let yPos = UIDevice.current.userInterfaceIdiom == .pad ? self.view.frame.size.height - 89 : self.view.frame.size.height - 40
            self.view.makeToast(NSLocalizedString("Password successfully changed", comment: ""), duration: 3.0, position: CGPoint(x: self.view.frame.size.width / 2, y: yPos))
        })
    }
    
}
