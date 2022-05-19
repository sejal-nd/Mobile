//
//  TerminateAgreementViewController.swift
//  EUMobile
//
//  Created by Joseph Erlandson on 5/19/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit
import SwiftUI

class TerminateAgreementViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stickyFooterView: StickyFooterView!
    @IBOutlet weak var ctaButton: PrimaryButton!
    
    var childView: UIHostingController<TerminateAgreementView>? = nil// = UIHostingController(rootView: SeamlessMoveWarningView())
        
    private var hasAgreed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Third Party Agreement", comment: "")
        
        addHostingController()
    }
    
    private func addHostingController() {
        let terminateAgreementView = TerminateAgreementView(didSelectCheckbox: didSelectCheckbox)
        childView = UIHostingController(rootView: (terminateAgreementView))
                
        guard let unwrappedChildView = childView else {
            return
        }

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
    
    private func didSelectCheckbox(hasAgreed: Bool) {
        self.hasAgreed = hasAgreed
        
        ctaButton.isEnabled = hasAgreed
    }
    
    // MARK: Action
    
    @IBAction func ctaButtonPress(_ sender: Any) {
        if hasAgreed {
            performSegue(withIdentifier: "showComplete", sender: nil)
        }
    }
    
}
