//
//  AlertsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertsViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var segmentedControl: AlertsSegmentedControl!
    
    @IBOutlet weak var alertsTableView: UITableView!
    @IBOutlet weak var updatesTableView: UITableView!
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    let viewModel = AlertsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .primaryColor
        
        segmentedControl.setItems(leftLabel: NSLocalizedString("My Alerts", comment: ""),
                                  rightLabel: String(format: NSLocalizedString("%@ Updates", comment: ""), Environment.sharedInstance.opco.displayString),
                                  initialSelectedIndex: 0)
        
        if Environment.sharedInstance.opco == .bge {
            accountPicker.isHidden = true
        }
        
        updatesTableView.backgroundColor = .softGray
        
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func bindViewModel() {
        segmentedControl.selectedIndex.asObservable().bind(to: viewModel.selectedSegmentIndex).disposed(by: disposeBag)
        
        viewModel.shouldShowAlertsTableView.not().drive(alertsTableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowUpdatesTableView.not().drive(updatesTableView.rx.isHidden).disposed(by: disposeBag)
    }

}
