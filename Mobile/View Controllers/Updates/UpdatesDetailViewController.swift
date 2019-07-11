//
//  UpdatesDetailViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UpdatesDetailViewController: UIViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var label: UILabel!
    
    var opcoUpdate: OpcoUpdate!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Update", comment: "")

        titleLabel.textColor = .blackText
        titleLabel.font = OpenSans.bold.of(textStyle: .title1)
        titleLabel.attributedText = opcoUpdate.title
            .attributedString(lineHeight: 28)
        
        label.textColor = .blackText
        label.font = OpenSans.regular.of(textStyle: .body)
        label.text = opcoUpdate.message
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

}
