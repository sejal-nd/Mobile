//
//  SegmentedControlNew.swift
//  Mobile
//
//  Created by Marc Shilling on 6/27/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SegmentedControlNew: UIControl {

    let disposeBag = DisposeBag()
    
    var items: [String]?
    var selectedIndex = Variable(0)
    
    private var views = [UIView]()
    private var labels = [UILabel]()
    private var buttons = [UIButton]()
    private var selectionPill = UIView(frame: .zero)
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .softGray
        
        selectionPill.backgroundColor = .white
        addSubview(selectionPill)
        
        for i in 0...2 {
            let view = UIView(frame: .zero)
            view.isUserInteractionEnabled = false
            views.append(view)
            
            let label = UILabel(frame: .zero)
            label.textColor = .actionBlue
            label.numberOfLines = 0
            label.textAlignment = .center
            label.isAccessibilityElement = false
            labels.append(label)
            
            let button = UIButton(frame: .zero)
            button.tag = i
            button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)
            buttons.append(button)
            
            view.addSubview(label)
            addSubview(view)
            addSubview(button)
        }
        
        selectedIndex.asDriver()
            .skip(1)
            .distinctUntilChanged()
            .drive(onNext: { [weak self] in self?.selectIndex($0, postAccessibilityNotification: false) })
            .disposed(by: disposeBag)
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        fullyRoundCorners(diameter: frame.size.height, borderColor: .accentGray, borderWidth: 1)
        selectionPill.fullyRoundCorners(diameter: frame.size.height, borderColor: .accentGray, borderWidth: 1)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if let items = items {
            let itemWidth = frame.width / CGFloat(items.count)
            
            let selectionPillSize = selectionPill.frame.size
            if selectionPillSize.width != itemWidth || selectionPillSize.height != frame.height {
                // To appropriately size the selectionPill without breaking animations
                selectionPill.frame = CGRect(x: 0, y: 0, width: itemWidth, height: frame.height)
            }
            
            for (index, item) in items.enumerated() {
                let xPos = CGFloat(index) * itemWidth
                
                let view = views[index]
                view.frame = CGRect(x: xPos, y: 0, width: itemWidth, height: frame.height)
                
                let label = labels[index]
                label.text = item
                if index == selectedIndex.value {
                    label.font = OpenSans.semibold.of(textStyle: .subheadline)
                } else {
                    label.font = OpenSans.regular.of(textStyle: .subheadline)
                }
                label.frame.size = CGSize(width: view.bounds.size.width, height: view.bounds.size.height)
                label.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
                
                let button = buttons[index]
                button.accessibilityTraits = .none
                button.frame = view.frame
            }
            
            for (index, item) in items.enumerated() {
                let button = buttons[index]
                button.accessibilityLabel = String(format: NSLocalizedString("%@, option %@ of %@ %@", comment: ""), item, String(index + 1), String(items.count), index == selectedIndex.value ? NSLocalizedString(", selected", comment: "") : "")
            }
        }
    }
    
    @objc func onButtonTap(sender: UIButton) {
        let index = sender.tag
        selectIndex(index)
    }
    
    func selectIndex(_ index: Int, animated: Bool = true, postAccessibilityNotification: Bool = true) {
        selectedIndex.value = index
        sendActions(for: .valueChanged)
        setNeedsLayout()
        
        if postAccessibilityNotification {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                let label = self.items![index]
                let a11yString = String(format: NSLocalizedString("Selected %@, option %@ of %@", comment: ""), label, String(index + 1), String(self.items!.count))
                UIAccessibility.post(notification: .announcement, argument: a11yString)
            })
        }
        
        let itemWidth = frame.width / CGFloat(items!.count)
        let xPos = CGFloat(index) * itemWidth
        
        let duration = animated ? 0.2 : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.selectionPill.frame = CGRect(x: xPos, y: 0, width: itemWidth, height: self.frame.height)
            self.layoutIfNeeded()
        }, completion: nil)
    }

}
