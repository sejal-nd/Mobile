//
//  PaperlessEBillCommercialViewController.swift
//  Mobile
//
//  Created by Sam Francis on 5/2/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PaperlessEBillCommercialViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    private var url: URL? {
        switch Environment.sharedInstance.opco {
        case .comEd:
            return URL(string: "https://mydetail.getbills.com/BDComEd/index.jsp")
        case .peco:
            return URL(string: "https://mydetail.getbills.com/BDPeco/index.jsp")
        case .bge:
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let text = NSLocalizedString("Eliminate your paper bill and receive an email notification when your bill is ready to view online.  Your online bill is identical to your current paper bill and is available to view, download, or print at any time.  Your preference will be updated with your next month’s bill.  Business customers can create an online account and enroll in Paperless eBill %@.", comment: "")
        let hereText = NSLocalizedString("here", comment: "")
        let allText = String(format: text, hereText)
        
        guard let url = url else { return }
        let attributedText = NSMutableAttributedString(string: allText, attributes: [NSFontAttributeName: OpenSans.regular.ofSize(16),
                                                                                     NSForegroundColorAttributeName: UIColor.darkJungleGreen])
        attributedText.addAttribute(NSLinkAttributeName, value: url, range: (allText as NSString).range(of: hereText))
        textView.attributedText = attributedText
    }

    @IBAction func cancelPressed(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
}
