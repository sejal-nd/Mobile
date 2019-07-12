//
//  SetDefaultAccountTableViewCell.swift
//  Mobile
//
//  Created by Marc Shilling on 7/12/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class SetDefaultAccountTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var radioButtonImageView: UIImageView!
    @IBOutlet weak var dividerLine: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        radioButtonImageView.image = #imageLiteral(resourceName: "ic_radiobutton_deselected")
        
        label.lineBreakMode = .byWordWrapping
        label.textColor = .blackText
        label.font = SystemFont.regular.of(textStyle: .headline)
        
        dividerLine.backgroundColor = .accentGray
        
        selectionStyle = .none
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        radioButtonImageView.image = selected ? #imageLiteral(resourceName: "ic_radiobutton_selected") : #imageLiteral(resourceName: "ic_radiobutton_deselected")
    }
    
}
