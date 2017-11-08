//
//  SmartThermostatScheduleViewController.swift
//  Mobile
//
//  Created by Sam Francis on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class SmartThermostatScheduleViewController: UIViewController {
    
    let viewModel: SmartThermostatScheduleViewModel
    
    init(viewModel: SmartThermostatScheduleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        let localizedTitle = NSLocalizedString("%@ Schedule", comment: "")
        title = String(format: localizedTitle, viewModel.period.displayString)
    }
    
    override func loadView() {
        super.loadView()
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let coolTempSliderView = TemperatureSliderView(currentTemperature: viewModel.coolTemp,
                                                       minTemp: Temperature(value: Double(40), scale: .fahrenheit),
                                                       maxTemp: Temperature(value: Double(90), scale: .fahrenheit),
                                                       coolOrHeat: .cool).usingAutoLayout()
        
        let stackView = UIStackView(arrangedSubviews: [coolTempSliderView]).usingAutoLayout()
        stackView.isUserInteractionEnabled = true
        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar()
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
