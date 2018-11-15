//
//  AlertPreferencesSectionHeaderView.swift
//  Mobile
//
//  Created by Samuel Francis on 9/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class AlertPreferencesSectionHeaderView: UIView {
    private let label = UILabel().usingAutoLayout()
    
    init() {
        super.init(frame: .zero)
        createView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createView()
    }
    
    private func createView() {
        backgroundColor = .white
        label.textColor = .blackText
        label.font = OpenSans.semibold.of(textStyle: .title1)
        
        let contentView = UIView().usingAutoLayout()
        addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        contentView.addTabletWidthConstraints(horizontalPadding: 0)
        
        contentView.addSubview(label)
        label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7).isActive = true
        label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: 12).isActive = true
        
        let separator = UIView().usingAutoLayout()
        separator.backgroundColor = .accentGray
        
        contentView.addSubview(separator)
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }
    
    func configure(withTitle title: String) {
        label.text = title
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 73)
    }
}
