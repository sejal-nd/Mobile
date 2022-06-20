//
//  InfoModalViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

class InfoModalViewController: DismissableFormSheetViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var infoModalButton: SecondaryButton!
    

  
    
    private var image: UIImage
    private var infoDescription: String
    private let infoModalBtnLabel: String?
    private let onClose: (() -> ())?
    private let onBtnClick: (() -> ())?
    
    init(title: String, image: UIImage, description: String, modalBtnLabel: String? = nil, onClose: (() -> ())? = nil, onBtnClick: (() -> ())? = nil) {
        self.image = image
        self.infoDescription = description
        self.infoModalBtnLabel = modalBtnLabel
        self.onClose = onClose
        self.onBtnClick = onBtnClick
        
        
        super.init(nibName: "InfoModal", bundle: nil)
        
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        
        addCloseButton()
        
        imageView.image = image

        descriptionLabel.textColor = .deepGray
        descriptionLabel.font = SystemFont.regular.of(textStyle: .body)
        descriptionLabel.text = infoDescription
        descriptionLabel.setLineHeight(lineHeight: 25)
        
        self.infoModalButton.isHidden = infoModalBtnLabel == nil
        infoModalButton.titleLabel?.text = infoModalBtnLabel ?? ""
        
    }
    
    
    @IBAction func infoModalButtonPress() {
        self.dismissModal()
        onBtnClick?()
    }

   
    override func dismissModal() {
        onClose?()
        super.dismissModal()
    }
    
}
