//
//  SmartEnergyRewardsHistoryViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TotalSavingsViewController: UIViewController {
    
    @IBOutlet weak var totalSavingsValueLabel: UILabel!
    @IBOutlet weak var totalSavingsTitleLabel: UILabel!
    @IBOutlet weak var leftArrowImageView: UIImageView!
    @IBOutlet weak var rightArrowImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    
    var eventResults: [SERResult]! // Passed from HomeViewController/UsageViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Total Savings", comment: "")
        
        totalSavingsValueLabel.textColor = .primaryColor
        totalSavingsValueLabel.font = OpenSans.semibold.of(size: 30)
        totalSavingsValueLabel.text = totalSavingsValue.currencyString
        
        totalSavingsTitleLabel.textColor = .blackText
        totalSavingsTitleLabel.font = OpenSans.bold.of(textStyle: .subheadline)
        totalSavingsTitleLabel.text = NSLocalizedString("Total Bill Credit", comment: "")
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    private var totalSavingsValue: Double {
        var val = 0.0
        for result in eventResults {
            val += result.savingDollar
        }
        return val
    }

}

extension TotalSavingsViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventResults.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }
    
}

extension TotalSavingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TotalSavingsCell", for: indexPath) as! TotalSavingsTableViewCell
        
        cell.testLabel.text = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        
        return cell
    }
}
