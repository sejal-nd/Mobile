//
//  AlertsSegmentedControl.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertsSegmentedControl: UIControl {
    
    let disposeBag = DisposeBag()
    
    var selectedIndex = Variable(0)
    
    @IBOutlet weak var view: UIView!
    
    @IBOutlet weak var leftButton: ButtonControl!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var leftBar: UIView!
    
    @IBOutlet weak var rightButton: ButtonControl!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var rightBar: UIView!

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
        
        Bundle.main.loadNibNamed(AlertsSegmentedControl.className, owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        addSubview(view)
        
        leftLabel.textColor = .white
        rightLabel.textColor = .white
        
        
        leftSelection.map{ $0 ? OpenSans.bold.of(textStyle: .title1) : OpenSans.regular.of(textStyle: .title1) }.drive(leftLabel.rx.font).disposed(by: disposeBag)
        leftSelection.map{ $0 ? .white : UIColor.white.withAlphaComponent(0.4) }.drive(leftBar.rx.backgroundColor).disposed(by: disposeBag)
        leftSelection.not().map{ $0 ? OpenSans.bold.of(textStyle: .title1) : OpenSans.regular.of(textStyle: .title1) }.drive(rightLabel.rx.font).disposed(by: disposeBag)
        leftSelection.not().map{ $0 ? .white : UIColor.white.withAlphaComponent(0.4) }.drive(rightBar.rx.backgroundColor).disposed(by: disposeBag)
            
        leftSelection.map { [weak self] in
            $0 ? String(format: "%@, option 1 of 2, selected", self?.leftLabel.text ?? "") : String(format: "%@, option 1 of 2", self?.leftLabel.text ?? "")
            }.drive(leftButton.rx.accessibilityLabel).disposed(by: disposeBag)
        leftSelection.map { [weak self] in
            $0 ? String(format: "%@, option 2 of 2", self?.rightLabel.text ?? "") : String(format: "%@, option 2 of 2, selected", self?.rightLabel.text ?? "")
            }.drive(rightButton.rx.accessibilityLabel).disposed(by: disposeBag)
        
        leftButton.accessibilityTraits = .none
        rightButton.accessibilityTraits = .none
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        leftBar.roundCorners([.topLeft, .topRight], radius: 2.0)
        rightBar.roundCorners([.topLeft, .topRight], radius: 2.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        leftBar.roundCorners([.topLeft, .topRight], radius: 2.0)
        rightBar.roundCorners([.topLeft, .topRight], radius: 2.0)
    }
    
    func setItems(leftLabel: String, rightLabel: String, initialSelectedIndex: Int) {
        self.leftLabel.text = leftLabel
        self.rightLabel.text = rightLabel
        selectedIndex.value = initialSelectedIndex
    }
    
    @IBAction func onButtonTap(sender: ButtonControl) {
        if sender == leftButton {
            selectedIndex.value = 0
        } else {
            selectedIndex.value = 1
        }
        sendActions(for: .valueChanged)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: { [weak self] in
            var a11yString: String
            if self?.selectedIndex.value == 0 {
                a11yString = String(format: NSLocalizedString("Selected %@, option 1 of 2", comment: ""), self?.leftLabel.text ?? "")
            } else {
                a11yString = String(format: NSLocalizedString("Selected %@, option 2 of 2", comment: ""), self?.rightLabel.text ?? "")
            }
            UIAccessibility.post(notification: .announcement, argument: a11yString)
        })
    }
    
    private lazy var leftSelection: Driver<Bool> = self.selectedIndex.asDriver().map {
        $0 == 0
    }
    
}
