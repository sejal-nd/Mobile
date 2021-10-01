//
//  MoveLandingViewController.swift
//  EUMobile
//
//  Created by Salunke, Swapnil Uday on 07/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class MoveLandingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        
        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
        let scheduleMoveServiceViewController = storyboard.instantiateViewController(withIdentifier: "ScheduleMoveServiceViewController") as! ScheduleMoveServiceViewController
        self.navigationController?.pushViewController(scheduleMoveServiceViewController, animated: true)

    }
}
