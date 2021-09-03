//
//  StopServiceViewController.swift
//  EUMobile
//
//  Created by RAMAITHANI on 02/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class StopServiceViewController: UIViewController {

    @IBOutlet weak var currentServiceAddressLabel: UILabel!
    @IBOutlet weak var changeAccountButton: UIButton!
    @IBOutlet weak var serviceProviderStackView: UIStackView!
    @IBOutlet weak var stopDateButton: UIButton!
    @IBOutlet weak var stopDateSelectionView: UIView!
    @IBOutlet weak var billAddressSegmentControl: SegmentedControl!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        billAddressSegmentControl.items = [NSLocalizedString("Yes", comment: ""), NSLocalizedString("No", comment: "")]
        stopDateSelectionView.roundCorners(.allCorners, radius: 10.0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        continueButton.roundCorners(.allCorners, radius: 27.5, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
