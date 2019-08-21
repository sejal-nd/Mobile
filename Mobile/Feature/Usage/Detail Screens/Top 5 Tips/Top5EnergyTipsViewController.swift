//
//  Top5EnergyTipsViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class Top5EnergyTipsViewController: DismissableFormSheetViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var xButton: UIButton!
    
    let disposeBag = DisposeBag()
    var accountDetail: AccountDetail!
    
    private lazy var viewModel = Top5EnergyTipsViewModel(usageService: ServiceFactory.createUsageService(useCache: false),
                                                         accountDetail: self.accountDetail)
    var energyTips = [EnergyTip]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let residentialAMIString = String(format: "%@%@", accountDetail.isResidential ? "Residential/" : "Commercial/", accountDetail.isAMIAccount ? "AMI" : "Non-AMI")
        GoogleAnalytics.log(event: .viewTopTips, dimensions: [.residentialAMI: residentialAMIString])
        
        tableView.backgroundColor = .primaryColor
        titleLabel.textColor = .blackText
        errorLabel.textColor = .blackText
        xButton.tintColor = .actionBlue
        
        tableView.register(UINib(nibName: EnergyTipTableViewCell.className, bundle: nil),
                           forCellReuseIdentifier: EnergyTipTableViewCell.className)
        tableView.dataSource = self
        tableView.estimatedRowHeight = 650
        
        // Header and footer for padding
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 16))
        header.backgroundColor = .clear
        tableView.tableHeaderView = header
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 22))
        footer.backgroundColor = .clear
        tableView.tableFooterView = footer
        
        loadingIndicator.isHidden = false
        errorLabel.isHidden = true
        tableView.isHidden = true
        viewModel.energyTips
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.energyTips = $0
                self.tableView.reloadData()
                self.loadingIndicator.isHidden = true
                self.errorLabel.isHidden = true
                self.tableView.isHidden = false
            }, onError: { [weak self] _ in
                self?.loadingIndicator.isHidden = true
                self?.errorLabel.isHidden = false
                self?.tableView.isHidden = true
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func xPressed(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

extension Top5EnergyTipsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return energyTips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EnergyTipTableViewCell.className, for: indexPath) as! EnergyTipTableViewCell
        cell.configure(with: energyTips[indexPath.row])
        return cell
    }
}
