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

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ChangePasswordViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let viewModel = SettingsViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService())
    
    let disposeBag = DisposeBag()
    
    var touchIdCell: TableViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "TableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        
        tableView.backgroundColor = .tableViewBackgroundColor
        tableView.contentInset = UIEdgeInsetsMake(30, 0, 30, 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.isDeviceTouchIDCompatible() {
            return 2
        }
        return 1
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
            cell.configureWith(label: "Change Password", carat: true)
        } else {
            cell.configureWith(label: "Touch ID", switchOn: viewModel.isTouchIDEnabled(), switchObserver: { isOn in
                self.switchObserver(cell: cell, isOn: isOn)
            })
            touchIdCell = cell
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.section == 0 {
            performSegue(withIdentifier: "changePasswordSegue", sender: self)
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
        let pwAlert = UIAlertController(title: "Confirm Password", message: message, preferredStyle: .alert)
        pwAlert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
            textField.rx.text.orEmpty.bindTo(self.viewModel.password).addDisposableTo(self.disposeBag)
        })
        pwAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            self.touchIdCell?.setSwitch(on: false)
        }))
        pwAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
            hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            hud.contentColor = .white
            self.viewModel.validateCredentials(onSuccess: {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.view.makeToast("Touch ID Enabled", duration: 3.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
            }, onError: { (error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.presentPasswordAlert(message: "Error: \(error)")
            })
        }))
        self.present(pwAlert, animated: true, completion: nil)
    }
    
    func didChangePassword(sender: ChangePasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.makeToast("Password successfully changed", duration: 3.0, position: CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height - 40))
        })
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination.isKind(of: ChangePasswordViewController.self) {
            let vc: ChangePasswordViewController = segue.destination as! ChangePasswordViewController
            vc.delegate = self
        }
    }

}
