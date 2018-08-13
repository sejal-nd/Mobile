//
//  MoreViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import StoreKit
import ToastSwiftFramework

class MoreViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton! {
        didSet {
            signOutButton.setTitleColor(.white, for: .normal)
        }
    }

    let viewModel = MoreViewModel(authService: ServiceFactory.createAuthenticationService(), biometricsService: ServiceFactory.createBiometricsService(), accountService: ServiceFactory.createAccountService())
    
    let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "TitleTableViewHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "TitleTableViewHeaderView")
        tableView.register(UINib(nibName: "TitleTableViewCell", bundle: nil), forCellReuseIdentifier: "TitleTableViewCell")
        tableView.register(UINib(nibName: "ToggleTableViewCell", bundle: nil), forCellReuseIdentifier: "ToggleTableViewCell")
        
        view.backgroundColor = .primaryColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        if AccountsStore.shared.accounts == nil {
            fetchAccounts()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 10.3, *) , AppRating.shouldRequestRating() {
            SKStoreReviewController.requestReview()
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func signOutPress(_ sender: Any) {
        presentAlert(title: NSLocalizedString("Sign Out", comment: ""),
                     message: NSLocalizedString("Are you sure you want to sign out?", comment: ""),
                     style: .alert,
                     actions: [UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil),
                               UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: logout)])
    }
    
    
    // MARK: - Helper
    
    func fetchAccounts() {
        viewModel.fetchAccounts()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
    }
    
    private func logout(action: UIAlertAction) {
        let authService = ServiceFactory.createAuthenticationService()
        authService.logout().subscribe(onNext: { (success) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.isKeepMeSignedInChecked)
            appDelegate.configureQuickActions(isAuthenticated: false)
            appDelegate.resetNavigation()
        }, onError: { (error) in
            dLog("Logout Error: \(error)")
        }).disposed(by: disposeBag)
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
        default:
            break
        }
    }
    
}

// MARK: - Change Password

extension MoreViewController: ChangePasswordViewControllerDelegate {
    
    func changePasswordViewControllerDidChangePassword(_ changePasswordViewController: ChangePasswordViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Password changed", comment: ""))
            Analytics.log(event: .changePasswordComplete)
        })
    }
    
}


// MARK: - Change PECO Release

extension MoreViewController: PECOReleaseOfInfoViewControllerDelegate {
    
    func pecoReleaseOfInfoViewControllerDidUpdate(_ vc: PECOReleaseOfInfoViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Release of information updated", comment: ""))
            Analytics.log(event: .releaseInfoComplete)
        })
    }
    
}
