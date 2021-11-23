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
    
    var moveFlowData: MoveServiceFlowData! = nil
    
    var isUnauth: Bool {
        return moveFlowData.unauthMoveData?.isUnauthMove ?? false
    }

    func moveServiceRequest(moveFlowData: MoveServiceFlowData, onSuccess: @escaping (MoveServiceResponse) -> (), onFailure: @escaping (NetworkingError) -> ()) {
        
        if isUnauth {
            moveServiceUnauthenticationRequest(moveFlowData: moveFlowData, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            moveServiceAuthenticationRequest(moveFlowData: moveFlowData, onSuccess: onSuccess, onFailure: onFailure)
        }
    }
    
    func moveServiceAuthenticationRequest(moveFlowData: MoveServiceFlowData, onSuccess: @escaping (MoveServiceResponse) -> (), onFailure: @escaping (NetworkingError) -> ()) {
        
        MoveService.moveService(moveFlowData: moveFlowData) {(result: Result<MoveServiceResponse, NetworkingError>) in
            switch result {
            case .success(let moveResponse):
                onSuccess(moveResponse)
            case .failure(let error):
                onFailure(error)
            }
        }
    }
    
    func moveServiceUnauthenticationRequest(moveFlowData: MoveServiceFlowData, onSuccess: @escaping (MoveServiceResponse) -> (), onFailure: @escaping (NetworkingError) -> ()) {
        
        MoveService.moveServiceAnon(moveFlowData: moveFlowData) {(result: Result<MoveServiceResponse, NetworkingError>) in
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
