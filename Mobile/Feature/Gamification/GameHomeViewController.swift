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
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self

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
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
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
        
        viewModel.usageData.asDriver().drive(onNext: { usageArray in
            print(usageArray)
        }).disposed(by: bag)
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
        print(view.frame.origin.x)
        bubbleTriangleCenterXConstraint.isActive = false
        bubbleTriangleCenterXConstraint = bubbleTriangleImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        bubbleTriangleCenterXConstraint.isActive = true
    }
}
