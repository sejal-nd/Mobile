//
//  MoveFinaledView.swift
//  EUMobile
//
//  Created by RAMAITHANI on 14/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class MoveFinaledView: UIView {
    
    @IBOutlet weak var serviceStatusLabel: UILabel!
    @IBOutlet weak var helplineDescriptionTextView: UITextView!
    
    let helplineDescription = "Please call our Customer Care Center at 1-800-685-0123 Monday-Friday from 7 a.m. to 7 p.m. for help and more information."
    let contactNumber = "1-800-685-0123"
    
    override func awakeFromNib() {
        
        fontStyle()
        dataBinding()
    }
    
    private func fontStyle() {
        
        serviceStatusLabel.font = SystemFont.semibold.of(textStyle: .title3)
        helplineDescriptionTextView.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
    private func dataBinding() {
        
        let range = (helplineDescription as NSString).range(of: contactNumber)
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.deepGray], range: NSRange(location: 0, length: helplineDescription.count))
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.actionBlue], range: range)
        helplineDescriptionTextView.attributedText = attributedString
        helplineDescriptionTextView.isUserInteractionEnabled = true
        helplineDescriptionTextView.isEditable = false
        helplineDescriptionTextView.textAlignment = .center
        helplineDescriptionTextView.textContainerInset = .zero
    }
}
