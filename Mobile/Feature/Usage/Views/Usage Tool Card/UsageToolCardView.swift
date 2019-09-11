//
//  UsageToolCardView.swift
//  Mobile
//
//  Created by Samuel Francis on 7/27/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class UsageToolCardView: ButtonControl {
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var lineView: UIView!
    
    override func commonInit() {
        super.commonInit()
        normalBackgroundColor = .white
        backgroundColorOnPress = .softGray
        Bundle.main.loadNibNamed(UsageToolCardView.className, owner: self, options: nil)
        containerView.frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(containerView)
        styleViews()
    }
    
    // MARK: - Configure
    
    public func configureView(withUsageTool usageTool: UsageTool) {
        titleLabel.text = usageTool.title
        imageView.image = usageTool.icon
        accessibilityLabel = usageTool.title
    }
    
    private func styleViews() {
        // Card Style
        containerView.backgroundColor = .clear
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        
        // Line
        lineView.layer.cornerRadius = 1
        lineView.backgroundColor = .softGray
        
        // Label
        titleLabel.textColor = .deepGray
        titleLabel.font = OpenSans.regular.of(textStyle: .subheadline)
    }

}
