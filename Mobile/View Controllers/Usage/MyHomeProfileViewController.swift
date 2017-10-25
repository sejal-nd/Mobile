//
//  MyHomeProfileViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/18/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MyHomeProfileViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var homeTypeInfoLabel: UILabel!
    @IBOutlet weak var homeTypeButton: DisclosureButton!
    
    @IBOutlet weak var heatingFuelInfoLabel: UILabel!
    @IBOutlet weak var heatingFuelButton: DisclosureButton!
    
    @IBOutlet weak var numberOfResidentsInfoLabel: UILabel!
    @IBOutlet weak var numberOfAdultsButton: DisclosureButton!
    @IBOutlet weak var numberOfChildrenButton: DisclosureButton!
    
    @IBOutlet weak var homeSizeInfoLabel: UILabel!
    @IBOutlet weak var homeSizeTextField: FloatLabelTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Save", comment: ""),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(savePressed))
        styleViews()
    }
    
    func styleViews() {
        headerLabel.numberOfLines = 0
        headerLabel.font = SystemFont.regular.of(textStyle: .headline)
        headerLabel.setLineHeight(lineHeight: 24)
        homeTypeInfoLabel.numberOfLines = 0
        homeTypeInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        heatingFuelInfoLabel.numberOfLines = 0
        heatingFuelInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        numberOfResidentsInfoLabel.numberOfLines = 0
        numberOfResidentsInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        homeSizeInfoLabel.numberOfLines = 0
        homeSizeInfoLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        homeSizeTextField.textField.placeholder = NSLocalizedString("Home Size (sq. ft)", comment: "")
        homeSizeTextField.textField.delegate = self
        homeSizeTextField.textField.returnKeyType = .done
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }

    @objc func savePressed() {
        dLog("Save Pressed")
    }
}

extension MyHomeProfileViewController: UITextFieldDelegate {
    
}
