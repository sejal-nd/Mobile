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
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var submitButton: PrimaryButton!
        
    var selectedRowIndex = 0
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Release of Information", comment: "")
        
        submitButton.rx.tap.asDriver().drive(onNext: { _ in
            self.onSubmitPress()
        }).disposed(by: disposeBag)
        
        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ReleaseOfInfoCell")
        tableView.estimatedRowHeight = 51
        tableView.isHidden = true
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
        errorLabel.isHidden = true
        
        FirebaseUtility.logEvent(.releaseOfInfoStart)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseUtility.logScreenView(.ReleaseOfInfoView(className: self.className))
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        fetchCurrentSelection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GoogleAnalytics.log(event: .releaseInfoOffer)
    }
    
    @objc func onSubmitPress() {
        var rowToIntMapping = selectedRowIndex // Address only is mapped correctly
        if selectedRowIndex == 0 {
            rowToIntMapping = 1
        } else if selectedRowIndex == 1 {
            rowToIntMapping = 0
        }
        
        LoadingView.show()
        
        FirebaseUtility.logEvent(.releaseOfInfoSubmit)
        GoogleAnalytics.log(event: .releaseInfoSubmit)
        
        AccountService.updatePECOReleaseOfInfoPreference(selectedIndex: rowToIntMapping) { [weak self] result in
            switch result {
            case .success:
                LoadingView.hide()
                guard let self = self else { return }
                FirebaseUtility.logEvent(.releaseOfInfoNetworkComplete)
                
                FirebaseUtility.logEvent(.more, parameters: [EventParameter(parameterName: .action, value: .release_of_info_complete)])
                
                self.delegate?.pecoReleaseOfInfoViewControllerDidUpdate(self)
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                LoadingView.hide()
                let alertVc = UIAlertController(title: error.title, message: error.description, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self?.present(alertVc, animated: true, completion: nil)
                
            }
        }
    }
    
    func fetchCurrentSelection() {
        let fetchReleaseOfInfo = { [weak self] in
            guard let self = self else { return }
            AccountService.fetchAccountDetails { [weak self] result in
                switch result {
                case .success(let accountDetail):
                    guard let self = self else { return }
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
                    UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
                case .failure:
                    guard let self = self else { return }
                    self.errorLabel.isHidden = false
                    self.loadingIndicator.isHidden = true
                    UIAccessibility.post(notification: .screenChanged, argument: self.view)
                }
                
            }
        }
        
        if AccountsStore.shared.currentIndex == nil {
            AccountService.fetchAccounts { [weak self] result in
                switch result {
                case .success:
                    guard let self = self else { return }
                    let currentAccount = AccountsStore.shared.currentAccount
                    self.accountInfoBar.configure(accountNumberText: currentAccount.accountNumber, addressText: currentAccount.address)
                    fetchReleaseOfInfo()
                case .failure:
                    guard let self = self else { return }
                    self.errorLabel.isHidden = false
                    self.loadingIndicator.isHidden = true
                    
                }
            }
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
        return UITableView.automaticDimension
    }
}

extension PECOReleaseOfInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReleaseOfInfoCell", for: indexPath) as! RadioSelectionTableViewCell
        
        switch indexPath.row {
        case 0:
            cell.label.text = NSLocalizedString("Do Not Release My Information", comment: "")
        case 1:
            cell.label.text = NSLocalizedString("Release My Address and Energy Usage Profile", comment: "")
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
