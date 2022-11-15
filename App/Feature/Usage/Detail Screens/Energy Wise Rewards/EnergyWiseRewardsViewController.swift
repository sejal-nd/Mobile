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
    @IBOutlet private weak var footerView: StickyFooterView!
    
    var accountDetail: AccountDetail!
    
    private lazy var viewModel = EnergyWiseRewardsViewModel(accountDetail: self.accountDetail)
    
    // MARK: - View LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Adjust Thermostat", comment: "")
        styleViews()
        energyWiseRewardsInformationLabel.text = viewModel.energyWiseRewardsInformation
        adjustThermostatButton.rx.touchUpInside.asDriver()
                  .drive(onNext: { [weak self] in self?.onAdjustPress() })
                  .disposed(by: DisposeBag())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as iTronSmartThermostatViewController:
            vc.accountDetail = accountDetail
        default:
            break
        }
    }
    
    func onAdjustPress() {
        performSegue(withIdentifier: "iTronSmartThermostatSegue", sender: self)
    }
}


// MARK: - EnergyWiseRewardsViewController Private Methods
extension EnergyWiseRewardsViewController {
    
    /// This function customizes the UI Elements
    private func styleViews() {
         energyWiseRewardsInformationLabel.textColor = .neutralDark
         energyWiseRewardsInformationLabel.font = SystemFont.regular.of(textStyle: .body)
         energyWiseRewardsInformationLabel.setLineHeight(lineHeight: 24.0)
         footerView.isHidden = !viewModel.showAdjustThermostatCTA
    }
}
