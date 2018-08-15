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
            titleLabel.font = SystemFont.medium.of(textStyle: .headline)
        }
    }
    @IBOutlet weak var toggle: UISwitch! {
        didSet {
            toggle.layer.cornerRadius = 16.0
            toggle.layer.masksToBounds = true
            
            toggle.tintColor = .switchBackgroundColor
            toggle.backgroundColor = .switchBackgroundColor
            toggle.thumbTintColor = .primaryColor
            toggle.onTintColor = .white
        }
    }

    private let disposeBag = DisposeBag()
    

    // MARK: - Configure

    public func configure(viewModel: MoreViewModel) {        
        // Style
        backgroundColor = .primaryColor
        
        // Set Data
        if viewModel.biometricsString() == "Face ID" {
            iconImageView.image = #imageLiteral(resourceName: "ic_morefaceid")
            titleLabel.text = NSLocalizedString("Face ID", comment: "")
        } else {
            iconImageView.image = #imageLiteral(resourceName: "ic_moretouchid")
            titleLabel.text = NSLocalizedString("Touch ID", comment: "")
        }
        toggle.isOn = viewModel.isBiometryEnabled()
        
        // Accessibility
        titleLabel.accessibilityLabel = titleLabel.text
        toggle.isAccessibilityElement = true
    }

}
