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
    
    let minTime: Date
    let maxTime: Date
    
    init(device: SmartThermostatDevice, period: SmartThermostatPeriod, schedule: SmartThermostatDeviceSchedule) {
        self.device = device
        self.period = period
        self.periodInfo = schedule.info(for: period)
        
        self.coolTemp = BehaviorSubject(value: periodInfo.coolTemp)
        self.heatTemp = BehaviorSubject(value: periodInfo.heatTemp)
        
        var subtractSecondComponents = DateComponents()
        subtractSecondComponents.second = -1
        
        var addSecondComponents = DateComponents()
        addSecondComponents.second = 1
        
        switch period {
        case .wake:
            minTime = Calendar.opCo.startOfDay(for: periodInfo.startTime)
            maxTime = Calendar.opCo.date(byAdding: subtractSecondComponents, to: schedule.leaveInfo.startTime)!
        case .leave:
            minTime = Calendar.opCo.date(byAdding: addSecondComponents, to: schedule.wakeInfo.startTime)!
            maxTime = Calendar.opCo.date(byAdding: subtractSecondComponents, to: schedule.returnInfo.startTime)!
        case .return:
            minTime = Calendar.opCo.date(byAdding: addSecondComponents, to: schedule.leaveInfo.startTime)!
            maxTime = Calendar.opCo.date(byAdding: subtractSecondComponents, to: schedule.sleepInfo.startTime)!
        case .sleep:
            minTime = Calendar.opCo.date(byAdding: addSecondComponents, to: schedule.returnInfo.startTime)!
            maxTime = Calendar.opCo.endOfDay(for: periodInfo.startTime)
        }
    }
}
