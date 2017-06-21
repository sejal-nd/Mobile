//
//  MiniWalletTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 6/21/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MiniWalletTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        innerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        accountNumberLabel.font = SystemFont.medium.of(textStyle: .headline)
        accountNumberLabel.textColor = .blackText
        nicknameLabel.font = SystemFont.medium.of(textStyle: .footnote)
        nicknameLabel.textColor = .middleGray
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

class MiniWalletSectionHeaderCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .white
        
        label.font = SystemFont.regular.of(textStyle: .footnote)
        label.textColor = .blackText
    }
}

class MiniWalletAddAccountCell: UITableViewCell {
    
    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        innerContentView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 0), radius: 3)
        
        label.font = SystemFont.medium.of(textStyle: .title1)
        label.textColor = .blackText
    }
    
}
