//
//  AlertsService.swift
//  Mobile
//
//  Created by Marc Shilling on 11/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol AlertsService {
    /// Register the device for push notifications
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - firstLogin: If true, will attempt to enroll the default preferences for this account
    func register(token: String, firstLogin: Bool) -> Observable<Void>
    
    /// Fetch infomation about what push notifications the user is subscribed for
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    func fetchAlertPreferences(accountNumber: String) -> Observable<AlertPreferences>
    
    /// Subscribes or unsubscribes from certain push notifications
    ///
    /// - Parameters:
    ///   - accountNumber: The account to set prefs for
    ///   - alertPreferences: An AlertPreferences object describing the alerts the user wants/does not want
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences) -> Observable<Void>
    
    /// Enrolls in the budget billing push notification preference. This is a separate call so that
    /// we can use it individually during budget billing enrollment without impacting other notification prefs
    ///
    /// - Parameters:
    ///   - accountNumber: The account to set prefs for
    func enrollBudgetBillingNotification(accountNumber: String) -> Observable<Void>
    
    /// Fetch alerts language setting for ComEd account (will contain either 'English' or 'Spanish')
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    func fetchAlertLanguage(accountNumber: String) -> Observable<String>
    
    /// Set alerts language setting for ComEd account
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - english: true for "English", false for "Spanish"
    func setAlertLanguage(accountNumber: String, english: Bool) -> Observable<Void>
    
    /// Fetch opco specific updates to be displayed in the "Updates" section of the Alerts tab
    ///
    /// - Parameters:
    ///   - bannerOnly: If true, filter out any updates that don't belong on the home screen "banner"
    ///   - stormOnly: If true, filter out any updates unrelated to storm mode
    func fetchOpcoUpdates(bannerOnly: Bool, stormOnly: Bool) -> Observable<[OpcoUpdate]>
}

extension AlertsService {
    func fetchOpcoUpdates(bannerOnly: Bool = false, stormOnly: Bool = false) -> Observable<[OpcoUpdate]> {
        return fetchOpcoUpdates(bannerOnly: bannerOnly, stormOnly: stormOnly)
    }
}
