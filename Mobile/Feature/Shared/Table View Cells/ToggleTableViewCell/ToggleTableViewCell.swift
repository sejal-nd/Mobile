//
//  ToggleTableViewCell.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class ToggleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
            titleLabel.font = SystemFont.regular.of(textStyle: .callout)
        }
    }
    @IBOutlet weak var toggleCheckImageView: UIImageView!
    @IBOutlet weak var toggle: UISwitch! {
        didSet {
            toggle.layer.cornerRadius = 16.0
            toggle.layer.masksToBounds = true
            
            if StormModeStatus.shared.isOn {
                toggle.tintColor = .roseQuartz
                toggle.backgroundColor = .roseQuartz
                toggle.thumbTintColor = .stormModeBlack
                toggle.onTintColor = .stormPrimaryColor
            } else {
                toggle.tintColor = .switchBackgroundColor
                toggle.backgroundColor = .switchBackgroundColor
                toggle.thumbTintColor = .primaryColor
                toggle.onTintColor = .white
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = StormModeStatus.shared.isOn ? .clear : .primaryColor
        
        isAccessibilityElement = false
    }
    
    // MARK: - Configure
    public func configure(viewModel: MoreViewModel, tag: Int) {
        // Style
        backgroundColor = StormModeStatus.shared.isOn ? .clear : .primaryColor
        
        // Set Data
        if viewModel.biometricsString() == "Face ID" {
            iconImageView.image = #imageLiteral(resourceName: "ic_morefaceid")
            titleLabel.text = NSLocalizedString("Face ID", comment: "")
        } else {
            iconImageView.image = #imageLiteral(resourceName: "ic_moretouchid")
            titleLabel.text = NSLocalizedString("Touch ID", comment: "")
        }
        toggle.tag = tag
        toggle.isOn = viewModel.isBiometryEnabled()
        toggleCheckImageView.isHidden = !toggle.isOn
        
        toggle.isAccessibilityElement = true
    }
    
    // MARK:  Actions

    // Note: This only gets triggered when the user causes a change, does not trigger for programtic calls.
    @IBAction func toggleValueChanged(_ sender: UISwitch) {
        toggleCheckImageView.isHidden = !sender.isOn
    }
    
}
