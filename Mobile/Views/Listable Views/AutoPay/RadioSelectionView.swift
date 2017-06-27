//
//  RadioSelectionView.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class RadioSelectionView: UIView {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var radioButtonImageView: UIImageView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
//        Bundle.main.loadNibNamed(RadioSelectionView.className, owner: self, options: nil)
        
//        backgroundColor = .clear
//        self.backgroundColor = .clear
//        
//        radioButtonImageView.image = #imageLiteral(resourceName: "ic_radiobutton_deselected")
//        
//        label.numberOfLines = 0
//        label.lineBreakMode = .byWordWrapping
//        label.textColor = .blackText
//        label.font = SystemFont.regular.of(textStyle: .headline)
     }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .clear
        self.backgroundColor = .clear
        
        radioButtonImageView.image = #imageLiteral(resourceName: "ic_radiobutton_deselected")
        
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .blackText
        label.font = SystemFont.regular.of(textStyle: .headline)
    }
 
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setSelected(_ selected: Bool, animated: Bool) {
        radioButtonImageView.image = selected ? #imageLiteral(resourceName: "ic_radiobutton_selected") : #imageLiteral(resourceName: "ic_radiobutton_deselected")
    }

}
