//
//  InfoModalViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class InfoModalViewController: DismissableFormSheetViewController {
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var navTitle: String
    private var image: UIImage
    private var infoDescription: String
    private let onClose: (() -> ())?
    
    init(title: String, image img: UIImage, description: String, onClose: (() -> ())? = nil) {
        navTitle = title
        image = img
        infoDescription = description
        self.onClose = onClose
        
        super.init(nibName: "InfoModal", bundle: nil)
        
        modalPresentationStyle = .formSheet // For iPad
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        navBarView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        
        xButton.tintColor = .actionBlue
        xButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        
        titleLabel.textColor = .blackText
        titleLabel.text = navTitle
        
        imageView.image = image

        descriptionLabel.font = OpenSans.regular.of(textStyle: .body)
        descriptionLabel.textColor = .deepGray
        descriptionLabel.text = infoDescription
        descriptionLabel.setLineHeight(lineHeight: 25)
    }
    
    @IBAction func xAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: onClose)
    }

}
