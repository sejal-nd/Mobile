//
//  StopLandingViewController.swift
//  EUMobile
//
//  Created by Salunke, Swapnil Uday on 07/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class StopLandingViewController: UIViewController {

    @IBOutlet weak var headerMessageLabel: UILabel! {
        didSet {
            headerMessageLabel.textColor = .deepGray
            headerMessageLabel.font = SystemFont.semibold.of(textStyle: .title3)
            headerMessageLabel.text = NSLocalizedString("Permanently stop your current service", comment: "")
        }
    }
    @IBOutlet weak var estimatedTimeLabel: UILabel! {
        didSet {
            estimatedTimeLabel.textColor = .deepGray
            estimatedTimeLabel.font = SystemFont.regular.of(textStyle: .caption1)
            estimatedTimeLabel.text = NSLocalizedString("EST 4-7 MINUTES", comment: "")
        }
    }
    @IBOutlet weak var youWillNeedLabel: UILabel! {
        didSet {
            youWillNeedLabel.textColor = .deepGray
            youWillNeedLabel.font = SystemFont.regular.of(textStyle: .caption1)
            youWillNeedLabel.text = NSLocalizedString("You'll need:", comment: "")
        }
    }
    
    @IBOutlet weak var stopDateMessagingLabel: UILabel! {
        didSet {
            stopDateMessagingLabel.textColor = .deepGray
            stopDateMessagingLabel.font = SystemFont.regular.of(textStyle: .body)
            stopDateMessagingLabel.text = NSLocalizedString("Date to stop your service within 30 days, excluding holidays and Sundays.", comment: "")
        }
    }
    
    @IBAction func BeginTapped(_ sender: UIButton) {
        ///TODO:  Navigate to the first screen of the Stop Service Flow.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addCloseButton()
    }
}
