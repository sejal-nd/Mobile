//
//  TitleDetailRow.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class TitleDetailRow: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var disclosureIndicatorImageView: UIImageView!
    

    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        style()
    }
    
    
    // MARK: - Helper
    
    private func style() {
        titleLabel.textColor = .blackText
        titleLabel.font = SystemFont.regular.of(textStyle: .headline)
        detailLabel.textColor = .middleGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        // Cell Selection Color
        let backgroundView = UIView()
        backgroundView.backgroundColor = .softGray
        selectedBackgroundView = backgroundView
    }
}


// MARK: - Cell Configuration

extension TitleDetailRow {
    func configure(image: UIImage? = nil, title: String, detail: String? = nil, disclosureIndicatorImage: UIImage? = UIImage(named: "ic_caret")) {
        iconImageView.image = image
        titleLabel.text = title
        detailLabel.text = detail
        disclosureIndicatorImageView.image = disclosureIndicatorImage
    }
}
