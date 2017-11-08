//
//  SmartThermostatScheduleViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartThermostatScheduleViewModel {
    private let device: SmartThermostatDevice
    let period: SmartThermostatPeriod
    let periodInfo: SmartThermostatPeriodInfo
    
    let coolTemp: BehaviorSubject<Temperature>
    let heatTemp: BehaviorSubject<Temperature>
    
    init(device: SmartThermostatDevice, period: SmartThermostatPeriod, periodInfo: SmartThermostatPeriodInfo) {
        self.device = device
        self.period = period
        self.periodInfo = periodInfo
        
        self.coolTemp = BehaviorSubject(value: periodInfo.coolTemp)
        self.heatTemp = BehaviorSubject(value: periodInfo.heatTemp)
    }
}
