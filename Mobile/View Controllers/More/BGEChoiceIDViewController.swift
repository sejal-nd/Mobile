//
//  BGEChoiceIDViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/2/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class BGEChoiceIDViewController: AccountPickerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Choice ID", comment: "")

        accountPicker.delegate = self
        accountPicker.parentViewController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }

    func loadChoiceIds() {
        print("load choice ids")
    }
    
}

extension BGEChoiceIDViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        loadChoiceIds()
    }
    
}
