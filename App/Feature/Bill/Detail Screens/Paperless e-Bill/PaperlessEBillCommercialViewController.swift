//
//  PaperlessEBillCommercialViewController.swift
//  Mobile
//
//  Created by Sam Francis on 5/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PaperlessEBillCommercialViewController: DismissableFormSheetViewController {
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkButton: ButtonControl!
    @IBOutlet weak var buttonLabel: UILabel!
    
    private var url: URL? {
        switch Environment.shared.opco {
        case .comEd:
            return URL(string: "https://mydetail.getbills.com/BDComEd/index.jsp")
        case .peco:
            return URL(string: "https://mydetail.getbills.com/BDPeco/index.jsp")
        case .ace, .bge, .delmarva, .pepco:
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        xButton.tintColor = .actionBlue
        
        titleLabel.textColor = .blackText
        titleLabel.text = NSLocalizedString("Paperless eBill", comment: "")
        
        descriptionLabel.font = OpenSans.regular.of(textStyle: .body)
        descriptionLabel.textColor = .deepGray
        descriptionLabel.setLineHeight(lineHeight: 25)
        descriptionLabel.text = NSLocalizedString("Eliminate your paper bill and receive an email notification when your bill is ready to view online. Your online bill is identical to your current paper bill and is available to view, download, or print at any time. Your preference will be updated with your next month’s bill.", comment: "")
        
        linkButton.shouldFadeSubviewsOnPress = true
        buttonLabel.font = OpenSans.semibold.of(textStyle: .body)
        buttonLabel.setLineHeight(lineHeight: 25)
        buttonLabel.textColor = .actionBlue
        buttonLabel.text = NSLocalizedString("Business customers can create an online account and enroll in Paperless eBill here.", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func cancelPressed(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onLinkPress() {
        if let micrositeUrl = url {
            UIApplication.shared.open(micrositeUrl)
        }
    }
}
