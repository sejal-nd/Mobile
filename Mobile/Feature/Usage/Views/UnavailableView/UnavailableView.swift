//
//  UnavailableView.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/20/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class UnavailableView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(UnavailableView.className, owner: self, options: nil)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        styleViews()
    }
    
    func styleViews() {
        titleLabel.font = OpenSans.semibold.of(textStyle: .title3)
        descriptionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
}
