//
//  OutageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 3/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class OutageViewController: UIViewController, AccountScrollerDelegate {
    
    @IBOutlet weak var accountScroller: AccountScroller!
    
    var testAccounts = [
        Account(accountType: .Residential, accountNumber: "1234567890", address: "1215 E Fort Ave"),
        Account(accountType: .Commercial, accountNumber: "4108675309", address: "15 Main Street"),
        Account(accountType: .Residential, accountNumber: "7491837101", address: "7 Lough Mask Court")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false // Needed for AccountScroller
        
        accountScroller.delegate = self
        accountScroller.setAccounts(accounts: testAccounts)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func accountScrollerDidChangeAccount(accountScroller: AccountScroller, account: Account) {
        print("Selected account: \(account.accountNumber)")
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
