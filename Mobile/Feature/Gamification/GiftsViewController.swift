//
//  GiftsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/20/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GiftsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Gifts", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    

}
