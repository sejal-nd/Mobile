//
//  AnimateWithDuration+Completion.swift
//  Exelon_Mobile_watchOS Extension
//
//  Created by Joseph Erlandson on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

extension WKInterfaceController {
    func animate(withDuration duration: TimeInterval, animations: @escaping () -> Void, completion: @escaping () -> Void) {
        
        let queue = DispatchGroup()
        queue.enter()
        
        let action = {
            animations()
            queue.leave()
        }
        
        self.animate(withDuration: duration, animations: action)
        
        queue.notify(queue: .main, execute: completion)
    }
}
