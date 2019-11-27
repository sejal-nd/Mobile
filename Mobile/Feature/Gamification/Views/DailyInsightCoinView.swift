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
    @IBOutlet weak var circleBorderView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    private var canCollect = true
    
    var usage: DailyUsage?
    var lastWeekUsage: DailyUsage?
    var placeholderDate: Date?
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 56)
    }
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init(usage: DailyUsage, lastWeekUsage: DailyUsage?, canCollect: Bool) {
        super.init(frame: CGRect(x: 0, y: 0, width: 36, height: 56))
        
        self.usage = usage
        self.lastWeekUsage = lastWeekUsage
        
        commonInit()
         
        weekdayLabel.text = usage.date.weekday.abbreviationString
        
        if canCollect {
            imageView.image = #imageLiteral(resourceName: "ic_coin.pdf")
        } else {
            self.canCollect = false
            imageView.image = lastWeekComparisionImage
        }
    }
    
    init(placeholderViewForDate date: Date) {
        super.init(frame: CGRect(x: 0, y: 0, width: 36, height: 56))
        
        placeholderDate = date
        commonInit()
        
        weekdayLabel.text = date.weekday.abbreviationString
        imageView.image = nil
        
        canCollect = false
    }

    func commonInit() {
        Bundle.main.loadNibNamed("DailyInsightCoinView", owner: self, options: nil)
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
                
        circleBorderView.layer.borderColor = UIColor.accentGray.cgColor
        circleBorderView.layer.borderWidth = 1
        circleBorderView.layer.cornerRadius = 18
        circleBorderView.layer.masksToBounds = true
        
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    @objc func onTap() {
        if canCollect {
            canCollect = false
            imageView.image = lastWeekComparisionImage
            delegate?.dailyInsightCoinView(self, wasTappedWithCoinCollected: true)
        } else {
            delegate?.dailyInsightCoinView(self, wasTappedWithCoinCollected: false)
        }
    }
    
    var lastWeekComparisionImage: UIImage? {
        // Have this week's data, but no data for last week
        if usage != nil && lastWeekUsage == nil {
            return #imageLiteral(resourceName: "ic_trendcheck.pdf")
        }
        
        // No data - placeholder view
        guard let thisWeek = usage, let lastWeek = lastWeekUsage else { return nil }
        
        let diff = abs(thisWeek.amount - lastWeek.amount)
        let diffThreshold = thisWeek.unit == "kWh" ? 0.5 : 0.1
        if diff <= diffThreshold {
            return #imageLiteral(resourceName: "ic_trendequal.pdf")
        } else {
            if thisWeek.amount > lastWeek.amount {
                return #imageLiteral(resourceName: "ic_trendup.pdf")
            } else {
                return #imageLiteral(resourceName: "ic_trenddown.pdf")
            }
        }
    }
    
    var lastWeekComparisonString: String {
        // Have this week's data, but no data for last week
        if let thisWeek = usage, lastWeekUsage == nil {
            return String.localizedStringWithFormat("You used %@ %@.", thisWeek.amount.twoDecimalString, thisWeek.unit)
        }
        
        // No data - placeholder view
        guard let thisWeek = usage, let lastWeek = lastWeekUsage else {
            return NSLocalizedString("Data not yet available. It generally takes 24 to 48 hours to appear. Check back later!", comment: "")
        }
        
        let diff = abs(thisWeek.amount - lastWeek.amount)
        let diffThreshold = thisWeek.unit == "kWh" ? 0.5 : 0.1
        if diff <= diffThreshold {
            return String.localizedStringWithFormat("You used %@ %@ which was about the same as last week.", thisWeek.amount.twoDecimalString, thisWeek.unit)
        } else {
            if thisWeek.amount > lastWeek.amount {
                return String.localizedStringWithFormat("You used %@ %@ which was %@ %@ more than last week.",
                                                        thisWeek.amount.twoDecimalString, thisWeek.unit, diff.twoDecimalString, thisWeek.unit)
            } else {
                return String.localizedStringWithFormat("You used %@ %@ which was %@ %@ less than last week.",
                    thisWeek.amount.twoDecimalString, thisWeek.unit, diff.twoDecimalString, thisWeek.unit)
            }
        }
    }
    
}
