//
//  Top5EnergyTipsViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class Top5EnergyTipsViewController: DismissableFormSheetViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var energyTips = [EnergyTip]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .primaryColor
        titleLabel.textColor = .blackText
        
        tableView.register(UINib(nibName: EnergyTipTableViewCell.className, bundle: nil),
                           forCellReuseIdentifier: EnergyTipTableViewCell.className)
        tableView.dataSource = self
        tableView.estimatedRowHeight = 650
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
