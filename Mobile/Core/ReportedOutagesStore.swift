//
//  ReportedOutagesStore.swift
//  Mobile
//
//  Created by Samuel Francis on 7/18/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import Foundation

class ReportedOutagesStore {
    
    private let reportTimeLimit: TimeInterval = 28_800 // 8 hours
    
    static let shared = ReportedOutagesStore()
    
    // Private init protects against another instance being accidentally instantiated
    private init() { }
    
    private var reportsCache = [String: ReportedOutageResult]()
    
    subscript(accountNumber: String) -> ReportedOutageResult? {
        get {
            if let report = reportsCache[accountNumber] {
                if report.reportedTime.addingTimeInterval(reportTimeLimit) > Date() {
                    return report
                } else {
                    removeReport(forAccountNumber: accountNumber)
                    return nil
                }
            } else if let reportDictionary = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.reportedOutagesDictionary),
                let reportNSDictionary = reportDictionary[accountNumber] as? NSDictionary,
                let report = ReportedOutageResult.from(reportNSDictionary) {
                
                if report.reportedTime.addingTimeInterval(reportTimeLimit) > Date() {
                    reportsCache[accountNumber] = report
                    return report
                } else {
                    removeReport(forAccountNumber: accountNumber)
                    return nil
                }
            } else {
                return nil
            }
        }
        set(newValue) {
            reportsCache[accountNumber] = newValue
            
            var reportDictionary = [String: Any]()
            if let existingDict = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.reportedOutagesDictionary) {
                reportDictionary = existingDict
            }
            
            if let report = newValue {
                reportDictionary[accountNumber] = [
                    "reportedTime": report.reportedTime.apiFormatString,
                    "etr": report.etr?.apiFormatString
                ]
                UserDefaults.standard.set(reportDictionary, forKey: UserDefaultKeys.reportedOutagesDictionary)
            } else {
                reportDictionary.removeValue(forKey: accountNumber)
                UserDefaults.standard.set(reportDictionary, forKey: UserDefaultKeys.reportedOutagesDictionary)
            }
            
        }
    }
    
    private func removeReport(forAccountNumber accountNumber: String) {
        reportsCache.removeValue(forKey: accountNumber)
        var reportDictionary = [String: Any]()
        if let existingDict = UserDefaults.standard.dictionary(forKey: UserDefaultKeys.reportedOutagesDictionary) {
            reportDictionary = existingDict
        }
        reportDictionary.removeValue(forKey: accountNumber)
        UserDefaults.standard.set(reportDictionary, forKey: UserDefaultKeys.reportedOutagesDictionary)
    }
    
}
