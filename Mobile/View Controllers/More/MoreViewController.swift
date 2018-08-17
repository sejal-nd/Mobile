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
            signOutButton.titleLabel?.font = SystemFont.bold.of(textStyle: .title1)
            signOutButton.setTitleColor(.white, for: .normal)
        }
    }

    let viewModel = MoreViewModel(authService: ServiceFactory.createAuthenticationService(), biometricsService: ServiceFactory.createBiometricsService(), accountService: ServiceFactory.createAccountService())
    
    private var biometricsPasswordRetryCount = 0
    
    private let disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: TitleTableViewHeaderView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: TitleTableViewHeaderView.className)
        tableView.register(UINib(nibName: SeparatorTableViewFooterView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: SeparatorTableViewFooterView.className)
        tableView.register(UINib(nibName: TitleTableViewCell.className, bundle: nil), forCellReuseIdentifier: TitleTableViewCell.className)
        tableView.register(UINib(nibName: ToggleTableViewCell.className, bundle: nil), forCellReuseIdentifier: ToggleTableViewCell.className)
        
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
    
    @objc func toggleBiometrics(_ sender: UISwitch) {
        if sender.isOn {
            presentPasswordAlert(message: viewModel.getConfirmPasswordMessage(), toggle: sender)
            Analytics.log(event: .touchIDEnable)
        } else {
            viewModel.disableBiometrics()
            Analytics.log(event: .touchIDDisable)
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
        let pwAlert = UIAlertController(title: NSLocalizedString("Confirm Password", comment: ""), message: message, preferredStyle: .alert)
        pwAlert.addTextField(configurationHandler: { [weak self] (textField) in
            guard let `self` = self else { return }
            textField.placeholder = NSLocalizedString("Password", comment: "")
            textField.isSecureTextEntry = true
            textField.rx.text.orEmpty.bind(to: self.viewModel.password).disposed(by: self.disposeBag)
        })
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) -> Void in
            toggle.setOn(false, animated: true)
        }))
        pwAlert.addAction(UIAlertAction(title: NSLocalizedString("Enable", comment: ""), style: .default, handler: { [weak self] (action) -> Void in
            LoadingView.show()
            self?.viewModel.validateCredentials(onSuccess: { [weak self] in
                guard let `self` = self else { return }
                LoadingView.hide()
                self.view.showToast(String(format: NSLocalizedString("%@ Enabled", comment: ""), self.viewModel.biometricsString()!))
                }, onError: { [weak self] (error) in
                    LoadingView.hide()
                    guard let `self` = self else { return }
                    self.biometricsPasswordRetryCount += 1
                    if self.biometricsPasswordRetryCount < 3 {
                        self.presentPasswordAlert(message: NSLocalizedString("Error", comment: "") + ": \(error)", toggle: toggle)
                    } else {
                        self.biometricsPasswordRetryCount = 0
                        toggle.setOn(false, animated: true)
                    }
            })
        }))
        present(pwAlert, animated: true, completion: nil)
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
