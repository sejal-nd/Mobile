//
//  UINavigationBackButton.swift
//  Mobile
//
//  Created by Marc Shilling on 6/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class UINavigationBackButton: UIButton {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var backLabel: UILabel!
    
    @IBInspectable var isLabelHidden: Bool = false {
        didSet {
            backLabel.isHidden = isLabelHidden
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
        backgroundColor = .clear
        Bundle.main.loadNibNamed(className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        addSubview(view)
        
        arrowImage.image = arrowImage.image!.withRenderingMode(.alwaysTemplate)
        arrowImage.tintColor = .white
        backLabel.textColor = .white
    }
    
    override func layoutSubviews() {
        titleLabel?.isHidden = true
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                arrowImage.alpha = 0.2
                backLabel.alpha = 0.2
            }
            else {
                arrowImage.alpha = 1.0
                backLabel.alpha = 1.0
            }
        }
    }
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        backLabel.text = title
    }
    
}
