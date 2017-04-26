//
//  WhatIsPaperlessEBillViewController.swift
//  Mobile
//
//  Created by Sam Francis on 4/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class WhatIsPaperlessEBillViewController: UIViewController {
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var navigationBar: UINavigationBar!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let subviews = navigationBar.subviews.flatMap { $0.subviews }
        guard let imageView = (subviews.filter { $0 is UIImageView && $0.bounds.width == navigationBar.frame.width && $0.bounds.height < 2.0 }).first as? UIImageView else { return }
        imageView.isHidden = true
    }
    
    @IBAction func xAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
