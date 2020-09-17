//
//  EnergyWiseRewardsViewController.swift
//  BGE
//
//  Created by Majumdar, Amit on 17/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class EnergyWiseRewardsViewController: DismissableFormSheetViewController {

    @IBOutlet private weak var logo: UIImageView!
    @IBOutlet private weak var energyWiseRewardsInformationLabel: UILabel!
    @IBOutlet private weak var adjustThermostatButton: PrimaryButton!
    
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

   
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
