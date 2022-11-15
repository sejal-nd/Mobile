//
//  PrepaidCardView.swift
//  Mobile
//
//  Created by Samuel Francis on 4/10/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

final class PrepaidCardView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(PrepaidCardView.className, owner: self, options: nil)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        styleViews()
    }
    
    private func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 10
        
        headerLabel.textColor = .blackText
        headerLabel.font = ExelonFont.semibold.of(textStyle: .headline)
        
        detailLabel.textColor = .blackText
        detailLabel.font = ExelonFont.regular.of(textStyle: .subheadline)
    }
    
    @IBAction private func launchDashboard() {
        GoogleAnalytics.log(event: .prePaidEnrolled)
        let url = URL(string: Configuration.shared.myAccountUrl)!
        UIApplication.shared.openUrlIfCan(url)
    }
}
