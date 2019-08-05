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
    @IBOutlet weak var arrowImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var backLabel: UILabel!
    
    @IBInspectable var isLabelHidden: Bool = false {
        didSet {
            backLabel.isHidden = isLabelHidden
        }
    }
    
    @IBInspectable var tintWhite: Bool = false {
        didSet {
            arrowImage.tintColor = tintWhite ? .white : .actionBlue
            backLabel.textColor = tintWhite ? .white : .actionBlue
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
    
    // When created in a Storyboard this isn't necessary (because it will lay out exactly as you
    // specify), but when creating programatically to set a `navigationItem.leftBarButtonItem`,
    // this leading constraint is necessary for proper apperance.
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        commonInit()
        arrowImageLeadingConstraint.constant = -8.5
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
        arrowImage.tintColor = .actionBlue
        backLabel.textColor = .actionBlue
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
