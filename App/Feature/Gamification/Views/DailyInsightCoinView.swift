//
//  DailyInsightCoinView.swift
//  Mobile
//
//  Created by Marc Shilling on 11/5/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

protocol DailyInsightCoinViewDelegate: class {
    func dailyInsightCoinView(_ view: DailyInsightCoinView, wasTappedWithCoinCollected coinCollected: Bool, decreasedUsage: Bool)
}

class DailyInsightCoinView: UIControl {
    
    weak var delegate: DailyInsightCoinViewDelegate?
    
    @IBOutlet weak private var view: UIView!
    @IBOutlet weak var weekdayLabel: UILabel!
    @IBOutlet weak var circleBorderView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lottieView: UIView!
    
    private var canCollect = true
    
    var dailyUsageData: DailyUsageData?
    var usage: DailyUsage?
    var lastWeekUsage: DailyUsage?
    var placeholderDate: Date?
    var isMissedDay = false
    
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
    
    init(dailyUsageData: DailyUsageData, usage: DailyUsage, lastWeekUsage: DailyUsage?, canCollect: Bool) {
        super.init(frame: CGRect(x: 0, y: 0, width: 36, height: 56))
        
        self.dailyUsageData = dailyUsageData
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
    
    init(placeholderViewForDate date: Date, isMissedDay: Bool) {
        super.init(frame: CGRect(x: 0, y: 0, width: 36, height: 56))
        
        self.placeholderDate = date
        self.isMissedDay = isMissedDay
        
        commonInit()
        
        weekdayLabel.text = date.weekday.abbreviationString
        imageView.image = isMissedDay ? #imageLiteral(resourceName: "ic_nodata.pdf") : nil
        
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
            FirebaseUtility.logEventV2(.gamification(parameters: [.coin_tapped]))
            
            canCollect = false
            imageView.image = lastWeekComparisionImage
            
            let decreasedUsage = lastWeekComparisionImage == #imageLiteral(resourceName: "ic_trenddown.pdf")
            if decreasedUsage {
                let coinAnimation = AnimationView(name: "coin_bonus_point")
                coinAnimation.frame.size = lottieView.frame.size
                coinAnimation.contentMode = .scaleAspectFit
                lottieView.addSubview(coinAnimation)
                coinAnimation.play()
            }
            
            delegate?.dailyInsightCoinView(self, wasTappedWithCoinCollected: true, decreasedUsage: decreasedUsage)
        } else {
            delegate?.dailyInsightCoinView(self, wasTappedWithCoinCollected: false, decreasedUsage: false)
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
        let diffThreshold = dailyUsageData?.unit == "kWh" ? 0.5 : 0.1
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
            return String.localizedStringWithFormat("You used %@ %@.", thisWeek.amount.twoDecimalString, dailyUsageData?.unit ?? "kWh")
        }
        
        // No data - placeholder view
        guard let thisWeek = usage, let lastWeek = lastWeekUsage else {
            return isMissedDay ?
                NSLocalizedString("Unable to retrieve data for this day. Check out the Usage section for more data about your energy consumption.", comment: "") :
                NSLocalizedString("Smart meter data is typically available within 24-48 hours of your usage. Check back later!", comment: "")
        }
        
        let diff = abs(thisWeek.amount - lastWeek.amount)
        let diffThreshold = dailyUsageData?.unit == "kWh" ? 0.5 : 0.1
        if diff <= diffThreshold {
            return String.localizedStringWithFormat("You used %@ %@ which was about the same as last week.", thisWeek.amount.twoDecimalString, dailyUsageData?.unit ?? "kWh")
        } else {
            if thisWeek.amount > lastWeek.amount {
                return String.localizedStringWithFormat("You used %@ %@ which was %@ %@ more than last week.",
                                                        thisWeek.amount.twoDecimalString, dailyUsageData?.unit ?? "kWh", diff.twoDecimalString, dailyUsageData?.unit ?? "kWh")
            } else {
                return String.localizedStringWithFormat("You used %@ %@ which was %@ %@ less than last week.",
                    thisWeek.amount.twoDecimalString, dailyUsageData?.unit ?? "kWh", diff.twoDecimalString, dailyUsageData?.unit ?? "kWh")
            }
        }
    }
    
}
