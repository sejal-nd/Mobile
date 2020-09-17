//
//  EnergyWiseRewardsViewController.swift
//  Mobile
//
//  Created by Majumdar, Amit on 17/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class EnergyWiseRewardsViewController: DismissableFormSheetViewController {

    @IBOutlet private weak var logo: UIImageView!
    @IBOutlet private weak var energyWiseRewardsInformationLabel: UILabel!
    @IBOutlet private weak var adjustThermostatButton: PrimaryButton!
    
    var accountDetail: AccountDetail!
    
    private lazy var viewModel = EnergyWiseRewardsViewModel(accountDetail: self.accountDetail)
    
    // MARK: - View LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Energy Wise Rewards", comment: "")
        styleViews()
        energyWiseRewardsInformationLabel.text = viewModel.energyWiseRewardsInformation
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}


// MARK: - EnergyWiseRewardsViewController Private Methods
extension EnergyWiseRewardsViewController {
    
    /// This function customizes the UI Elements
    private func styleViews() {
         energyWiseRewardsInformationLabel.textColor = .deepGray
         energyWiseRewardsInformationLabel.font = SystemFont.regular.of(textStyle: .body)
         energyWiseRewardsInformationLabel.setLineHeight(lineHeight: 24.0)
    }
}
