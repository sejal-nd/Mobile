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
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain an AlertPreferences
    ////    object upon success, or the error on failure.
    func register(token: String, firstLogin: Bool) -> Observable<Void>
    
    /// Fetch infomation about what push notifications the user is subscribed for
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain an AlertPreferences
    ////    object upon success, or the error on failure.
    func fetchAlertPreferences(accountNumber: String) -> Observable<AlertPreferences>
    
    /// Subscribes or unsubscribes from certain push notifications
    ///
    /// - Parameters:
    ///   - accountNumber: The account to set prefs for
    ///   - alertPreferences: An AlertPreferences object describing the alerts the user wants/does not want
    ///   - completion: the completion block to execute upon completion.
    func setAlertPreferences(accountNumber: String, alertPreferences: AlertPreferences) -> Observable<Void>
    
    /// Enrolls in the budget billing push notification preference. This is a separate call so that
    /// we can use it individually during budget billing enrollment without impacting other notification prefs
    ///
    /// - Parameters:
    ///   - accountNumber: The account to set prefs for
    ///   - completion: the completion block to execute upon completion.
    func enrollBudgetBillingNotification(accountNumber: String) -> Observable<Void>
    
    /// Fetch alerts language setting for ComEd account
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - completion: the completion block to execute upon completion.
    ///     The ServiceResult that is provided will contain either 'English' or 'Spanish'
    func fetchAlertLanguage(accountNumber: String) -> Observable<String>
    
    /// Set alerts language setting for ComEd account
    ///
    /// - Parameters:
    ///   - accountNumber: The account to fetch info for
    ///   - english: true for "English", false for "Spanish"
    ///   - completion: the completion block to execute upon completion.
    func setAlertLanguage(accountNumber: String, english: Bool) -> Observable<Void>
    
    /// Fetch opco specific updates to be displayed in the "Updates" section of the Alerts tab
    ///
    /// - Parameters:
    ///   - bannerOnly: If true, filter out any updates that don't belong on the home screen "banner"
    ///   - completion: the completion block to execute upon completion.
    func fetchOpcoUpdates(bannerOnly: Bool) -> Observable<[OpcoUpdate]>
}
