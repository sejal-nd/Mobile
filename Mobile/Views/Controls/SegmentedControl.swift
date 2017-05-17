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
    private var bigBottomBar: UIView?
    private var selectedBar: UIView?

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
        
        for _ in 0...2 {
            let view = UIView(frame: .zero)
            view.isUserInteractionEnabled = false
            views.append(view)
            
            let label = UILabel(frame: .zero)
            label.textColor = UIColor.actionBlue
            label.numberOfLines = 0
            label.textAlignment = .center
            labels.append(label)
            
            view.addSubview(label)
            addSubview(view)
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
                    label.font = UIFont.boldSystemFont(ofSize: 17)
                } else {
                    label.font = UIFont.systemFont(ofSize: 17)
                }
                label.frame.size = CGSize(width: view.bounds.size.width, height: view.bounds.size.height)
                label.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
            }
            
            bigBottomBar!.frame = CGRect(x: 0, y: frame.height - 6, width: frame.width, height: 6)
            
            let xPos = CGFloat(selectedIndex.value) * itemWidth
            selectedBar!.frame = CGRect(x: xPos, y: frame.height - 6, width: itemWidth + 1, height: 6)
        }
    }
    
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        let location = touch.location(in: self)
        
        let itemWidth = frame.width / CGFloat(items!.count)
        
        var calculatedIndex : Int?
        for i in 1...items!.count {
            if location.x < itemWidth * CGFloat(i) {
                calculatedIndex = i - 1
                break
            }
        }

        if calculatedIndex != nil {
            selectedIndex.value = calculatedIndex!
            sendActions(for: .valueChanged)
        }
        
        setNeedsLayout()
        
        return false
    }

}
