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
    @IBOutlet private weak var detailsTextView: UITextView!
    
    var opcoUpdate: Alert!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setValues()
        
        style()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Helper
    
    private func style() {
        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        
        detailsTextView.textColor = .deepGray
        detailsTextView.font = OpenSans.regular.of(textStyle: .body)
    }
    
    private func setValues() {
        title = NSLocalizedString("Update", comment: "")
        
        titleLabel.attributedText = opcoUpdate.title
            .attributedString(lineHeight: 28)
        
        detailsTextView.text = opcoUpdate.message
    }
    
}
