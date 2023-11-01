//
//  OpcoUpdatesHostingController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 10/27/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import UIKit
import SwiftUI

class OpcoUpdatesHostingController<T:View>: UIHostingController<T> {
    var shouldShowLargeTitle = true
    
    init(rootView: T, shouldShowLargeTitle: Bool) {
        super.init(rootView: rootView)
        self.shouldShowLargeTitle = shouldShowLargeTitle
    }
    
    override init(rootView: T) {
        super.init(rootView: rootView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented (or needed)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = shouldShowLargeTitle
    }
}
