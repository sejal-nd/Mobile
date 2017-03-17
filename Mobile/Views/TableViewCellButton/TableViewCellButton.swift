//
//  TableViewCellButton.swift
//  Mobile
//
//  Created by Marc Shilling on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class TableViewCellButton: UIButton {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var caretAccessory: UIImageView!
    
    @IBInspectable var labelText: String? {
        didSet {
            label.text = labelText
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("TableViewCellButton", owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        addSubview(view)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.masksToBounds = false
        
        label.textColor = .darkJungleGreen
        detailLabel.textColor = .oldLavender
        setDetailLabel(text: "", checkHidden: true)
    }
    
    func setDetailLabel(text: String, checkHidden: Bool) {
        detailLabel.text = text
        detailLabel.isHidden = text.characters.count == 0
        checkImage.isHidden = checkHidden
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
               view.backgroundColor = .whiteButtonHighlight
            }
            else {
                view.backgroundColor = .white
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.33
        }
    }
    
}
