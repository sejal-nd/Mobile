//
//  OpcoUpdatesHostingController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 10/27/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import UIKit
import SwiftUI

class SecondViewHostingController: UIHostingController<OpcoUpdatesView> {
    override init(rootView: OpcoUpdatesView) {
        super.init(rootView: rootView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: OpcoUpdatesView())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
