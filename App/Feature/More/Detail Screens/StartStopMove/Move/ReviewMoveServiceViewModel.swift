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
    
    func isValidDate(_ date: Date, workDays: [WorkdaysResponse.WorkDay])-> Bool {
        
        let calendarDate = DateFormatter.mmDdYyyyFormatter.string(from: date)
        return workDays.contains { $0.value == calendarDate }
    }
}
