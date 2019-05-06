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
    let tabs = Observable.just(Tab.allCases).share(replay: 1)
    let selectedIndex = Variable(0)
    let htmlString: Driver<String>
    private let readyToLoadWidget = PublishSubject<Void>()
    
    init(ssoData: SSOData) {
        self.url = ssoData.ssoPostURL
        htmlString = Observable
            .combineLatest(readyToLoadWidget.asObservable(),
                           selectedIndex.asObservable()
                            .distinctUntilChanged())
            { _, selectedIndex in
                html(for: Tab.allCases[selectedIndex])
            }
            .asDriver(onErrorDriveWith: .empty())
    }
    
    func didAuthenticate() {
        
    }
    
    enum Tab: CaseIterable {
        case billingHistory
        case usageTrends
        case weatherImpact
        case operatingSchedule
        
        var title: String {
            switch self {
            case .billingHistory:
                return NSLocalizedString("Billing History", comment: "")
            case .usageTrends:
                return NSLocalizedString("Usage Trends", comment: "")
            case .weatherImpact:
                return NSLocalizedString("Weather Impact", comment: "")
            case .operatingSchedule:
                return NSLocalizedString("Operating Schedule", comment: "")
            }
        }
        
        var widgetId: String {
            switch self {
            case .billingHistory:
                return "42a223c3-ebd4-4f6f-9f11-e7ddf0158494"
            case .usageTrends:
                return "bbbbde32-2e5a-4df2-afc0-3a46083c8f06"
            case .weatherImpact:
                return "e267c842-f179-4f56-adb6-6207cd3db257"
            case .operatingSchedule:
                return "cd68dbdd-e5cc-4ed9-8a0c-4ab5ef4ee084"
            }
        }
    }
}

// MARK: - Helper Functions

fileprivate func html(for tab: CommercialUsageViewModel.Tab) -> String {
    let url = Bundle.main.url(forResource: "FirstFuelWidget", withExtension: "html")!
    // TODO, string replace the correct "data-login" (User's ID/email), "data-widget-id" (which widget), and "data-energy-type" (GAS/ELECTRIC)
    return try! String(contentsOf: url)
        .replacingOccurrences(of: "fmdcqomdkocmqcoeiwci", with: tab.widgetId)
}
