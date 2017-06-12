//
//  PECOReleaseOfInfoViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol PECOReleaseOfInfoViewControllerDelegate: class {
    func pecoReleaseOfInfoViewControllerDidUpdate(_ vc: PECOReleaseOfInfoViewController)
}

class PECOReleaseOfInfoViewController: UIViewController {
    
    weak var delegate: PECOReleaseOfInfoViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var accountInfoView: UIView!
    @IBOutlet weak var accountInfoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    let accountService = ServiceFactory.createAccountService()
    
    var selectedRowIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Release of Info", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        
        accountInfoView.backgroundColor = .softGray
        accountInfoLabel.textColor = .deepGray
        
        let currentAccount = AccountsStore.sharedInstance.currentAccount!
        accountInfoLabel.text = "ACCOUNT \(currentAccount.accountNumber)\n\(currentAccount.address ?? "")"
        
        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ReleaseOfInfoCell")
        tableView.estimatedRowHeight = 51
        tableView.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
        
        fetchCurrentSelection()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        accountInfoView.addBottomBorder(color: .accentGray, width: 1)
    }
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        LoadingView.show()
        accountService.updatePECOReleaseOfInfoPreference(account: AccountsStore.sharedInstance.currentAccount!, selectedIndex: selectedRowIndex)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                LoadingView.hide()
                self.delegate?.pecoReleaseOfInfoViewControllerDidUpdate(self)
                self.navigationController?.popViewController(animated: true)
            }, onError: { error in
                LoadingView.hide()
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })
            .addDisposableTo(disposeBag)
    }
    
    func fetchCurrentSelection() {
        accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount!)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { accountDetail in
                if let selectedRelease = accountDetail.releaseOfInformation {
                    if let releaseOfInfoInt = Int(selectedRelease) {
                        let indexPath = IndexPath(row: releaseOfInfoInt - 1, section: 0)
                        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                }
                self.loadingIndicator.isHidden = true
                self.tableView.isHidden = false
            }, onError: { error in
                print(error.localizedDescription)
            })
            .addDisposableTo(disposeBag)
    }
    
}

extension PECOReleaseOfInfoViewController: UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension PECOReleaseOfInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReleaseOfInfoCell", for: indexPath) as! RadioSelectionTableViewCell
        
        switch indexPath.row {
        case 0:
            cell.label.text = NSLocalizedString("Do Not Release My Information", comment: "")
        case 1:
            cell.label.text = NSLocalizedString("Release My Address and Energy\nUsage Profile", comment: "")
        case 2:
            cell.label.text = NSLocalizedString("Release My Address Only", comment: "")
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRowIndex = indexPath.row
    }
    
}
