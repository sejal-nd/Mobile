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
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 10
        
        headerLabel.textColor = .blackText
        headerLabel.font = OpenSans.semibold.of(textStyle: .title1)
        
        detailLabel.textColor = .blackText
        detailLabel.font = OpenSans.regular.of(textStyle: .subheadline)
    }
    
    @IBAction private func launchDashboard() {
        let url = URL(string: Environment.shared.myAccountUrl)!
        UIApplication.shared.openUrlIfCan(url)
    }
}
