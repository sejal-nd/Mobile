//
//  AssistanceProgramStore.swift
//  EUMobile
//
//  Created by Adarsh Maurya on 11/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

final class AssistanceProgramStore {
    static let shared = AssistanceProgramStore()
    
    var dueDateExtensionData: (Result<DueDateElibility, NetworkingError>)?
    var paymentArrangementData: (Result<PaymentArrangement, NetworkingError>)?
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
    }
    
    func clearStore() {
        dueDateExtensionData = nil
        paymentArrangementData = nil
    }
}
