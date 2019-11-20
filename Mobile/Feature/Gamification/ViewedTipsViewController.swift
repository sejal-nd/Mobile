//
//  ViewedTipsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/20/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class ViewedTipsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Viewed Tips", comment: "")

        emptyStateLabel.textColor = .middleGray
        emptyStateLabel.font = OpenSans.regular.of(textStyle: .headline)
        emptyStateLabel.text = NSLocalizedString("You haven't viewed any tips yet.", comment: "")
        
        tableView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
}
