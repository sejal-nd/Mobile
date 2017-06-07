//
//  PECOReleaseOfInfoViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 6/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PECOReleaseOfInfoViewController: UIViewController {
    
    @IBOutlet weak var accountInfoView: UIView!
    @IBOutlet weak var accountInfoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Release of Information", comment: "")
        
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.rightBarButtonItem = submitButton
        
        accountInfoView.backgroundColor = .softGray
        accountInfoView.addBottomBorder(color: .accentGray, width: 1)
        accountInfoLabel.textColor = .deepGray

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

    }
    
    func onSubmitPress() {
        print("submit")
    }
}
