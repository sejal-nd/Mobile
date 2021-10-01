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

        addCloseButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)


        // Note :
        // navigate to New Service Address Screen
        // when Move Landing and Move Stop implemented
        // make changes accordingly
        //
        performSegue(withIdentifier: "NewServiceAddressSegue", sender: self)
    }

}
