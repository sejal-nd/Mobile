//
//  TermsPoliciesViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TermsPoliciesViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    let viewModel = TermsPoliciesViewModel()
    var viewAppeared = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        title = NSLocalizedString("Terms and Policies", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let url = viewModel.termPoliciesURL!
        webView.loadRequest(URLRequest(url: url))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setWhiteNavBar()
        } else {
            // if it loads from unauthorized user entry screen, then it
            // needs to explicitly set its style here because it cannot be cast
            // to MainBaseNavigationController
            setWhiteNavBar()
        }
    }
    
    private func setWhiteNavBar() {
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.tintColor = .actionBlue
        navigationController?.navigationBar.isTranslucent = false
        
        // Re-add the bottom border line (in case it was removed on another screen)
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.blackText,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // some trick when transition from terms and policies back to unauthorized entry screen
        // This prevent the navigation bar turns white when it goes back
        navigationController?.setNavigationBarHidden(true, animated: true)

    }
    
}
