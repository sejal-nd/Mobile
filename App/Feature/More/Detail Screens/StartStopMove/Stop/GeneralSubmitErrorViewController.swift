//
//  GeneralSubmitErrorViewController.swift
//  EUMobile
//
//  Created by Aman Vij on 07/10/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class GeneralSubmitErrorViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var helplineDescriptionTextView: UITextView!

    let helplineDescription = "Please call our Customer Care Center at 1-800-685-0123 Monday-Friday from 7 a.m. to 7 p.m. for more information."
    let contactNumber = "1-800-685-0123"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
    }
    
    func initialSetup() {
        
        navigationSetup()
        fontStyle()
        dataBinding()
    }
    
    private func fontStyle() {
        
        statusLabel.font = .title3
        helplineDescriptionTextView.font = .subheadline
    }
    
    private func navigationSetup() {
        
        navigationItem.hidesBackButton = false
        let newBackButton = UIBarButtonItem(image: UIImage(named: "ic_close"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(GeneralSubmitErrorViewController.back(sender:)))
        navigationItem.leftBarButtonItem = newBackButton
    }
    
    private func dataBinding() {
        
        let range = (helplineDescription as NSString).range(of: contactNumber)
        let attributedString = NSMutableAttributedString(string: helplineDescription)
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.neutralDark], range: NSRange(location: 0, length: helplineDescription.count))
        attributedString.addAttributes([ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.primaryBlue], range: range)
        helplineDescriptionTextView.attributedText = attributedString
        helplineDescriptionTextView.isUserInteractionEnabled = true
        helplineDescriptionTextView.delegate = self
        helplineDescriptionTextView.isEditable = false
        helplineDescriptionTextView.textAlignment = .center
        helplineDescriptionTextView.textContainerInset = .zero
    }
    
    @objc func back(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
