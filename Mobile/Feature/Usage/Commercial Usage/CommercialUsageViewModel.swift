//
//  CommercialUsageViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 5/3/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

fileprivate let jsTimeoutInterval: TimeInterval = 15 // 15 seconds

class CommercialUsageViewModel {
    
    let accountDetail: Observable<AccountDetail>
    let ssoData: Observable<SSOData>
    let errorTrigger: PublishSubject<Error>
    let tabs = BehaviorRelay(value: Tab.allCases)
    let selectedIndex = BehaviorRelay(value: 0)
    private let readyToLoadWidget = PublishSubject<Void>()
    
    var jsTimeout: Timer?
    
    let disposeBag = DisposeBag()
    
    init(accountDetail: Observable<AccountDetail>,
         ssoData: Observable<SSOData>,
         errorTrigger: PublishSubject<Error>) {
        self.accountDetail = accountDetail
        self.ssoData = ssoData
        self.errorTrigger = errorTrigger
        
        accountDetail
            .map { accountDetail -> [Tab] in
                if !accountDetail.isAMIAccount || accountDetail.isFinaled ||
                    accountDetail.isActiveSeverance || accountDetail.serviceType?.uppercased() == "GAS" {
                    return Tab.allCases.filter { $0 != .operatingSchedule }
                } else {
                    return Tab.allCases
                }
            }
            .bind(to: tabs)
            .disposed(by: disposeBag)
    }
    
    private(set) lazy var javascript: Driver<String> = ssoData.map { [weak self] ssoData in
        guard let self = self else { return "" }
        self.jsTimeout = Timer.scheduledTimer(withTimeInterval: jsTimeoutInterval, repeats: false, block: { _ in
            dLog("Did not observe expected redirect within \(jsTimeoutInterval) seconds")
            self.errorTrigger.onNext(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        })

        return String(format: jsString,
                      ssoData.samlResponse,
                      ssoData.relayState.absoluteString,
                      ssoData.ssoPostURL.absoluteString)
    }
    .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var htmlString: Driver<String> = Observable
        .combineLatest(readyToLoadWidget.asObservable(),
                       selectedIndex.asObservable().distinctUntilChanged())
        .withLatestFrom(ssoData.map(\.username).unwrap()) { ($0.0, $0.1, $1) }
        .map { [weak self] _, selectedIndex, username in
            guard let self = self else { return "" }
            return html(forTab: self.tabs.value[selectedIndex], username: username)
        }
        .asDriver(onErrorDriveWith: .empty())
    
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

fileprivate let isProd = Environment.shared.environmentName == .prod ||
    Environment.shared.environmentName == .prodbeta

fileprivate var embedJsUrl: String {
    let opcoStr = Environment.shared.opco.displayString.lowercased()
    let strFormat = isProd ? "https://%@-sso.firstfuel.com/assets/widgets/v1/embed.js" :
        "https://%@-sso.firstfuelsoftware.net/assets/ff/pdf/widgets/v1/embed.js"
    return String(format: strFormat, opcoStr)
}

fileprivate var providerUrl: String {
    let opcoStr = Environment.shared.opco.displayString.lowercased()
    let strFormat = isProd ? "https://%@-sso.firstfuel.com" :
        "https://%@-sso.firstfuelsoftware.net"
    return String(format: strFormat, opcoStr)
}

fileprivate var logLevel: String {
    return isProd ? "INFO" : "DEBUG"
}

fileprivate func html(forTab tab: CommercialUsageViewModel.Tab, username: String) -> String {
    let url = Bundle.main.url(forResource: "FirstFuelWidget", withExtension: "html")!
    return try! String(contentsOf: url)
        .replacingOccurrences(of: "[dataWidgetId]", with: tab.widgetId)
        .replacingOccurrences(of: "[loggedInUsername]", with: username)
        .replacingOccurrences(of: "[accountNumber]", with: AccountsStore.shared.currentAccount.accountNumber)
        .replacingOccurrences(of: "[embedJsSrc]", with: embedJsUrl)
        .replacingOccurrences(of: "[providerUrl]", with: providerUrl)
        .replacingOccurrences(of: "[logLevel]", with: logLevel)
}