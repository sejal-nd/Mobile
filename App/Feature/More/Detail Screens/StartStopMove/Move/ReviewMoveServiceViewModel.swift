//
//  ReviewMoveServiceViewModel.swift
//  EUMobile
//
//  Created by Mithlesh Kumar on 21/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
enum ChnageDateServiceType{
    case stop
    case start
}
class ReviewMoveServiceViewModel {
    
    func moveServiceRequest(moveFlowData: MoveServiceFlowData, onSuccess: @escaping (MoveServiceResponse) -> (), onFailure: @escaping (NetworkingError) -> ()) {
        
        MoveService.moveService(moveFlowData: moveFlowData) { [weak self] (result: Result<MoveServiceResponse, NetworkingError>) in
            switch result {
            case .success(let moveResponse):
                onSuccess(moveResponse)
            case .failure(let error):
                onFailure(error)
            }
        }
    }

    func isValidDate(_ date: Date, workDays: [WorkdaysResponse.WorkDay], accountDetails: AccountDetail)-> Bool {

        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        if !accountDetails.isAMIAccount {
            let firstDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 0, to: Date())!)
            let secondDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 1, to: Date())!)
            let thirdDay = DateFormatter.mmDdYyyyFormatter.string(from: Calendar.opCo.date(byAdding: .day, value: 2, to: Date())!)
            if calendarDate == firstDay || calendarDate == secondDay || calendarDate == thirdDay {
                return false
            }
        }
        return workDays.contains { $0.value == calendarDate}
    }
}
