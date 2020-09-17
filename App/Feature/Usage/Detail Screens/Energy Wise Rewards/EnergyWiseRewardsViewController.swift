//
//  EnergyWiseRewardsViewController.swift
//  BGE
//
//  Created by Majumdar, Amit on 17/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit

class EnergyWiseRewardsViewController: DismissableFormSheetViewController {

    var accountDetail: AccountDetail!
    
    // MARK: - View LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Energy Wise Rewards", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
