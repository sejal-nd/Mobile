//
//  DefaultAccountViewController.swift
//  Mobile
//
//  Created by Sam Francis on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DefaultAccountViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let viewModel = DefaultAccountViewModel(withAccounts: AccountsStore.sharedInstance.accounts, accountService: ServiceFactory.createAccountService())
    
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        let infoButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_question_white"), style: .plain, target: self, action: #selector(infoButtonPressed))
        navigationItem.rightBarButtonItem = infoButton
        infoButton.isAccessibilityElement = true
        infoButton.accessibilityLabel = "Tooltip"
        let nib = UINib(nibName: AdvancedAccountPickerTableViewCell.className, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: AdvancedAccountPickerTableViewCell.className)
        
        viewModel.shouldShowLoadingIndicator
            .drive(onNext: { [weak self] in
                self?.showLoadingView($0)
            })
            .disposed(by: bag)
        
        viewModel.accounts.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: bag)
        
        viewModel.changeDefaultAccountErrorMessage
            .drive(onNext: { [weak self] errorMessage in
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                              message: errorMessage,
                                              preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
                    Analytics().logScreenView(AnalyticsPageView.SetDefaultAccountChange.rawValue)
                })
                
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    func showLoadingView(_ show: Bool) {
        if show {
            LoadingView.show()
        } else {
            LoadingView.hide()
        }
    }
    
    func infoButtonPressed() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Default Account", comment: ""),
                                                image: #imageLiteral(resourceName: "bge_account_picker"),
                                                description: NSLocalizedString("Your default account will display automatically when you sign in. You can change your default account at any time.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    deinit {
        dLog()
    }

}

extension DefaultAccountViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.accounts.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AdvancedAccountPickerTableViewCell.className, for: indexPath) as! AdvancedAccountPickerTableViewCell
        cell.configure(withAccount: viewModel.accounts.value[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}

extension DefaultAccountViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        Observable<Account>.create { [weak self] observer in
            let alert = UIAlertController(title: NSLocalizedString("Change Default", comment: ""),
                                          message: NSLocalizedString("Are you sure you want to change your default account?", comment: ""),
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                Analytics().logScreenView(AnalyticsPageView.SetDefaultAccountCancel.rawValue)
                observer.onCompleted()
            })
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Change", comment: ""), style: .default) { [weak self] _ in
                Analytics().logScreenView(AnalyticsPageView.SetDefaultAccountChange.rawValue)
                if let `self` = self {
                    observer.onNext(self.viewModel.accounts.value[indexPath.row])
                }
                observer.onCompleted()
            })
            
            self?.present(alert, animated: true, completion: nil)
            
            return Disposables.create {
                alert.dismiss(animated: true, completion: nil)
            }
            }
            .bind(onNext: { [weak self] account in self?.viewModel.changeDefaultAccount.onNext(account) })
            .disposed(by: bag)
        
    }
    
}
