//
//  NewOutageViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class NewOutageViewController: UIViewController {
    
    @IBOutlet weak var maintenanceModeContainerView: UIView!
    @IBOutlet weak var NoNetworkConnectionContainerView: UIView!
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var gasOnlyContainerView: UIView!
    @IBOutlet weak var notAvailableContainerView: UIView!
  
    // todo loading view, should be a container view similar to gas only.
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var outageStatusView: OutageStatusView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView! // may be special text view
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        outageStatusView.outageState = .powerStatus(false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
        tableView.sizeFooterToFit()
    }
    
    
    // MARK: - Helper
    
    
    
    
    // MARK: - Actions
    
}
