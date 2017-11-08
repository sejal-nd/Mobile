//
//  SelectDeviceViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class SelectDeviceViewController: UIViewController {
    
    let tableView = UITableView().usingAutoLayout()
    
    let viewModel: PeakRewardsViewModel
    let devices: [SmartThermostatDevice]

    init(viewModel: PeakRewardsViewModel, devices: [SmartThermostatDevice]) {
        self.viewModel = viewModel
        self.devices = devices
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        super.loadView()
        
        title = NSLocalizedString("Select Device", comment: "")
        
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SelectDeviceViewController.className)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
}

extension SelectDeviceViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SmartThermostatDeviceCell(style: .default, reuseIdentifier: SmartThermostatDeviceCell.className)
        let isChecked = viewModel.selectedDeviceIndex.asDriver()
            .map { indexPath.row == $0 }
        cell.configure(withDevice: devices[indexPath.row], isChecked: isChecked)
        return cell
    }
}

extension SelectDeviceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedDeviceIndex.value = indexPath.row
    }
}

