//
//  AdjustThermostatViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class AdjustThermostatViewController: UIViewController {
    
    let viewModel: AdjustThermostatViewModel
    
    init(viewModel: AdjustThermostatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

}
