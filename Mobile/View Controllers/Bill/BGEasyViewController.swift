//
//  BGEasyViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/12/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class BGEasyViewController: DismissableFormSheetViewController {
    
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet var bulletCollection: [UIView]!
    @IBOutlet weak var bullet1Label: UILabel!
    @IBOutlet weak var bullet2Label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryColor
        
        xButton.imageView?.tintColor = .actionBlue
        
        navBar.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        
        titleLabel.textColor = .blackText
        titleLabel.text = NSLocalizedString("BGEasy Customer", comment: "")
        titleLabel.setLineHeight(lineHeight: 25)
        
        descriptionLabel.textColor = .deepGray
        descriptionLabel.text = NSLocalizedString("You are currently enrolled in BGEasy, our legacy automatic payment system.", comment: "")

        for view in bulletCollection {
            view.backgroundColor = .primaryColor
            view.layer.cornerRadius = 3.5
        }
        
        bullet1Label.textColor = .deepGray
        bullet1Label.text = NSLocalizedString("As an existing participant, you may continue to use this plan at no additional charge; however this payment option cannot be managed through an online account.", comment: "")
        bullet1Label.setLineHeight(lineHeight: 25)
        
        bullet2Label.textColor = .deepGray
        bullet2Label.text = NSLocalizedString("If you would like to take advantage of the more flexible BGE.com payment options or if you would like to manage your BGEasy program enrollment, please contact us.", comment: "")
        bullet2Label.setLineHeight(lineHeight: 25)
    }
    
    @IBAction func onXPress() {
        dismiss(animated: true, completion: nil)
    }

}
