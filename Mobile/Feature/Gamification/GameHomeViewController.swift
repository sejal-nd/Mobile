//
//  GameHomeViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 10/29/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GameHomeViewController: AccountPickerViewController {
            
    @IBOutlet weak var energyBuddyView: EnergyBuddyView!
    
    @IBOutlet weak var dailyInsightCardView: UIView!
    @IBOutlet weak var dailyInsightLabel: UILabel!
    
    @IBOutlet weak var dailyInsightContentView: UIView!
    @IBOutlet weak var coinStack: UIStackView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var bubbleLabel: UILabel!
    @IBOutlet weak var bubbleTriangleImageView: UIImageView!
    @IBOutlet weak var bubbleTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var loadingView: UIView!
    
    private var coinViews = [DailyInsightCoinView]()
    
    let viewModel = GameHomeViewModel(accountService: ServiceFactory.createAccountService(),
                                      gameService: ServiceFactory.createGameService())

    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.energyBuddyView.stopAnimations()
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                self?.energyBuddyView.updateSky()
                self?.energyBuddyView.playDefaultAnimations()
                self?.energyBuddyView.bounce()
            })
            .disposed(by: bag)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self

        dailyInsightCardView.layer.cornerRadius = 10
        dailyInsightCardView.layer.borderColor = UIColor.accentGray.cgColor
        dailyInsightCardView.layer.borderWidth = 1
        dailyInsightCardView.layer.masksToBounds = false
        
        dailyInsightLabel.textColor = .deepGray
        dailyInsightLabel.font = OpenSans.regular.of(textStyle: .headline)
        dailyInsightLabel.text = NSLocalizedString("Daily Insight", comment: "")
                
        bubbleView.layer.borderColor = UIColor.accentGray.cgColor
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.cornerRadius = 10
        bubbleLabel.textColor = .deepGray
        bubbleLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        energyBuddyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBuddyTap)))
        
        energyBuddyView.bounce()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.energyBuddyView.playHappyAnimation()
            self?.energyBuddyView.showWelcomeMessage()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let rightMostCoinView = coinViews.last {
            bubbleTriangleCenterXConstraint.isActive = false
            bubbleTriangleCenterXConstraint = bubbleTriangleImageView.centerXAnchor.constraint(equalTo: rightMostCoinView.centerXAnchor)
            bubbleTriangleCenterXConstraint.isActive = true
        }
    }
    
    private func bindViewModel() {
        viewModel.loading.asDriver().not().drive(loadingView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowContent.not().drive(dailyInsightContentView.rx.isHidden).disposed(by: bag)
        
        viewModel.usageData.asDriver().drive(onNext: { [weak self] array in
            guard let usageArray = array, usageArray.count > 0 else { return }
            self?.layoutCoinViews(usageArray: usageArray)
        }).disposed(by: bag)
        
        viewModel.selectedCoinView.asDriver().drive(onNext: { [weak self] coinView in
            guard let self = self, let selectedCoinView = coinView else { return }
            
            self.bubbleTriangleCenterXConstraint.isActive = false
            self.bubbleTriangleCenterXConstraint = self.bubbleTriangleImageView.centerXAnchor.constraint(equalTo: selectedCoinView.centerXAnchor)
            self.bubbleTriangleCenterXConstraint.isActive = true
        }).disposed(by: bag)
    }
    
    func layoutCoinViews(usageArray: [DailyUsage]) {
        coinStack.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        coinViews.removeAll()
        
        let dataCount = min(usageArray.count, 7)
        for i in 0..<dataCount {
            let data = usageArray[i]
            var lastWeekData: DailyUsage?
            if usageArray.count > i + 7 {
                lastWeekData = usageArray[i + 7]
            }
            
            //let canCollect = coreDataManager.getDay(accountNumber: accountNumber!, data: electricData) == nil
            
            let view = DailyInsightCoinView(usage: data, lastWeekUsage: lastWeekData, canCollect: true)
            view.delegate = self
            coinViews.append(view)
        }
        coinViews.reverse() // Views are now oldest to most recent
        
        // Fill in "placeholder" views if there are any days without data between now and the first data point
        let mostRecentDataPoint = usageArray.first!
        let startOfToday = Calendar.current.startOfDay(for: Date()) // Based on user's timezone so their current "today" is always displayed
        let daysApart = abs(mostRecentDataPoint.date.interval(ofComponent: .day, fromDate: startOfToday, usingCalendar: .gmt))
        //print("daysApart = \(daysApart)")
        for i in 1...daysApart {
            guard let nextDay = Calendar.gmt.date(byAdding: .day, value: i, to: mostRecentDataPoint.date) else { continue }
            let placeholderView = DailyInsightCoinView(placeholderViewForDate: nextDay)
            placeholderView.delegate = self
            coinViews.append(placeholderView)
        }
        
        coinViews.removeFirst(coinViews.count - 7)
        coinViews.forEach {
            coinStack.addArrangedSubview($0)
        }
        dailyInsightCoinView(coinViews.last!, wasTappedWithCoinCollected: false)
    }
    
    @objc func onBuddyTap() {
        //energyBuddyView.playHappyAnimation()
        //energyBuddyView.playSuperHappyAnimation()
        energyBuddyView.playSuperHappyAnimation(withSparkles: true)
        //energyBuddyView.playSuperHappyAnimation(withHearts: true)
    }
    

}

extension GameHomeViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchData()
    }
}

extension GameHomeViewController: DailyInsightCoinViewTapDelegate {
    
    func dailyInsightCoinView(_ view: DailyInsightCoinView, wasTappedWithCoinCollected coinCollected: Bool) {
        viewModel.selectedCoinView.accept(view)
    }
}
