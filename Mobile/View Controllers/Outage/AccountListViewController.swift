//
//  AccountListViewController.swift
//  Mobile
//
//  Created by Wesley Weitzel on 4/24/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AccountListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var accounts = [Account]()
    var currentAccount: Account?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AccountListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? AccountTableViewCell {
            let cells = self.tableView.visibleCells as! Array<AccountTableViewCell>
            for cell in cells {
                if cell.accountNumber.text == currentAccount?.accountNumber {
                    cell.accountNumber.textColor = .black
                }
            }
            cell.accountNumber.textColor = .primaryColor
            for account in accounts {
                if account.accountNumber == cell.accountNumber.text {
                    currentAccount = account
                }
            }
        }
    }
    
}

extension AccountListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell", for: indexPath) as! AccountTableViewCell
        let account = accounts[indexPath.row]
        cell.accountNumber.text = account.accountNumber
        cell.addressLabel.text = account.address
        if account.accountType == .Commercial {
            cell.imageView?.image = #imageLiteral(resourceName: "ic_commercial")
        } else {
            cell.imageView?.image = #imageLiteral(resourceName: "ic_residential")
        }
        if account.accountNumber == self.currentAccount?.accountNumber {
            cell.accountNumber.textColor = UIColor.primaryColor
        }
        return cell
        
    }
    
}


