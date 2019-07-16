//
//  InfoModalViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class InfoModalViewController: DismissableFormSheetViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var image: UIImage
    private var infoDescription: String
    private let onClose: (() -> ())?
    
    init(title: String, image: UIImage, description: String, onClose: (() -> ())? = nil) {
        self.image = image
        self.infoDescription = description
        self.onClose = onClose
        
        super.init(nibName: "InfoModal", bundle: nil)
        
        self.title = title
        
        extendedLayoutIncludesOpaqueBars = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()
        
        imageView.image = image

        descriptionLabel.font = OpenSans.regular.of(textStyle: .body)
        descriptionLabel.textColor = .deepGray
        descriptionLabel.text = infoDescription
        descriptionLabel.setLineHeight(lineHeight: 25)
    }
    
}
