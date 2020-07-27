//
//  PasswordStrengthMeterView.swift
//  Mobile
//
//  Created by Marc Shilling on 3/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class PasswordStrengthMeterView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    let weakColor = UIColor(red: 254/255, green: 114/255, blue: 18/255, alpha: 1.0)
    let mediumColor = UIColor(red: 255/255, green: 187/255, blue: 16/255, alpha: 1.0)
    let strongColor = UIColor(red: 110/255, green: 184/255, blue: 96/255, alpha: 1.0)
    
    let colorSubview = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .clear
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = frame.height / 2
        layer.masksToBounds = true

        addSubview(colorSubview)
    }
    
    func setScore(_ score: Int32) {
        if score == -1 { // Pass -1 to display an empty meter
            colorSubview.frame = CGRect(x: 0, y: 0, width: 0, height: frame.size.height)
        } else {
            let percentage = CGFloat(score + 1) / 5.0
            colorSubview.frame = CGRect(x: 0, y: 0, width: frame.size.width * percentage, height: frame.size.height)
            if score < 2 {
                colorSubview.backgroundColor = weakColor
            } else if score < 4 {
                colorSubview.backgroundColor = mediumColor
            } else {
                colorSubview.backgroundColor = strongColor
            }
        }
    }

}
