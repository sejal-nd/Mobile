//
//  InfoModalViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class InfoModalViewController: UIViewController {
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    private var navTitle: String!
    private var image: UIImage!
    private var infoDescription: String!
    
    init(title: String, image img: UIImage, description: String) {
        super.init(nibName: "InfoModal", bundle: nil)
        
        navTitle = title
        image = img
        infoDescription = description
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        
        navItem.title = navTitle
        
        imageView.image = image

        label.textColor = .blackText
        label.setLineHeight(lineHeight: 25)
        label.text = infoDescription
    }
    
    @IBAction func xAction(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

}
