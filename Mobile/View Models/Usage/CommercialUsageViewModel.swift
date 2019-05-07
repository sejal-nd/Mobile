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
    let javascript: Driver<String>
    let tabs = Observable.just(Tab.allCases).share(replay: 1)
    let selectedIndex = BehaviorRelay(value: 0)
    let htmlString: Driver<String>
    private let readyToLoadWidget = PublishSubject<Void>()
    
    init(ssoData: Observable<SSOData>) {
        javascript = ssoData.map { ssoData in
            String(format: jsString,
                   ssoData.samlResponse,
                   ssoData.relayState.absoluteString,
                   ssoData.ssoPostURL.absoluteString)
            }
            .asDriver(onErrorDriveWith: .empty())
        
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
        readyToLoadWidget.onNext(())
    }
    
    enum Tab: CaseIterable {
        case usageTrends
        case billingHistory
        case weatherImpact
        case operatingSchedule
        
        var title: String {
            switch self {
            case .usageTrends:
                return NSLocalizedString("Usage Trends", comment: "")
            case .billingHistory:
                return NSLocalizedString("Billing History", comment: "")
            case .weatherImpact:
                return NSLocalizedString("Weather Impact", comment: "")
            case .operatingSchedule:
                return NSLocalizedString("Operating Schedule", comment: "")
            }
        }
        
        var widgetId: String {
            switch self {
            case .usageTrends:
                return "87538db3-ddfa-4476-b0e3-c6d7e580e5d2"
            case .billingHistory:
                return "42a223c3-ebd4-4f6f-9f11-e7ddf0158494"
            case .weatherImpact:
                return "e267c842-f179-4f56-adb6-6207cd3db257"
            case .operatingSchedule:
                return "cd68dbdd-e5cc-4ed9-8a0c-4ab5ef4ee084"
            }
        }
    }
}

// MARK: - Helper

fileprivate let jsString = "var data={SAMLResponse:'%@',RelayState:'%@'};var form=document.createElement('form');form.setAttribute('method','post'),form.setAttribute('action','%@');for(var key in data){if(data.hasOwnProperty(key)){var hiddenField=document.createElement('input');hiddenField.setAttribute('type', 'hidden');hiddenField.setAttribute('name', key);hiddenField.setAttribute('value', data[key]);form.appendChild(hiddenField);}}document.body.appendChild(form);form.submit();"

fileprivate func html(for tab: CommercialUsageViewModel.Tab) -> String {
    let url = Bundle.main.url(forResource: "FirstFuelWidget", withExtension: "html")!
    // TODO, string replace the correct "data-login" (User's ID/email), "data-widget-id" (which widget), and "data-energy-type" (GAS/ELECTRIC)
    
    let loggedInUsername = UserDefaults.standard.string(forKey: UserDefaultKeys.loggedInUsername)!
    return try! String(contentsOf: url)
        .replacingOccurrences(of: "dataWidgetId", with: tab.widgetId)
        .replacingOccurrences(of: "loggedInUsername", with: loggedInUsername)
}
