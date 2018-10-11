//
//  AppointmentDetailViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class AppointmentDetailViewController: UIViewController {
    
    var premiseNumber: String!
    var appointments: [Appointment]!
    
    private lazy var viewModel = AppointmentDetailViewModel(premiseNumber: premiseNumber,
                                                            appointments: appointments,
                                                            appointmentService: ServiceFactory.createAppointmentService())

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setColoredNavBar()
    }

}
