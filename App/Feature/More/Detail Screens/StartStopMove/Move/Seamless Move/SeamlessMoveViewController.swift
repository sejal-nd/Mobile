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

    var childView: UIHostingController<SeamlessMoveWarningView>? = nil// = UIHostingController(rootView: SeamlessMoveWarningView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addHostingController()
    }
    
    private func addHostingController() {
        let seamlessMoveView = SeamlessMoveWarningView(stopServiceAddress: "123 123123 123 TEST",
                                                       startServiceAddress: "New new new 321 312 312",
                                                       didPressButton: didPressButton)
        childView = UIHostingController(rootView: (seamlessMoveView))
        
        
        guard let unwrappedChildView = childView else {
            return
        }
        
        addChild(unwrappedChildView)
        view.addSubview(unwrappedChildView.view)
        
        // Set constraints        
        unwrappedChildView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            unwrappedChildView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            unwrappedChildView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            unwrappedChildView.view.topAnchor.constraint(equalTo: view.topAnchor),
            unwrappedChildView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func didPressButton() {
        print("PRESSED")
    }
    
}
