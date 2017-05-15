//
//  DisclosureButton.swift
//  Mobile
//
//  Created by Marc Shilling on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class DisclosureButton: UIButton {
    
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
        Bundle.main.loadNibNamed(DisclosureButton.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        addSubview(view)
        
        addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        layer.masksToBounds = false
        
        label.textColor = .blackText
        detailLabel.textColor = .middleGray
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
               view.backgroundColor = .softGray
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
