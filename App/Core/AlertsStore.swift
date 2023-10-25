//
//  AlertsStore.swift
//  Mobile
//
//  Created by Joey Erlandson on 5/10/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import Foundation

// Todo: It may be possible to save each and every notification to user defaults regadless of whether a user presses on it or not.
// Reference: https://stackoverflow.com/questions/64771872/ios-swift-push-notification-save-all-remote-notifications-in-a-database-also
final class PushNotificationStore {
    static let shared = PushNotificationStore()

    // A list of accounts with their associated notifications
    var accounts = [AccountNotifications]()

    private let defaults = UserDefaults.standard
    private static let defaultsKey = "savedNotificationContainers"

    private init () {
        migrateNotificationStore()
        loadNotifications()
    }
    
    // Migrate old notifications storage to new method.  This is a one time per device operation.
    // todo: THIS CODE CAN BE REMOVED AFTER THE CIS RELEASE.
    private func migrateNotificationStore() {
        guard !defaults.bool(forKey: "hasMigratedAlertStore") else { return }
        
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        let filePath = (url!.appendingPathComponent("AlertsStore").path)
        
        let alertURL = URL(fileURLWithPath: filePath)
        if let data = try? Data(contentsOf: alertURL),
            let storedAlerts = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: [OldPushNotification]] {
            
            for alert in storedAlerts {
                var newNotifications = [PushNotification]()
                for oldNotification in alert.value {
                    let newPushNotification = PushNotification(accountNumbers: oldNotification.accountNumbers,
                                                               title: oldNotification.title ?? "",
                                                               message: oldNotification.message ?? "",
                                                               date: oldNotification.date)
                    newNotifications.append(newPushNotification)
                }

                accounts.append(AccountNotifications(accountNumber: alert.key, notifications: newNotifications))
                Log.error("MIGRATION OCCURED")
            }
            
            // persist to disk
            let encoder = JSONEncoder()
            guard let encoded = try? encoder.encode(accounts) else {
                Log.error("Failed to save notification due to encoding error: \n")
                return
            }
            self.defaults.set(encoded, forKey: PushNotificationStore.defaultsKey)
            Log.info("Notification Saved")
            
            defaults.set(true, forKey: "hasMigratedAlertStore")
        }
    }
    

    // Load all notifications across all accounts
    private func loadNotifications() {
        let decoder = JSONDecoder()
        guard let savedNotificationContainers = defaults.object(forKey: PushNotificationStore.defaultsKey) as? Data,
              let notificationContainers = try? decoder.decode([AccountNotifications].self, from: savedNotificationContainers) else {
            Log.error("Failed to load notifications due to decoding error.")
            return
        }
                accounts = notificationContainers
        Log.info("Loading notifications...")
    }

    // get all of the notifications for a specific account
    func loadNotifications(for accountNumber: String) -> [PushNotification] {
        Log.info("Loading notifications for account: \(accountNumber)...")
        Log.info("\(accounts)")
        return accounts.first(where: { $0.accountNumber == accountNumber })?.notifications ?? []
    }


    // Add notification to each account that it applies to and save to user defaults
    func saveNotification(_ notification: PushNotification) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            // Add new notification to accounts array
            self?.addToAccounts(notification)

            // Save
            let encoder = JSONEncoder()
            guard let accounts = self?.accounts,
                  let encoded = try? encoder.encode(accounts) else {
                Log.error("Failed to save notification due to encoding error: \n\(notification)")
                return
            }
            self?.defaults.set(encoded, forKey: PushNotificationStore.defaultsKey)
            Log.info("Notification Saved")
        }
    }

    // Add notification to accounts
    private func addToAccounts(_ notification: PushNotification) {
        notification.accountNumbers.forEach { accountNumber in
            if let index = accounts.firstIndex(where: { $0.accountNumber == accountNumber }) {
                // Add new notification to existing account
                accounts[index].notifications.append(notification)
            } else {
                // Add new account and notification to stored accounts
                accounts.append(AccountNotifications(accountNumber: accountNumber, notifications: [notification]))
            }
        }
    }
}

struct AccountNotifications: Codable {
    var accountNumber: String
    var notifications: [PushNotification]
}

struct PushNotification: Codable, Equatable {
    let accountNumbers: [String]
    let title: String
    let message: String
    
    var date = Date()
}
