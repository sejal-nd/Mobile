//
//  SegmentedControl.swift
//  Mobile
//
//  Created by Marc Shilling on 3/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class SegmentedControl: UIControl {
    
    var items: [String]?
    var selectedIndex = Variable(0)
    
    private var views = [UIView]()
    private var labels = [UILabel]()
    private var buttons = [UIButton]()
    private var bigBottomBar: UIView?
    private var selectedBar: UIView?
    
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
        clipsToBounds = true
        
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
        
        bigBottomBar = UIView(frame: .zero)
        bigBottomBar!.isUserInteractionEnabled = false
        bigBottomBar!.backgroundColor = .accentGray
        addSubview(bigBottomBar!)
        
        selectedBar = UIView(frame: .zero)
        selectedBar!.isUserInteractionEnabled = false
        selectedBar!.backgroundColor = .primaryColor
        addSubview(selectedBar!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let items = items {
            let itemWidth = frame.width / CGFloat(items.count)
            for (index, item) in items.enumerated() {
                let xPos = CGFloat(index) * itemWidth
                
                let view = views[index]
                view.frame = CGRect(x: xPos, y: 0, width: itemWidth, height: frame.height - 6)
                view.backgroundColor = index == selectedIndex.value ?
                    UIColor(red: 237/255, green: 237/255, blue: 237/255, alpha: 1) :
                    UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
                view.addTopBorder(color: .accentGray, width: 1)
                view.addLeftBorder(color: .accentGray, width: 1)
                if index == items.count - 1 {
                    view.addRightBorder(color: .accentGray, width: 1)
                }
                
                let label = labels[index]
                label.text = item
                if index == selectedIndex.value {
                    label.font = SystemFont.bold.of(textStyle: .subheadline)
                } else {
                    label.font = SystemFont.regular.of(textStyle: .subheadline)
                }
                label.frame.size = CGSize(width: view.bounds.size.width, height: view.bounds.size.height)
                label.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
                
                let button = buttons[index]
                button.accessibilityTraits = UIAccessibilityTraitNone
                button.frame = view.frame
            }
            
            for (index, item) in items.enumerated() {
                let button = buttons[index]
                button.accessibilityLabel = String(format: NSLocalizedString("%@, option %@ of %@ %@", comment: ""), item, String(index + 1), String(items.count), index == selectedIndex.value ? NSLocalizedString(", selected", comment: "") : "")
            }
            
            bigBottomBar!.frame = CGRect(x: 0, y: frame.height - 6, width: frame.width, height: 6)
            
            let xPos = CGFloat(selectedIndex.value) * itemWidth
            selectedBar!.frame = CGRect(x: xPos, y: frame.height - 6, width: itemWidth + 1, height: 6)
        }
    }
    
    func onButtonTap(sender: UIButton) {
        let index = sender.tag
        
        selectedIndex.value = index
        sendActions(for: .valueChanged)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            let label = self.items![index]
            let a11yString = String(format: NSLocalizedString("Selected %@, option %@ of %@", comment: ""), label, String(index + 1), String(self.items!.count))
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, a11yString)
        })
        
        setNeedsLayout()
    }
    
}
