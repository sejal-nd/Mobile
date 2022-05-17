//
//  SeamlessMoveViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/17/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit
import SwiftUI

class SeamlessMoveViewController: UIViewController {

    let childView = UIHostingController(rootView: SeamlessMoveWarningView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addHostingController()
    }
    
    private func addHostingController() {
        addChild(childView)
        view.addSubview(childView.view)
        
        // Set constraints        
        childView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childView.view.topAnchor.constraint(equalTo: view.topAnchor),
            childView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
}
