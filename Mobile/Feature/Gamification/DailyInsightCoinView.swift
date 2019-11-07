//
//  DailyInsightCoinView.swift
//  Mobile
//
//  Created by Marc Shilling on 11/5/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import Foundation

protocol DailyInsightCoinViewTapDelegate: class {
    func dailyInsightCoinView(_ view: DailyInsightCoinView, wasTappedWithCoinCollected coinCollected: Bool)
}

class DailyInsightCoinView: UIControl {
    
    weak var delegate: DailyInsightCoinViewTapDelegate?
    
    @IBOutlet weak private var view: UIView!
    @IBOutlet weak var weekdayLabel: UILabel!
    //@IBOutlet weak var dateLabel: UILabel!
    //@IBOutlet weak var usageLabel: UILabel!
    @IBOutlet weak var coinImageView: UIImageView!
    //@IBOutlet weak var dataNotAvailableLabel: UILabel!
    
    private var canCollect = true
    
    var usage: DailyUsage?
    var placeholderDate: Date?
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init(dailyUsage: DailyUsage, canCollect: Bool) {
        super.init(frame: CGRect(x: 0, y: 0, width: 36, height: 56))
        commonInit()
        
        //print("\(dailyUsage.date) - \(dailyUsage.usage)")
        self.usage = dailyUsage
                
        weekdayLabel.text = dailyUsage.date.weekday.abbreviationString
        //dateLabel.text = dateFormatter.string(from: dailyUsage.date)
        //usageLabel.text = "\(dailyUsage.usage.twoDecimalString) kWh"
        
        if !canCollect {
            self.canCollect = false
            //usageLabel.isHidden = false
            //coinImageView.isHidden = true
        }
    }
    
    init(placeholderViewForDate date: Date) {
        super.init(frame: CGRect(x: 0, y: 0, width: 36, height: 56))
        commonInit()
        
        placeholderDate = date
        
        weekdayLabel.text = date.weekday.abbreviationString
        //dateLabel.text = dateFormatter.string(from: date)
        
        //coinImageView.isHidden = true
        //dataNotAvailableLabel.isHidden = false
        
        canCollect = false
    }

    func commonInit() {
        Bundle.main.loadNibNamed("DailyInsightCoinView", owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
                
        coinImageView.layer.borderColor = UIColor.accentGray.cgColor
        coinImageView.layer.borderWidth = 1
        coinImageView.layer.cornerRadius = 18
        coinImageView.layer.masksToBounds = true
        
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 56)
    }

    @objc func onTap() {
        if canCollect {
            canCollect = false
            
            //coinImageView.isHidden = true
            //usageLabel.isHidden = false
            
            //delegate?.dailyUsageView(self, wasTappedWithCoinCollected: true)
        }
        delegate?.dailyInsightCoinView(self, wasTappedWithCoinCollected: canCollect)
    }
    
}
