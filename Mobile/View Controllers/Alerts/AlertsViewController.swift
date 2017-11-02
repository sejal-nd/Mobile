//
//  AlertsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

let testAlerts = [
    "Outage to area 1215 E Fort Ave analyzed. The probable cause is unknown. Estimated restoration time 8/22/17 at 9:00 PM",
    "Severe thunderstorms in 1215 E Fort Ave from 2:00 PM to 5:00 PM. Be prepared for possible outages.",
    "Payment for account ending in 1234. Amount of $150.50 is due on 7/22/17."
]

class AlertsViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var segmentedControl: AlertsSegmentedControl!
    
    @IBOutlet weak var alertsTableView: UITableView!
    @IBOutlet weak var preferencesButton: ButtonControl!
    @IBOutlet weak var preferencesButtonLabel: UILabel!
    
    
    @IBOutlet weak var updatesTableView: UITableView!
    
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let viewModel = AlertsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
        
        segmentedControl.setItems(leftLabel: NSLocalizedString("My Alerts", comment: ""),
                                  rightLabel: NSLocalizedString("Updates", comment: ""),
                                  initialSelectedIndex: 0)
        
        if Environment.sharedInstance.opco == .bge {
            accountPicker.isHidden = true
        }
        
        alertsTableView.separatorColor = .accentGray
        updatesTableView.backgroundColor = .softGray
        
        styleViews()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Dynamic sizing for the table header view
        if let headerView = alertsTableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            var headerFrame = headerView.frame
            
            // If we don't have this check, viewDidLayoutSubviews() will get called repeatedly, causing the app to hang.
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                alertsTableView.tableHeaderView = headerView
            }
        }
    }
    
    private func styleViews() {
        preferencesButtonLabel.textColor = .actionBlue
        preferencesButtonLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        preferencesButtonLabel.text = NSLocalizedString("Preferences", comment: "")
    }
    
    private func bindViewModel() {
        segmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).disposed(by: disposeBag)
        
        viewModel.isFetching.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.shouldShowAlertsTableView.not().drive(alertsTableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowUpdatesTableView.not().drive(updatesTableView.rx.isHidden).disposed(by: disposeBag)
    }
    
    @IBAction func onPreferencesButtonTap(_ sender: Any) {
        performSegue(withIdentifier: "preferencesSegue", sender: self)
    }
    

}

extension AlertsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == alertsTableView {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == alertsTableView {
            return testAlerts.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == alertsTableView {
            var cell = tableView.dequeueReusableCell(withIdentifier: "AlertCell")
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: "AlertCell")
            }
            
            cell!.textLabel?.numberOfLines = 0
            cell!.detailTextLabel?.numberOfLines = 0
            
            cell!.textLabel?.textColor = .deepGray
            cell!.textLabel?.font = SystemFont.regular.of(textStyle: .headline)
            cell!.textLabel?.text = testAlerts[indexPath.row]
            
            return cell!
        } else {
            return UITableViewCell()
        }
    }
}

extension AlertsViewController: UITableViewDelegate {
    
}
