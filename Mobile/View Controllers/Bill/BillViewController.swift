//
//  BillViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BillViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountScroller: AccountScroller!
    @IBOutlet weak var accountScrollerActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var paperlessButtonView: UIView!
    @IBOutlet weak var budgetButtonView: UIView!
    
    let viewModel = BillViewModel(accountService: ServiceFactory.createAccountService())

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Bill", comment: "")
        
        accountScroller.delegate = self
        accountScroller.isHidden = true
        
        accountScrollerActivityIndicator.color = .mediumPersianBlue
        
        paperlessButtonView.layer.cornerRadius = 2
        paperlessButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        paperlessButtonView.layer.shadowOpacity = 0.3
        paperlessButtonView.layer.shadowColor = UIColor.black.cgColor
        paperlessButtonView.layer.shadowRadius = 3
        paperlessButtonView.layer.masksToBounds = false
        paperlessButtonView.isHidden = true
        
        budgetButtonView.layer.cornerRadius = 2
        budgetButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        budgetButtonView.layer.shadowOpacity = 0.2
        budgetButtonView.layer.shadowColor = UIColor.black.cgColor
        budgetButtonView.layer.shadowRadius = 3
        budgetButtonView.layer.masksToBounds = false
        budgetButtonView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewModel.currentAccount == nil {
            getAccounts()
        }
    }
    
    func getAccounts() {
        accountScrollerActivityIndicator.isHidden = false
        viewModel.getAccounts(onSuccess: { accounts in
            self.accountScrollerActivityIndicator.isHidden = true
            self.accountScroller.setAccounts(accounts)
            self.accountScroller.isHidden = false
            self.paperlessButtonView.isHidden = false
            self.budgetButtonView.isHidden = false
        }, onError: { message in
            self.accountScrollerActivityIndicator.isHidden = true
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    @IBAction func onButtonTouchDown(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .whiteButtonHighlight
    }
    
    @IBAction func onButtonTouchCancel(_ sender: Any) {
        let button = sender as! UIButton
        button.superview?.backgroundColor = .white
    }

}

extension BillViewController: AccountScrollerDelegate {
    
    func accountScroller(_ accountScroller: AccountScroller, didChangeAccount account: Account) {
        viewModel.currentAccount = account
    }
    
}
