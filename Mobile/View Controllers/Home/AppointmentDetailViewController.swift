//
//  AppointmentDetailViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class AppointmentDetailViewController: UIViewController, IndicatorInfoProvider {
    
    let appointment: Appointment
    
    init(appointment: Appointment) {
        self.appointment = appointment
        super.init(nibName: AppointmentDetailViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: appointment.startTime.monthDayOrdinalString,
                             accessibilityLabel: appointment.startTime.monthDayOrdinalString,
                             image: nil,
                             highlightedImage: nil,
                             userInfo: nil)
    }
    
    
}
