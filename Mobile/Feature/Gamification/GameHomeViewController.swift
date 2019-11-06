//
//  GameHomeViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/29/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GameHomeViewController: UIViewController {
        
    @IBOutlet weak var energyBuddyTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var energyBuddyImageView: UIImageView!
    
    @IBOutlet weak var dailyInsightCardView: UIView!
    @IBOutlet weak var dailyInsightLabel: UILabel!
    
    @IBOutlet weak var coinStack: UIStackView!
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var bubbleLabel: UILabel!
    @IBOutlet weak var bubbleTriangleImageView: UIImageView!
    @IBOutlet weak var bubbleTriangleCenterXConstraint: NSLayoutConstraint!
    
    private var coinViews = [DailyInsightCoinView]()

    override func viewDidLoad() {
        super.viewDidLoad()

        dailyInsightCardView.layer.cornerRadius = 10
        dailyInsightCardView.layer.borderColor = UIColor.accentGray.cgColor
        dailyInsightCardView.layer.borderWidth = 1
        dailyInsightCardView.layer.masksToBounds = false
        
        dailyInsightLabel.textColor = .deepGray
        dailyInsightLabel.font = OpenSans.regular.of(textStyle: .headline)
        dailyInsightLabel.text = NSLocalizedString("Daily Insight", comment: "")
        
        coinStack.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        var viewArray = [DailyInsightCoinView]()
        for _ in 0..<7 {
            let view = DailyInsightCoinView(placeholderViewForDate: Date())
            view.delegate = self
            viewArray.append(view)
        }
        
        viewArray.forEach {
            coinViews.append($0)
            coinStack.addArrangedSubview($0)
        }
        
        bubbleView.layer.borderColor = UIColor.accentGray.cgColor
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.cornerRadius = 10
        bubbleLabel.textColor = .deepGray
        bubbleLabel.font = SystemFont.regular.of(textStyle: .footnote)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.layoutIfNeeded()
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.energyBuddyTopConstraint.constant = 25
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let rightMostCoinView = coinViews.last {
            bubbleTriangleCenterXConstraint.isActive = false
            bubbleTriangleCenterXConstraint = bubbleTriangleImageView.centerXAnchor.constraint(equalTo: rightMostCoinView.centerXAnchor)
            bubbleTriangleCenterXConstraint.isActive = true
        }
    }
    

}

extension GameHomeViewController: DailyInsightCoinViewTapDelegate {
    
    func dailyInsightCoinView(_ view: DailyInsightCoinView, wasTappedWithCoinCollected coinCollected: Bool) {
        print(view.frame.origin.x)
        bubbleTriangleCenterXConstraint.isActive = false
        bubbleTriangleCenterXConstraint = bubbleTriangleImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        bubbleTriangleCenterXConstraint.isActive = true
    }
}
