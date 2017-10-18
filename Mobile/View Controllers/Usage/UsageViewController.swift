//
//  UsageViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UsageViewController: UIViewController {
    
    let disposeBag = DisposeBag()

    @IBOutlet weak var accountPicker: AccountPicker!
    @IBOutlet weak var usageGraphPlaceholderButton: DisclosureButton!
    @IBOutlet weak var top5EnergyTipsButton: DisclosureButton!
    @IBOutlet weak var updateYourHomeProfileButton: DisclosureButton!
    @IBOutlet weak var takeMeToSavingsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accountPicker.loadAccounts()
        accountPicker.updateCurrentAccount()
        
        buttonTapSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        }
    }
    
    func buttonTapSetup() {
        Driver.merge(usageGraphPlaceholderButton.rx.tap.asDriver().mapTo("usageWebViewSegue"),
                     top5EnergyTipsButton.rx.tap.asDriver().mapTo("top5EnergyTipsSegue"),
                     updateYourHomeProfileButton.rx.tap.asDriver().mapTo("updateYourHomeProfileSegue"),
                     takeMeToSavingsButton.rx.tap.asDriver().mapTo("takeMeToSavingsSegue"))
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: $0, sender: nil)
            })
            .disposed(by: disposeBag)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        //case let usageVC as UsageWebViewController:
        case _ as UsageWebViewController:
            break
        case _ as Top5EnergyTipsViewController:
            break
        case _ as MyHomeProfileViewController:
            break
        case _ as TotalPeakTimeSavingsViewController:
            break
        default:
            break
        }
    }

}
