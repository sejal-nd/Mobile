//
//  AlertPreferencesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class AlertPreferencesViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var accountInfoBar: AccountInfoBar!
    
    let viewModel = AlertPreferencesViewModel()
    
    @IBOutlet weak var outageTitleLabel: UILabel!
    @IBOutlet weak var outageDetailLabel: UILabel!
    @IBOutlet weak var outageSwitch: Switch!
    
    @IBOutlet weak var scheduledMaintView: UIView!
    @IBOutlet weak var scheduledMaintTitleLabel: UILabel!
    @IBOutlet weak var scheduledMaintDetailLabel: UILabel!
    @IBOutlet weak var scheduledMaintSwitch: Switch!
    
    @IBOutlet weak var severeWeatherTitleLabel: UILabel!
    @IBOutlet weak var severeWeatherDetailLabel: UILabel!
    @IBOutlet weak var severeWeatherSwitch: Switch!
    
    @IBOutlet weak var billReadyTitleLabel: UILabel!
    @IBOutlet weak var billReadyDetailLabel: UILabel!
    @IBOutlet weak var billReadySwitch: Switch!
    
    @IBOutlet weak var paymentDueTitleLabel: UILabel!
    @IBOutlet weak var paymentDueDetailLabel: UILabel!
    @IBOutlet weak var paymentDueSwitch: Switch!
    @IBOutlet weak var paymentDueRemindMeLabel: UILabel!
    @IBOutlet weak var paymentDueDaysBeforeButton: UIButton!
    
    @IBOutlet weak var budgetBillingView: UIView!
    @IBOutlet weak var budgetBillingTitleLabel: UILabel!
    @IBOutlet weak var budgetBillingSwitch: Switch!
    
    @IBOutlet weak var forYourInfoTitleLabel: UILabel!
    @IBOutlet weak var forYourInfoDetailLabel: UILabel!
    @IBOutlet weak var forYourInfoSwitch: Switch!
    
    // Prevents status bar color flash when pushed
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Alert Preferences", comment: "")
        
        if Environment.sharedInstance.opco == .bge {
            accountInfoBar.isHidden = true
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    


}
