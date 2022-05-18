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

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var ctaButton: PrimaryButton!
    
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
        
        
//        addChild(unwrappedChildView)
//        view.addSubview(unwrappedChildView.view)

        containerView.addSubview(unwrappedChildView.view)
        
        // Set constraints
        unwrappedChildView.view.translatesAutoresizingMaskIntoConstraints = false

        
        NSLayoutConstraint.activate([
            unwrappedChildView.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            unwrappedChildView.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            unwrappedChildView.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            unwrappedChildView.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        
    }
    
    private func didPressButton() {
        print("PRESSED")
        ctaButton.setTitle("Hello World", for: .normal)
    }
    
    // MARK: Action
    
    @IBAction func ctaButtonPress(_ sender: Any) {
        print("TEST TEST TEST")
        
        ctaButton.setTitle("Hello World 123", for: .normal)

    }
    
}
