//
//  AppRating.swift
//  Mobile
//
//  Created by Kenny Roethel on 9/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import StoreKit

/// Utility to keep track of events used to
/// track when to prompt the user to rate the app.
struct AppRating {
   
    static let EventThreshold = 2
    
    /// Log an event that should contribute to event count
    /// that is used to determine when to start asking the
    /// user to rate the app.
    static func logRatingEvent() {
        let defaults = UserDefaults.standard
        let value = defaults.integer(forKey: UserDefaultKeys.appRatingEventCount)
        defaults.set(value+1, forKey: UserDefaultKeys.appRatingEventCount)
    }
    
    /// Reset the event count, after calling this
    /// shouldRequestRating will return false until
    /// the event threshold has been reached again.
    static func clearEventCount() {
        let defaults = UserDefaults.standard
        defaults.set(0, forKey: UserDefaultKeys.appRatingEventCount)
    }
    
    /// Check if the event threshold has been met
    /// and the user should be prompted to rate the app.
    ///
    /// - Returns: true if the threshold was met and the
    ///     user should be prompted to rate the app.
    static func shouldRequestRating() -> Bool {
        let isDev = Configuration.shared.environmentName != .release &&
            Configuration.shared.environmentName != .rc &&
            Configuration.shared.environmentName != .beta
        
        let value = UserDefaults.standard.integer(forKey: UserDefaultKeys.appRatingEventCount)
        
        return value >= EventThreshold && !isDev
    }
    
    /// Presents the Apple App Store Rating Prompt, its presentation is not guarenteed
    static func present() {
        let env = Configuration.shared.environmentName
        if AppRating.shouldRequestRating() && (env == .release || env == .rc) {
            SKStoreReviewController.requestReview()
        }
    }
}
