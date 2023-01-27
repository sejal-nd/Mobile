//
//  AlertsStore.swift
//  Mobile
//
//  Created by Marc Shilling on 11/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation

final class AlertsStore {
    static let shared = AlertsStore()
    
    var alerts: [String: [PushNotification]] = [:]
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        let url = URL(fileURLWithPath: self.filePath)
        if let data = try? Data(contentsOf: url),
            let storedAlerts = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: [PushNotification]] {
            self.alerts = storedAlerts
        }
    }
    
    var filePath: String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        return (url!.appendingPathComponent("AlertsStore").path)
    }
    
    func savePushNotification(_ notification: PushNotification) {
        for accountNumber in notification.accountNumbers {
            if let array = alerts[accountNumber] {
                var arrayCopy = array
                arrayCopy.insert(notification, at: 0)
                alerts[accountNumber] = arrayCopy
            } else {
                let newArray = [notification]
                alerts[accountNumber] = newArray
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let url = URL(fileURLWithPath: self.filePath)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: self.alerts, requiringSecureCoding: false)
                try data.write(to: url)
            } catch {
                print("Couldn't write file")
            }
        }
    }
    
    func getAlerts(forAccountNumber accountNumber: String) -> [PushNotification] {
        if let notificationsArray = alerts[accountNumber] {
            return notificationsArray
        }
        return []
    }
}
