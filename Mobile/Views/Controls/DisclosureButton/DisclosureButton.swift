//
//  DisclosureButton.swift
//  Mobile
//
//  Created by Marc Shilling on 3/14/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DisclosureButton: UIButton {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var caretAccessory: UIImageView!
    
    @IBInspectable var labelText: String? {
        didSet {
            label.text = labelText
        }
    }
    
    var stormTheme = false {
        didSet {
            view.backgroundColor = .stormModeGray
            label.textColor = .white
            caretAccessory.image = #imageLiteral(resourceName: "ic_caret_white.pdf")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .clear
        Bundle.main.loadNibNamed(DisclosureButton.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.isUserInteractionEnabled = false
        addSubview(view)

        label.font = SystemFont.medium.of(textStyle: .headline)
        label.textColor = .blackText
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        detailLabel.textColor = .middleGray
        setDetailLabel(text: "", checkHidden: true)
        
        view.layer.cornerRadius = 10
        view.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
    }
    
    func setDetailLabel(text: String?, checkHidden: Bool) {
        detailLabel.text = text
        detailLabel.isHidden = (text ?? "").isEmpty
        checkImage.isHidden = checkHidden
    }
    
    public func setHideCaret(caretHidden: Bool) {
        caretAccessory.isHidden = caretHidden
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
               view.backgroundColor = stormTheme ? UIColor.stormModeGray.darker(by: 10) : .softGray
            }
            else {
                view.backgroundColor = stormTheme ? .stormModeGray : .white
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.5
            accessibilityTraits = isEnabled ? .button : [.button, .notEnabled]
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 60)
    }
    
}


extension Reactive where Base: DisclosureButton {
    
    var labelText: Binder<String?> {
        return Binder(base) { button, text in
            button.label.text = text
        }
    }
    
    var detailText: Binder<String?> {
        return Binder(base) { button, text in
            button.setDetailLabel(text: text, checkHidden: true)
        }
    }
    
}
