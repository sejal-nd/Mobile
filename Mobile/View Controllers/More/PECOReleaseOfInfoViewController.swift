//
//  PECOReleaseOfInfoViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

/* IMPORTANT - THEIR BACKEND MAPS THE CODES AS FOLLOWS (DIFFERENT FROM OUR DISPLAY
 01 = All Information
 02 = No Information
 03 = All Info Excluding Usage
*/

protocol PECOReleaseOfInfoViewControllerDelegate: class {
    func pecoReleaseOfInfoViewControllerDidUpdate(_ vc: PECOReleaseOfInfoViewController)
}

class PECOReleaseOfInfoViewController: UIViewController {
    
    weak var delegate: PECOReleaseOfInfoViewControllerDelegate?
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
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
    
    func onCancelPress() {
        navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        var rowToIntMapping = selectedRowIndex // Address only is mapped correctly
        if selectedRowIndex == 0 {
            rowToIntMapping = 1
        } else if selectedRowIndex == 1 {
            rowToIntMapping = 0
        }
        
        LoadingView.show()
        accountService.updatePECOReleaseOfInfoPreference(account: AccountsStore.sharedInstance.currentAccount!, selectedIndex: rowToIntMapping)
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
            .disposed(by: disposeBag)
    }
    
    func fetchCurrentSelection() {
        let fetchReleaseOfInfo = {
            self.accountService.fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount!)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { accountDetail in
                    if let selectedRelease = accountDetail.releaseOfInformation {
                        if let releaseOfInfoInt = Int(selectedRelease) {
                            var intToRowMapping = 2 // Address only is mapped correctly
                            if releaseOfInfoInt == 1 {
                                intToRowMapping = 1
                            } else if releaseOfInfoInt == 2 {
                                intToRowMapping = 0
                            }
                            let indexPath = IndexPath(row: intToRowMapping, section: 0)
                            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                        }
                    }
                    self.loadingIndicator.isHidden = true
                    self.tableView.isHidden = false
                }, onError: { error in
                    print(error.localizedDescription)
                })
                .disposed(by: self.disposeBag)
        }
        
        if AccountsStore.sharedInstance.currentAccount == nil {
            accountService.fetchAccounts()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    self.accountInfoBar.update()
                    fetchReleaseOfInfo()
                }, onError: { error in
                    print(error.localizedDescription)
                })
                .disposed(by: disposeBag)
        } else {
            fetchReleaseOfInfo()
        }
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
