//
//  SetDefaultAccountViewController.swift
//  Mobile
//
//  Created by Sam Francis on 7/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol SetDefaultAccountViewControllerDelegate: class {
    func setDefaultAccountViewControllerDidFinish(_ setDefaultAccountViewController: SetDefaultAccountViewController)
}

class SetDefaultAccountViewController: UIViewController {
    
    weak var delegate: SetDefaultAccountViewControllerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: PrimaryButtonNew!
    
    let viewModel = SetDefaultAccountViewModel(accountService: ServiceFactory.createAccountService())
    
    let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let infoButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_tooltip.pdf"), style: .plain, target: self, action: #selector(infoButtonPressed))
        navigationItem.rightBarButtonItem = infoButton
        infoButton.isAccessibilityElement = true
        infoButton.accessibilityLabel = "Tooltip"
        
        let nib = UINib(nibName: SetDefaultAccountTableViewCell.className, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SetDefaultAccountTableViewCell.className)
        tableView.estimatedRowHeight = 56
        
        viewModel.saveButtonEnabled.drive(saveButton.rx.isEnabled).disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)

        if let index = AccountsStore.shared.accounts.firstIndex(where: { $0.isDefault }) {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
    }
    
    @objc func infoButtonPressed() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Default Account", comment: ""),
                                                image: #imageLiteral(resourceName: "bge_account_picker"),
                                                description: NSLocalizedString("Your default account will display automatically when you sign in. You can change your default account at any time.", comment: ""))
        navigationController?.present(infoModal, animated: true, completion: nil)
        FirebaseUtility.logEvent(.more, parameters: [.init(parameterName: .action, value: .default_account_help)])
    }
    
    @IBAction func onSavePress() {
        LoadingView.show()
        viewModel.setDefaultAccount(onSuccess: { [weak self] in
            guard let self = self else { return }
            LoadingView.hide()
            self.delegate?.setDefaultAccountViewControllerDidFinish(self)
            self.navigationController?.popViewController(animated: true)
        }, onError: { [weak self] errorMessage in
            LoadingView.hide()
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                          message: errorMessage,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        })
    }

}

extension SetDefaultAccountViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AccountsStore.shared.accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SetDefaultAccountTableViewCell.className, for: indexPath) as! SetDefaultAccountTableViewCell

        let account = AccountsStore.shared.accounts[indexPath.row]

        cell.configureWith(account: account)
        
        if account.address == nil || (account.serviceType ?? "").isEmpty {
            cell.contentView.alpha = 0.2
            cell.accessibilityTraits = .notEnabled
        } else {
            cell.contentView.alpha = 1
            cell.accessibilityTraits = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension SetDefaultAccountViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let account = AccountsStore.shared.accounts[indexPath.row]
        viewModel.selectedAccount.value = account
    }
    
}
