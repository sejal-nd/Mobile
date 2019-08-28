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
        
        addCloseButton()
        
        title = NSLocalizedString("Select Device", comment: "")
        
        extendedLayoutIncludesOpaqueBars = true
        
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
        
        tableView.separatorStyle = .none

        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "SmartThermostatDeviceCell")
        tableView.estimatedRowHeight = 51
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let indexPath = IndexPath(row: viewModel.selectedDeviceIndex.value, section: 0)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "SmartThermostatDeviceCell", for: indexPath) as! RadioSelectionTableViewCell
        cell.label.text = devices[indexPath.row].name
        return cell
    }
}

extension SelectDeviceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedDeviceIndex.accept(indexPath.row)
        DispatchQueue.main.async { // Fixes occasional dismiss lag
            self.dismissModal()
        }
    }
}

