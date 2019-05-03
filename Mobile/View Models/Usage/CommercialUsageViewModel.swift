//
//  CommercialUsageViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 5/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class CommercialUsageViewModel {
    let url: URL
    
    init(ssoData: SSOData) {
        self.url = ssoData.ssoPostURL
    }
    
    enum Tab: Int, CaseIterable {
        case billingHistory, usageTrends, weatherImpact, operatingSchedule
        
        var htmlString: String {
            switch self {
            case .billingHistory:
                return ""
            case .usageTrends:
                return ""
            case .weatherImpact:
                return ""
            case .operatingSchedule:
                return ""
            }
        }
    }
}
