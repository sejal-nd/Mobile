//
//  LoginLandingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class LoginLandingViewController: UIViewController {
    @IBOutlet weak var logoView: UIView!
    
    var hasSeenTerms = false

    override func viewDidLoad() {
        super.viewDidLoad()

        logoView.backgroundColor = .primaryColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        
        if (!hasSeenTerms) { // use NSUserDefaults eventually
            performSegue(withIdentifier: "termsConditionsModalSegue", sender: self)
            hasSeenTerms = true
        }
        
    }
    
    @IBAction func onSkipForNowPress(_ sender: UIButton) {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.present(viewController!, animated: true, completion: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
 

}
