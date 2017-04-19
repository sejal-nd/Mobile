//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Bill", comment: "")
    }

}

extension BillViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.row == 0 {
            performSegue(withIdentifier: "paperlessBillingSegue", sender: self)
        } else if indexPath.row == 1 {
            performSegue(withIdentifier: "budgetBillingSegue", sender: self)
        }
    }
    
}

extension BillViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        var label = ""
        if indexPath.row == 0 {
            label = NSLocalizedString("Paperless Billing", comment: "")
        } else if indexPath.row == 1 {
            label = NSLocalizedString("Budget Billing", comment: "")
        }
        cell.textLabel?.text = label
        
        return cell
    }
    
}
