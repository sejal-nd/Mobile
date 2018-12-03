//
//  UsageToolTopCardView.swift
//  Mobile
//
//  Created by Samuel Francis on 7/27/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class UsageToolTopCardView: ButtonControl {
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    
    override func commonInit() {
        super.commonInit()
        normalBackgroundColor = .white
        backgroundColorOnPress = .softGray
        Bundle.main.loadNibNamed(UsageToolTopCardView.className, owner: self, options: nil)
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
        addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        
        // Label
        titleLabel.textColor = .actionBlue
        titleLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
    }
}
