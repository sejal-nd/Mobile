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
        
        switch Environment.sharedInstance.opco {
        case .bge:
            infoLabel.text = NSLocalizedString("Eliminate your paper bill.  Your online bill is identical to your current paper bill and is available to view, download, or print at any time.  You will receive bill ready email notifications regardless of preference.  Your preference will be updated with your next month’s bill.", comment: "")
        case .peco, .comEd:
            infoLabel.text = NSLocalizedString("Eliminate your paper bill and receive an email notification when your bill is ready to view online.  Your online bill is identical to your current paper bill and is available to view, download, or print at any time.  Your preference will be updated with your next month’s bill.", comment: "")
        }
        
        infoLabel.font = OpenSans.regular.of(textStyle: .body)
        infoLabel.setLineHeight(lineHeight: 25)
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
