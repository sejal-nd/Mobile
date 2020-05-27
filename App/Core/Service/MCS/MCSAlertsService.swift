//
//  MCSAlertsService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

struct MCSAlertsService: AlertsService {
    
    func register(token: String, firstLogin: Bool) -> Observable<Void> {
        let params: [String: Any] = [
            "notificationToken": token,
            "notificationProvider": "APNS",
            "mobileClient": [
                "id": Bundle.main.bundleIdentifier!,
                "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                "platform": "IOS"
            ],
            "setDefaults": firstLogin
        ]
        
        return MCSApi.shared.post(pathPrefix: .none, path: "notification/registration", params: params)
            .mapTo(())
    }

    func fetchAlertPreferences(accountNumber: String) -> Observable<AlertPreferences> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/alerts/preferences/push")
            .map { json in
                guard let responseObj = json as? NSDictionary,
                    let prefsDictArray = responseObj["alertPreferences"] as? [NSDictionary] else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                let alertPrefsArray = prefsDictArray.compactMap(AlertPreference.from)
                return AlertPreferences(alertPreferences: alertPrefsArray)
            }
    }
    
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences) -> Observable<Void> {
        let params = ["alertPreferences": alertPreferences.createAlertPreferencesJSONArray()]
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/alerts/preferences", params: params)
            .mapTo(())
    }
    
    func enrollBudgetBillingNotification(accountNumber: String) -> Observable<Void> {
        let params = ["alertPreferences": [["programName": "Budget Billing", "type": "push", "isActive": true]]]
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/alerts/preferences", params: params)
            .mapTo(())
    }
    
    func fetchAlertLanguage(accountNumber: String) -> Observable<String> {
        return MCSApi.shared.get(pathPrefix: .auth, path: "accounts/\(accountNumber)/alerts/accounts")
            .map { json in
                guard let responseObj = json as? NSDictionary, let language = responseObj["language"] as? String else {
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
                }
                
                return language
            }
    }
    
    func setAlertLanguage(accountNumber: String, english: Bool) -> Observable<Void> {
        let params = ["language": english ? "English" : "Spanish"]
        return MCSApi.shared.put(pathPrefix: .auth, path: "accounts/\(accountNumber)/alerts/accounts", params: params)
            .mapTo(())
    }
    
    func fetchOpcoUpdates(bannerOnly: Bool, stormOnly: Bool) -> Observable<[OpcoUpdate]> {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = Environment.shared.opcoUpdatesHost
        urlComponents.path = "/_api/web/lists/GetByTitle('GlobalAlert')/items"
        urlComponents.queryItems = [
            URLQueryItem(name: "$select", value: "Title,Message,Enable,CustomerType,Created,Modified"),
            URLQueryItem(name: "$orderby", value: "Modified desc")
        ]
        
        var filterString: String
        let path: String
        if bannerOnly {
            filterString = "(Enable eq 1) and (CustomerType eq 'Banner')"
            path = "Updates - Banner Only"
        } else if stormOnly {
            filterString = "(Enable eq 1) and (CustomerType eq 'Storm')"
            path = "Updates - Storm Only"
        } else {
            filterString = "(Enable eq 1) and ((CustomerType eq 'All')"
            ["Banner", "PeakRewards", "Peak Time Savings", "Smart Energy Rewards", "Storm"]
                .forEach {
                    filterString += "or (CustomerType eq '\($0)')"
            }
            filterString += ")"
            path = "Updates - All Updates"
        }
        
        let filter = URLQueryItem(name: "$filter", value: filterString)
        urlComponents.queryItems?.append(filter)
        
        guard let url = urlComponents.url else {
            return .error(ServiceError(serviceCode: ServiceErrorCode.localError.rawValue))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.get.rawValue
        request.setValue("application/json;odata=verbose", forHTTPHeaderField: "Accept")
        
        let requestId = ShortUUIDGenerator.getUUID(length: 8)
        APILog(MCSAlertsService.self, requestId: requestId, path: path, method: .get, logType: .request, message: nil)
        
        return URLSession.shared.rx.dataResponse(request: request, onCanceled: {
            APILog(MCSAlertsService.self, requestId: requestId, path: path, method: .get, logType: .canceled, message: nil)
        }).do(onError: { error in
            let serviceError = error as? ServiceError ?? ServiceError(cause: error)
            APILog(MCSAlertsService.self, requestId: requestId, path: path, method: .get, logType: .error, message: serviceError.errorDescription)
        }).map { data in
            guard let parsedData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                let dictData = parsedData as? [String: Any],
                let d = dictData["d"] as? [String: Any],
                let results = d["results"] as? [NSDictionary] else {
                    APILog(MCSAlertsService.self, requestId: requestId, path: path, method: .get, logType: .error, message: String(data: data, encoding: .utf8))
                    throw ServiceError(serviceCode: ServiceErrorCode.parsing.rawValue)
            }
            
            APILog(MCSAlertsService.self, requestId: requestId, path: path, method: .get, logType: .response, message: String(data: data, encoding: .utf8))
            return results.compactMap(OpcoUpdate.from)
        }
    }
    
}
