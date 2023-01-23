//
//  HomeCardHeaderView.swift
//  EUMobile
//
//  Created by Cody Dillon on 11/9/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

@IBDesignable
class HomeCardHeaderView: UIView {

    @IBOutlet weak var view: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label: UILabel!

    @IBInspectable
    var title: String? {
        didSet {
            label.text = title
        }
    }

    @IBInspectable
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.commonInit()
    }

    func commonInit() {
        Bundle.main.loadNibNamed(className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        button.setTitle(nil, for: .normal)
        addSubview(view)
    }
}
