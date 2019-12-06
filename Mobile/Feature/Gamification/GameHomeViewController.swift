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
    
    @IBOutlet weak var progressBar: GameProgressBar!
    
    @IBOutlet weak var dailyInsightCardView: UIView!
    @IBOutlet weak var dailyInsightLabel: UILabel!
    
    @IBOutlet weak var segmentedControlContainer: UIView!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    @IBOutlet weak var dailyInsightContentView: UIView!
    @IBOutlet weak var coinStack: UIStackView!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var bubbleLabel: UILabel!
    @IBOutlet weak var bubbleTriangleImageView: UIImageView!
    @IBOutlet weak var bubbleTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var weeklyInsightUnreadIndicator: UIView!
    @IBOutlet weak var weeklyInsightButton: UIButton!
    
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var coinViews = [DailyInsightCoinView]()
    
    private var refreshControl: UIRefreshControl?
    
    let viewModel = GameHomeViewModel(accountService: ServiceFactory.createAccountService(),
                                      gameService: ServiceFactory.createGameService())

    let bag = DisposeBag()
    
    var layoutSubviewsComplete = false
    var welcomedUser = false
    
    var points: Int {
        get {
            return UserDefaults.standard.integer(forKey: UserDefaultKeys.gamePointsLocal)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.gamePointsLocal)
        }
    }
    
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
            })
            .disposed(by: bag)
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        scrollView!.alwaysBounceVertical = false
        
        progressBar.instantiate()

        dailyInsightCardView.layer.cornerRadius = 10
        dailyInsightCardView.layer.borderColor = UIColor.accentGray.cgColor
        dailyInsightCardView.layer.borderWidth = 1
        dailyInsightCardView.layer.masksToBounds = true
        
        segmentedControl.items = [
            NSLocalizedString("Electric", comment: ""),
            NSLocalizedString("Gas", comment: "")
        ]
        segmentedControlContainer.isHidden = true
        
        dailyInsightLabel.textColor = .deepGray
        dailyInsightLabel.font = OpenSans.regular.of(textStyle: .headline)
        dailyInsightLabel.text = NSLocalizedString("Daily Insight", comment: "")
                
        bubbleView.layer.borderColor = UIColor.accentGray.cgColor
        bubbleView.layer.borderWidth = 1
        bubbleView.layer.cornerRadius = 10
        bubbleLabel.textColor = .deepGray
        bubbleLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        weeklyInsightUnreadIndicator.layer.cornerRadius = 6
        weeklyInsightUnreadIndicator.backgroundColor = .successGreen
        
        weeklyInsightButton.setTitleColor(.actionBlue, for: .normal)
        weeklyInsightButton.titleLabel?.font = SystemFont.semibold.of(textStyle: .headline)
        
        errorLabel.textColor = .deepGray
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    
        energyBuddyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBuddyTap)))
        
        bindViewModel()
        
        viewModel.fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        if layoutSubviewsComplete {
            // Resume animations that paused when switching tabs
            energyBuddyView.playDefaultAnimations()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        if !welcomedUser {
            welcomedUser = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                self?.energyBuddyView.playHappyAnimation()
                self?.energyBuddyView.showWelcomeMessage()
            }
        }
        
        _ = progressBar.setPoints(points, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !layoutSubviewsComplete {
            layoutSubviewsComplete = true
            energyBuddyView.playDefaultAnimations()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        energyBuddyView.stopAnimations()
    }
    
    private func bindViewModel() {
        viewModel.loading.asDriver().drive(onNext: { [weak self] loading in
            guard let self = self else { return }
            self.loadingView.isHidden = !loading
            if !loading {
                guard self.refreshControl == nil else { return }
                self.refreshControl = UIRefreshControl()
                self.refreshControl!.addTarget(self, action: #selector(self.onPullToRefresh), for: .valueChanged)
                self.scrollView!.insertSubview(self.refreshControl!, at: 0)
                self.scrollView!.alwaysBounceVertical = true
            }
        }).disposed(by: bag)
        viewModel.refreshing.asDriver().drive(onNext: { [weak self] refreshing in
            if !refreshing {
                self?.refreshControl?.endRefreshing()
            }
        }).disposed(by: bag)
        viewModel.shouldShowError.not().drive(errorView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowContent.not().drive(dailyInsightContentView.rx.isHidden).disposed(by: bag)
        viewModel.shouldShowSegmentedControl.not().drive(segmentedControlContainer.rx.isHidden).disposed(by: bag)
        
        viewModel.gameUser.asDriver().drive(onNext: { [weak self] user in
            guard let self = self, let gameUser = user else { return }
   
            if let unlockedGift = GiftInventory.shared.giftUnlockedWhen(pointsBefore: self.points, pointsAfter: gameUser.points) {
                self.presentGift(unlockedGift)
            }
            self.points = gameUser.points
            _ = self.progressBar.setPoints(self.points, animated: false)
        }).disposed(by: bag)
        
        viewModel.usageData.asDriver().drive(onNext: { [weak self] array in
            guard let usageArray = array, usageArray.count > 0 else { return }
            self?.layoutCoinViews(usageArray: usageArray)
        }).disposed(by: bag)
        
        viewModel.selectedCoinView.asDriver().drive(onNext: { [weak self] coinView in
            guard let self = self, let selectedCoinView = coinView else { return }
            self.bubbleTriangleCenterXConstraint?.isActive = false
            self.bubbleTriangleCenterXConstraint = self.bubbleTriangleImageView.centerXAnchor.constraint(equalTo: selectedCoinView.centerXAnchor)
            self.bubbleTriangleCenterXConstraint.isActive = true
        }).disposed(by: bag)
        
        viewModel.bubbleLabelText.drive(bubbleLabel.rx.text).disposed(by: bag)
        
        viewModel.shouldShowWeeklyInsightUnreadIndicator.not().drive(weeklyInsightUnreadIndicator.rx.isHidden).disposed(by: bag)
    }
    
    func layoutCoinViews(usageArray: [DailyUsage]) {
        coinStack.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        coinViews.removeAll()
        
        var date = Calendar.current.startOfDay(for: Date()) // Based on user's timezone so their current "today" is always displayed
        while coinViews.count < 7 {
            if let match = usageArray.filter({ Calendar.gmt.isDate($0.date, inSameDayAs: date) }).first {
                let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: date)!
                let lastWeekMatch = usageArray.filter({ Calendar.gmt.isDate($0.date, inSameDayAs: lastWeek) }).first

                let accountNumber = viewModel.accountDetail.value!.accountNumber
                let canCollect = viewModel.coreDataManager.getCollectedCoin(accountNumber: accountNumber, date: match.date, gas: viewModel.selectedSegmentIndex == 1) == nil

                let view = DailyInsightCoinView(usage: match, lastWeekUsage: lastWeekMatch, canCollect: canCollect)
                view.delegate = self
                coinViews.append(view)
            } else {
                let placeholderView = DailyInsightCoinView(placeholderViewForDate: date)
                placeholderView.delegate = self
                coinViews.append(placeholderView)
            }
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        coinViews.reverse() // Views are now oldest to most recent

        coinViews.forEach {
            coinStack.addArrangedSubview($0)
        }
        dailyInsightCoinView(coinViews.last!, wasTappedWithCoinCollected: false, decreasedUsage: false)
    }
    
    @objc func onPullToRefresh() {
        viewModel.fetchData(pullToRefresh: true)
    }
    
    @objc func onBuddyTap() {
//        showEnergyBuddyTooltip()
        
//        energyBuddyView.playHappyAnimation()
//        energyBuddyView.playSuperHappyAnimation()
//        energyBuddyView.playSuperHappyAnimation(withSparkles: true)
//        energyBuddyView.playSuperHappyAnimation(withHearts: true)
        
//        let tipVc = GameTipViewController.create()
//        self.tabBarController?.present(tipVc, animated: true, completion: nil)
        
        let quiz = GameQuiz(
            question: "Which appliance do you think uses the most energy?",
            answers: [
                ["answer": "TV", "correct": false],
                ["answer": "Dishwasher", "correct": false],
                ["answer": "Dryer", "correct": true]
            ],
            answerDescription: "Clothes dryers use more energy than any other appliance."
        )
        let quizVc = GameQuizViewController.create(withQuiz: quiz)
        quizVc.delegate = self
        self.tabBarController?.present(quizVc, animated: true, completion: nil)
    }
    
    @IBAction func onDailyInsightTooltipPress() {
        let alert = InfoAlertController(title: NSLocalizedString("Daily Insight", comment: ""),
                                        message: NSLocalizedString("Your daily usage will be compared to your previous week. Points for each day will be available for up to 7 days of data. Uncollected points for the days prior will be lost, so be sure to check at least once a week!\n\nSmart meter data is typically available within 24-48 hours of your usage.", comment: ""),
                                        action: nil)
        self.tabBarController?.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func segmentValueChanged(_ sender: SegmentedControl) {
        viewModel.selectedSegmentIndex = sender.selectedIndex.value
        viewModel.fetchDailyUsage()
    }
    
    @IBAction func onViewedTipsPress() {
        performSegue(withIdentifier: "viewedTipsSegue", sender: nil)
    }
    
    @IBAction func onGiftsPress() {
        performSegue(withIdentifier: "giftSegue", sender: nil)
    }
    
    private func showEnergyBuddyTooltip() {
        let alert = InfoAlertController(title: NSLocalizedString("Energy Buddy", comment: ""),
                                        message: NSLocalizedString("Your Energy Buddy will teach you how to make small changes that lead to big impacts.\n\nNew backgrounds or accessories for the Energy Buddy may be earned by collecting your daily insight points, viewing weekly insights, and viewing tips.", comment: ""),
                                        action: nil)
        self.tabBarController?.present(alert, animated: true, completion: nil)
    }
    
    private func presentGift(_ gift: Gift) {
        let rewardVc = GameRewardViewController.create(withGift: gift)
        rewardVc.setItemCallback = {
            self.tabBarController?.dismiss(animated: true, completion: nil)
        }
        self.tabBarController?.present(rewardVc, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? LargeTitleNavigationController,
            let vc = nav.viewControllers.first as? WeeklyInsightViewController {
            vc.viewModel.accountDetail = viewModel.accountDetail.value!
            vc.updateUnreadIndicator = viewModel.weeklyInsightPublishSubject
        }
    }

}

extension GameHomeViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        let gameAccountNumber = UserDefaults.standard.string(forKey: UserDefaultKeys.gameAccountNumber)
        if AccountsStore.shared.currentAccount.accountNumber != gameAccountNumber {
            NotificationCenter.default.post(name: .gameSwitchToHomeView, object: nil)
        }
    }
}

extension GameHomeViewController: DailyInsightCoinViewDelegate {
    
    func dailyInsightCoinView(_ view: DailyInsightCoinView, wasTappedWithCoinCollected coinCollected: Bool, decreasedUsage: Bool) {
        viewModel.selectedCoinView.accept(view)
        if coinCollected {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            let newPoints = points + (decreasedUsage ? 2 : 1)
                
            if let result = progressBar.setPoints(newPoints) {
                if result == .halfWay {
                    energyBuddyView.playSuperHappyAnimation()
                    energyBuddyView.showHalfWayMessage()
                } else if result == .levelUp {
                    energyBuddyView.playSuperHappyAnimation(withSparkles: true)
                    energyBuddyView.showLevelUpMessage()
                }
            } else {
                energyBuddyView.playHappyAnimation()
            }
            
            viewModel.debouncedPoints.accept(newPoints)
            self.points = newPoints
            
            let accountNumber = viewModel.accountDetail.value!.accountNumber
            self.viewModel.coreDataManager.addCollectedCoin(accountNumber: accountNumber, date: view.usage!.date, gas: viewModel.selectedSegmentIndex == 1)
        } else {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

extension GameHomeViewController: GameQuizViewControllerDelegate {
    
    func gameQuizViewController(_ viewController: GameQuizViewController, wantsToViewTipWithId tipId: String) {
        tabBarController?.dismiss(animated: true) {
            // TODO: Present the real tip
            let tipVc = GameTipViewController.create()
            self.tabBarController?.present(tipVc, animated: true, completion: nil)
        }
    }
}
