//
//  GameTaskStore.swift
//  Mobile
//
//  Created by Marc Shilling on 12/9/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import Foundation

final class GameTaskStore {
    static let shared = GameTaskStore()

    var tasks =  [GameTask]()

    // Private init protects against another instance being accidentally instantiated
    private init() {
        guard let filePath = Bundle.main.path(forResource: "GameTasks", ofType: "json") else {
            fatalError("GameTasks.json not found")
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data)
            if let jsonArray = jsonResult as? [[String: Any]] {
                tasks = jsonArray.compactMap { GameTask.from($0 as NSDictionary) }
            }
        } catch {
            fatalError("Failed to parse GameTasks.json: \(error.localizedDescription)")
        }
    }
    
    func tipWithId(_ id: String) -> GameTip {
        guard let tip = tasks.first(where: { id == $0.tip?.id })?.tip else {
            fatalError("Requested tip with id \(id) which does not exist in GameTasks.json")
        }
        return tip
    }

    func fetchTipIdsForPendingReminders(completion: @escaping ([String]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests.map({ $0.identifier }))
        }
    }
}
