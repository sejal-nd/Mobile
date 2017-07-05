//
//  MultiPremiseAddressView.swift
//  Mobile
//
//  Created by Jeremy Kliphouse on 6/30/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class MultiPremiseAddressView: UIView {

    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var checkMark: UIImageView!
    
    class func instanceFromNib(showsCheck: Bool, labelText: String) -> MultiPremiseAddressView {
        
        let view = UINib(nibName: String(describing: MultiPremiseAddressView.self), bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! MultiPremiseAddressView
        
        view.addressLabel.text = labelText
        view.checkMark.isHidden = !showsCheck
        
        return view
        
    }

}
