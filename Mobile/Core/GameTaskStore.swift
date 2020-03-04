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
    
    // Tracking for the 'Try the FAB' task
    var tryFabActivated = false {
        didSet {
            if !tryFabActivated {
                tryFabWentHome = false
                tryFabWentBackToGame = false
            }
        }
    }
    var tryFabWentHome = false
    var tryFabWentBackToGame = false

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
    
    func tipWithId(_ id: String) -> GameTip? {
        return tasks.first(where: { id == $0.tip?.id })?.tip
    }

    func fetchTipIdsForPendingReminders(completion: @escaping ([String]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.map({ $0.identifier }))
            }
        }
    }
}