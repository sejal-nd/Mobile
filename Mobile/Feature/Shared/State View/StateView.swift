//
//  StateView.swift
//  Mobile
//
//  Created by Cody Dillon on 11/7/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class StateView: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var stateImageView: UIImageView!
    @IBOutlet weak var stateLabel: UILabel!
    
    public var stateMessage: String = "" {
        didSet {
            stateLabel.text = stateMessage
        }
    }
    
    public var stateImageName: String = "" {
        didSet {
            stateImageView.image = UIImage(named: stateImageName)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(StateView.className, owner: self, options: nil)
        containerView.frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(containerView)
        styleViews()
    }
    
    private func styleViews() {
        stateLabel.textColor = .middleGray
        stateLabel.font = OpenSans.regular.of(textStyle: .headline)
    }
}
