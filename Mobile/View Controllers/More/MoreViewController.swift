//
//  MoreViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class MoreViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func onSignOutPress() {
        let confirmAlert = UIAlertController(title: NSLocalizedString("Sign Out", comment: ""), message: NSLocalizedString("Are you sure you want to sign out?", comment: ""), preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: logout))
        present(confirmAlert, animated: true, completion: nil)
    }
    
    func logout(action: UIAlertAction) {
        let authService = ServiceFactory.createAuthenticationService()
        authService.logout().subscribe(onNext: { (success) in
            let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let rootVC = loginStoryboard.instantiateInitialViewController()
            UIApplication.shared.keyWindow?.rootViewController = rootVC
        }, onError: { (error) in
            print("Logout Error: \(error)")
        }).addDisposableTo(disposeBag)
    }
    
}

extension MoreViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.row == 0 {
            performSegue(withIdentifier: "settingsSegue", sender: self)
        } else if indexPath.row == 2 {
            performSegue(withIdentifier: "termsPoliciesSegue", sender: self)
        } else if indexPath.row == 3 {
            onSignOutPress()
        }
    }
    
}

extension MoreViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        var label = ""
        if indexPath.row == 0 {
            label = NSLocalizedString("Settings", comment: "")
        } else if indexPath.row == 1 {
            label = NSLocalizedString("Contact Us", comment: "")
        } else if indexPath.row == 2 {
            label = NSLocalizedString("Terms & Policies", comment: "")
        } else if indexPath.row == 3 {
            label = NSLocalizedString("Sign Out", comment: "")
        }
        cell.textLabel?.text = label
        
        return cell
    }
    
}
