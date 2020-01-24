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
    
    @IBOutlet weak var pointEarnView: UIView!
    @IBOutlet weak var pointEarnLabel: UILabel!
    
    @IBOutlet weak var dailyInsightCardView: UIView!
    @IBOutlet weak var dailyInsightLabel: UILabel!
    @IBOutlet weak var streakButton: ButtonControl!
    @IBOutlet weak var streakLabel: UILabel!
    
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
    var loadedInitialGameUser = false
    var didGoToHomeProfile = false
    var viewDidAppear = false
    
    var pointEarnAnimator: UIViewPropertyAnimator?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FirebaseUtility.trackScreenWithName(self.className, className: self.className)
                                
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        scrollView!.alwaysBounceVertical = false
        
        progressBar.instantiate()
        
        pointEarnView.layer.cornerRadius = 24
        pointEarnLabel.textColor = .successGreenText
        pointEarnLabel.font = SystemFont.semibold.of(size: 12)

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
        
        streakLabel.textColor = .actionBlue
        streakLabel.font = SystemFont.semibold.of(size: 13)
                
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
        
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.gameEnergyBuddyUpdatesAlertPreference) {
            enrollInWeeklyPushNotification()
        }
        
        viewModel.fetchData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !layoutSubviewsComplete {
            layoutSubviewsComplete = true
            
            energyBuddyView.layoutIfNeeded()
            energyBuddyView.playDefaultAnimations()
            
            progressBar.layoutIfNeeded()
            _ = progressBar.setPoints(viewModel.points, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        scrollView?.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        
        energyBuddyView.updateBuddy()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        FirebaseUtility.logEvent(.gamificationExperienceAccessed, customParameters: [
            "current_point_total": viewModel.points,
            "curr_streak": UserDefaults.standard.integer(forKey: UserDefaultKeys.gameStreakCount),
            "selected_bg": UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedBackground) ?? "none",
            "selected_hat": UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedHat) ?? "none",
            "selected_acc": UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedAccessory) ?? "none"
        ])

        if viewDidAppear { // Only do this on the 2nd `viewDidAppear` and beyond. The initial play is done in `viewDidLayoutSubviews`
            energyBuddyView.playDefaultAnimations()
        }
        
        if !welcomedUser {
            welcomedUser = true
            
            if GameTaskStore.shared.tryFabWentBackToGame {
                if loadedInitialGameUser {
                    GameTaskStore.shared.tryFabActivated = false
                    awardPoints(16, advanceTaskIndex: true, advanceTaskTimer: false)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    guard let self = self else { return }
                    self.energyBuddyView.playHappyAnimation()
                    self.energyBuddyView.showWelcomeMessage(isFirstTimeSeeingBuddy: self.viewModel.points == 0)
                }
            }
        }
        
        if didGoToHomeProfile {
            awardPoints(8, advanceTaskIndex: true)
            didGoToHomeProfile = false
        }
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tipId = appDelegate.tipIdWaitingToBeShown,
            let tip = GameTaskStore.shared.tipWithId(tipId) {
                let tipVc = GameTipViewController.create(withTip: tip)
                self.tabBarController?.present(tipVc, animated: true, completion: nil)
                appDelegate.tipIdWaitingToBeShown = nil
            }
        
        viewDidAppear = true
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        energyBuddyView.stopAnimations()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func willResignActive() {
        energyBuddyView.stopAnimations()
    }
    
    @objc private func didBecomeActive() {
       energyBuddyView.updateBuddy()
       energyBuddyView.playDefaultAnimations()
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

            self.viewModel.currentTaskIndex = gameUser.taskIndex
            
            // Reconcile points with what's on the server
            if self.viewModel.points != gameUser.points && self.viewModel.debouncedCoinQueue.isEmpty {
                _ = self.progressBar.setPoints(gameUser.points, animated: false)
                self.viewModel.points = gameUser.points
            }
            
            let numGiftsUnlocked = GiftInventory.shared.numGiftsUnlocked(forPointValue: gameUser.points)
            if numGiftsUnlocked > self.viewModel.numGiftsUnlocked {
                self.viewModel.numGiftsUnlocked = numGiftsUnlocked
                if let unlockedGift = GiftInventory.shared.lastUnlockedGift(forPointValue: gameUser.points) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        self.presentGift(unlockedGift)
                    }
                }
            }
            
            if GameTaskStore.shared.tryFabWentBackToGame {
                if self.viewDidAppear {
                    GameTaskStore.shared.tryFabActivated = false
                    self.awardPoints(16, advanceTaskIndex: true, advanceTaskTimer: false)
                }
            } else {
                self.checkForAvailableTask()
            }
            
            self.loadedInitialGameUser = true
        }).disposed(by: bag)
        
        viewModel.streakCount.asDriver().drive(onNext: { [weak self] count in
            if count == 7 { // Award 3 points, show the modal, and reset streak back to 1
                FirebaseUtility.logEvent(.gamification, parameters: [EventParameter(parameterName: .action, value: .seven_day_streak)])
                self?.awardPoints(3, advanceTaskIndex: false, advanceTaskTimer: false)
                self?.viewModel.streakCount.accept(1)
                UserDefaults.standard.set(1, forKey: UserDefaultKeys.gameStreakCount)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    let alert = InfoAlertController(title: NSLocalizedString("Keep it up!", comment: ""),
                                    message: NSLocalizedString("You’ve been more energy conscious by checking the app for 7 days in a row! You’ve received extra points as a reward!", comment: ""),
                                    icon: #imageLiteral(resourceName: "ic_energybuddy.pdf"))
                    self?.tabBarController?.present(alert, animated: true, completion: nil)
                }

            } else {
                self?.streakButton.isHidden = count == 1
                self?.streakLabel.text = "\(count)"
            }
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
        
        var matchFound = false // If we've already found a data point, that means any subsequent placeholder view is a missing data point
        var date = Calendar.current.startOfDay(for: Date.now) // Based on user's timezone so their current "today" is always displayed
        while coinViews.count < 7 {
            if let match = usageArray.filter({ Calendar.gmt.isDate($0.date, inSameDayAs: date) }).first {
                matchFound = true
                
                let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: date)!
                let lastWeekMatch = usageArray.filter({ Calendar.gmt.isDate($0.date, inSameDayAs: lastWeek) }).first

                let accountNumber = viewModel.accountDetail.value!.accountNumber
                let canCollect = viewModel.coreDataManager.getCollectedCoin(accountNumber: accountNumber, date: match.date, gas: viewModel.selectedSegmentIndex == 1) == nil

                let view = DailyInsightCoinView(usage: match, lastWeekUsage: lastWeekMatch, canCollect: canCollect)
                view.delegate = self
                coinViews.append(view)
            } else {
                let placeholderView = DailyInsightCoinView(placeholderViewForDate: date, isMissedDay: matchFound)
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
    
    private func enrollInWeeklyPushNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["game_weekly_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Lumi Misses You!"
        content.body = "Check out new data, tips, and insights to help you save energy and money."
        content.sound = UNNotificationSound.default
        
        if let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date.now) {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: weekFromNow)
            comps.hour = 19 // 7pm
            comps.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "game_weekly_reminder", content: content, trigger: trigger)
            notificationCenter.add(request)
        }

    }
    
    // MARK: - IBActions
    
    @objc func onPullToRefresh() {
        viewModel.fetchData(pullToRefresh: true)
    }
    
    @objc func onBuddyTap() {
        guard let task = viewModel.currentTask else {
            showEnergyBuddyTooltip()
            return
        }
        
        if task.type == .fab {
            let fabVc = GameTryFabViewController.create()
            self.tabBarController?.present(fabVc, animated: true, completion: nil)
        } else if task.type == .eBill || task.type == .homeProfile {
            let enrollVc = GameEnrollmentViewController.create(withTaskType: task.type)
            enrollVc.delegate = self
            self.tabBarController?.present(enrollVc, animated: true, completion: nil)
        } else if let survey = task.survey {
            let surveyVc = GameSurveyViewController.create(withSurvey: survey)
            surveyVc.delegate = self
            self.tabBarController?.present(surveyVc, animated: true, completion: nil)
        } else if let tip = task.tip {
            let tipVc = GameTipViewController.create(withTip: tip)
            tipVc.delegate = self
            self.tabBarController?.present(tipVc, animated: true, completion: nil)
        } else if let quiz = task.quiz {
            let quizVc = GameQuizViewController.create(withQuiz: quiz)
            quizVc.delegate = self
            self.tabBarController?.present(quizVc, animated: true, completion: nil)
        } else if task.type == .checkIn {
            let checkInVc = GameCheckInViewController.create()
            checkInVc.delegate = self
            self.tabBarController?.present(checkInVc, animated: true, completion: nil)
        }
    }
    
    @IBAction func onStreakButtonPress() {
        let alert = InfoAlertController(title: NSLocalizedString("Daily Streak Challenge!", comment: ""),
                                        message: NSLocalizedString("You can begin a streak by checking the app daily. Doing so will help you stay mindful of your daily usage. Every 7 days of maintaining the streak, you’ll receive extra points!", comment: ""),
                                        icon: #imageLiteral(resourceName: "ic_energybuddy.pdf"))
        self.tabBarController?.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onDailyInsightTooltipPress() {
        let alert = InfoAlertController(title: NSLocalizedString("Daily Insight", comment: ""),
                                        message: NSLocalizedString("Your daily usage will be compared to your previous week. Points for each day will be available for up to 7 days of data. Uncollected points for the days prior will be lost, so be sure to check at least once a week!\n\nSmart meter data is typically available within 24-48 hours of your usage.", comment: ""))
        self.tabBarController?.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func segmentValueChanged(_ sender: SegmentedControl) {
        FirebaseUtility.logEvent(.gamification, parameters: [EventParameter(parameterName: .action, value: .toggled_gas_elec)])
        viewModel.selectedSegmentIndex = sender.selectedIndex.value
        viewModel.fetchDailyUsage()
    }
    
    @IBAction func onViewedTipsPress() {
        performSegue(withIdentifier: "viewedTipsSegue", sender: nil)
    }
    
    @IBAction func onGiftsPress() {
        performSegue(withIdentifier: "giftSegue", sender: nil)
    }
    
    // MARK:-
    
    private func checkForAvailableTask() {
        if let lastTaskDate = UserDefaults.standard.object(forKey: UserDefaultKeys.gameLastTaskDate) as? Date {
            let daysSinceLastTask = abs(lastTaskDate.interval(ofComponent: .day, fromDate: Date.now, usingCalendar: Calendar.current))
            if daysSinceLastTask < 4 {
                viewModel.currentTask = nil
                return
            }
        }
        
        if let gameUser = viewModel.gameUser.value, let accountDetail = viewModel.accountDetail.value {
            while true {
                if let task = GameTaskStore.shared.tasks.get(at: viewModel.currentTaskIndex) {
                    if shouldFilterOutTask(task: task, gameUser: gameUser, accountDetail: accountDetail) {
                        viewModel.currentTaskIndex += 1
                    } else {
                        viewModel.currentTask = task
                        energyBuddyView.setTaskIndicator(task.type)
                        break
                    }
                } else {
                    break
                }
            }
        }
    }
    
    private func shouldFilterOutTask(task: GameTask, gameUser: GameUser, accountDetail: AccountDetail) -> Bool {
        if let survey = task.survey {
            if survey.surveyNumber == 1 && UserDefaults.standard.bool(forKey: UserDefaultKeys.gameSurvey1Complete) {
                return true
            }
            if survey.surveyNumber == 2 && UserDefaults.standard.bool(forKey: UserDefaultKeys.gameSurvey2Complete) {
                return true
            }
        }
        
        // eBill Enroll Task: Should filter out if already enrolled, or ineligible for enrollment
        if task.type == .eBill && (accountDetail.isEBillEnrollment || accountDetail.eBillEnrollStatus != .canEnroll) {
            return true
        }
                
        // Tip/Quiz will either be "RENT", "OWN" or "RENT/OWN". If user's rent/own onboarding response
        // is not contained in that string, task should be filtered out
        if let gameUserRentOrOwn = gameUser.onboardingRentOrOwnAnswer?.uppercased() {
            if let tip = task.tip, !tip.rentOrOwn.uppercased().contains(gameUserRentOrOwn) {
                return true
            }
            if let quiz = task.quiz, !quiz.rentOrOwn.uppercased().contains(gameUserRentOrOwn) {
                return true
            }
        }
        
        // Season will either be "WINTER", "SUMMER", or nil. Winter tips should only be displayed
        // in October - March, while Summer tips should only be displayed in April - September
        var taskSeason: String?
        if let tip = task.tip, let tipSeason = tip.season?.uppercased() {
            taskSeason = tipSeason
        } else if let quiz = task.quiz, let quizSeason = quiz.season?.uppercased() {
            taskSeason = quizSeason
        }
        if let season = taskSeason, let month = Calendar.current.dateComponents([.month], from: Date.now).month {
            if season == "SUMMER" && month >= 10 && month <= 3 { // October - March, filter out summer tips
                return true
            }
            if season == "WINTER" && month >= 4 && month <= 9 { // April - September, filter out winter tips
                return true
            }
        }
        
        return false
    }
    
    private func showEnergyBuddyTooltip() {
        FirebaseUtility.logEvent(.gamification, parameters: [EventParameter(parameterName: .action, value: .viewed_task_empty_state)])
        
        let message = NSMutableAttributedString(string: NSLocalizedString("I’m Lumi!\n\nI’m here to help you make small changes that lead to big impacts by giving you tips, challenges, and insights to help you lower your energy use.\n\nAlong the way, you’ll be awarded with points for checking your daily and weekly insights as well as any tips, quizzes, or other challenges I might have for you! With those points, you can unlock backgrounds, hats, and accessories.", comment: ""))
        if let taskTimeStr = viewModel.nextAvaiableTaskTimeString {
            let attrString = NSMutableAttributedString(string: "\n\n\(taskTimeStr)", attributes: [
                .foregroundColor: UIColor.primaryColor,
                .font: SystemFont.semibold.of(textStyle: .subheadline)
            ])
            message.append(attrString)
        }
        
        let alert = InfoAlertController(title: NSLocalizedString("Hello!", comment: ""),
                                        attributedMessage: message,
                                        icon: #imageLiteral(resourceName: "ic_energybuddy.pdf"))
        self.tabBarController?.present(alert, animated: true, completion: nil)
    }
    
    private func showGameCompletionPopup() {
        FirebaseUtility.logEvent(.gamification, parameters: [EventParameter(parameterName: .action, value: .final_gift_unlocked)])
        let alert = InfoAlertController(title: NSLocalizedString("You did it!", comment: ""),
                                        message: NSLocalizedString("Congratulations! You’ve unlocked all the gifts! Although you’ve reached the end for now, you can still earn points and complete any remaining tasks.", comment: ""),
                                        icon: #imageLiteral(resourceName: "ic_energybuddy.pdf"))
        self.tabBarController?.present(alert, animated: true, completion: nil)
    }
    
    private func awardPoints(_ points: Double, advanceTaskIndex: Bool = false, advanceTaskTimer: Bool = true) {
        let pointsAfter = self.viewModel.points + points
                
        // Animate the progress bar, making the buddy speak when it becomes half/full
        if let result = progressBar.setPoints(pointsAfter) {
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
        
        // Flash the points earned over the gift button
        let fadeOutAfter2Seconds = {
            self.pointEarnAnimator = UIViewPropertyAnimator(duration: 0.33, curve: .linear, animations: {
                self.pointEarnView.alpha = 0
            })
            self.pointEarnAnimator?.startAnimation(afterDelay: 2)
        }
        
        self.pointEarnLabel.text = "+ \(NSNumber(value: points).stringValue)"
        
        // If already playing (i.e. when collecting coins quickly), just keep delaying the fade out
        if pointEarnAnimator?.isRunning ?? false || pointEarnView.alpha > 0 {
            pointEarnAnimator?.stopAnimation(true)
            pointEarnView.alpha = 1
            fadeOutAfter2Seconds()
        } else {
            pointEarnAnimator?.stopAnimation(true)
            pointEarnAnimator = UIViewPropertyAnimator(duration: 0.33, curve: .linear, animations: {
                self.pointEarnView.alpha = 1
            })
            pointEarnAnimator?.addCompletion({ _ in
                fadeOutAfter2Seconds()
            })
            self.pointEarnAnimator?.startAnimation()
        }

        if advanceTaskIndex { // If advancing index, update index + points in the same request
            energyBuddyView.setTaskIndicator(nil)
            viewModel.currentTask = nil
            
            viewModel.currentTaskIndex += 1
            viewModel.updateGameUser(taskIndex: viewModel.currentTaskIndex, advanceTaskTimer: advanceTaskTimer, points: pointsAfter)
        } else { // If just points (collected coins), use the debounced point update
            viewModel.debouncedPoints.accept(pointsAfter)
        }
        
        self.viewModel.points = pointsAfter
    }
    
    private func presentGift(_ gift: Gift) {
        let rewardVc = GameRewardViewController.create(withGift: gift)
        rewardVc.delegate = self
        self.tabBarController?.present(rewardVc, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? LargeTitleNavigationController,
            let vc = nav.viewControllers.first as? WeeklyInsightViewController {
            vc.delegate = self
            vc.viewModel.accountDetail = viewModel.accountDetail.value!
        } else if let vc = segue.destination as? PaperlessEBillViewController {
            vc.delegate = self
            vc.accountDetail = viewModel.accountDetail.value!
        } else if let vc = segue.destination as? MyHomeProfileViewController {
            vc.accountDetail = viewModel.accountDetail.value!
            vc.didSaveHomeProfile
                .delay(0.5)
                .drive(onNext: { [weak self] in
                    self?.view.showToast(NSLocalizedString("Home profile updated", comment: ""))
                    self?.viewModel.updateGameUserAnalytic(forKey: "pilotHomeProfileCompletion")
                })
                .disposed(by: vc.disposeBag)
            didGoToHomeProfile = true
        }
    }

}

// MARK: - AccountPickerDelegate
extension GameHomeViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        let gameAccountNumber = UserDefaults.standard.string(forKey: UserDefaultKeys.gameAccountNumber)
        if AccountsStore.shared.currentAccount.accountNumber != gameAccountNumber {
            NotificationCenter.default.post(name: .gameSwitchToHomeView, object: nil)
        }
    }
}

// MARK: - DailyInsightCoinViewDelegate
extension GameHomeViewController: DailyInsightCoinViewDelegate {
    
    func dailyInsightCoinView(_ view: DailyInsightCoinView, wasTappedWithCoinCollected coinCollected: Bool, decreasedUsage: Bool) {
        viewModel.selectedCoinView.accept(view)
        if coinCollected {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Dual fuel customers get half the points here because they have twice as many coins!
            if viewModel.accountDetail.value!.serviceType?.uppercased() == "GAS/ELECTRIC" {
                awardPoints(decreasedUsage ? 1 : 0.5)
            } else {
                awardPoints(decreasedUsage ? 2 : 1)
            }
            
            let accountNumber = viewModel.accountDetail.value!.accountNumber
            let date = view.usage!.date
            let gas = viewModel.selectedSegmentIndex == 1
            
            viewModel.debouncedCoinQueue.append((date, gas))
            viewModel.coreDataManager.addCollectedCoin(accountNumber: accountNumber, date: date, gas: gas)
        } else {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - GameTipViewControllerDelegate
extension GameHomeViewController: GameTipViewControllerDelegate {
    
    func gameTipViewControllerWasDismissed(_ gameTipViewController: GameTipViewController, withQuizPoints quizPoints: Double) {
        if quizPoints > 0 { // Pressed "View Tip" after answering a quiz question
            awardPoints(quizPoints, advanceTaskIndex: true)
        } else {
            awardPoints(3, advanceTaskIndex: true)
        }
    }
}

// MARK: - GameQuizViewControllerDelegate
extension GameHomeViewController: GameQuizViewControllerDelegate {
    
    func gameQuizViewController(_ viewController: GameQuizViewController, wasDismissedWithCorrectAnswer correct: Bool) {
        awardPoints(correct ? 4 : 3, advanceTaskIndex: true)
    }
    
    func gameQuizViewController(_ viewController: GameQuizViewController, wantsToViewTipWithId tipId: String, withCorrectAnswer correct: Bool) {
        tabBarController?.dismiss(animated: true) {
            if let tip = GameTaskStore.shared.tipWithId(tipId) {
                let tipVc = GameTipViewController.create(withTip: tip, quizPoints: correct ? 4 : 3)
                tipVc.delegate = self
                self.tabBarController?.present(tipVc, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - GameRewardViewControllerDelegate
extension GameHomeViewController: GameRewardViewControllerDelegate {
    
    func gameRewardViewControllerShouldDismiss(_ gameRewardViewController: GameRewardViewController, didSetGift: Bool) {
        let gift = gameRewardViewController.gift!
        if didSetGift {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            energyBuddyView.updateBuddy()
            viewModel.updateGiftSelections()
        }
        tabBarController?.dismiss(animated: true) {
            if didSetGift {
                self.energyBuddyView.playSuperHappyAnimation(withSparkles: false, withHearts: true)
                self.energyBuddyView.showNewGiftAppliedMessage(forGift: gift)
            }
            
            if GiftInventory.shared.isFinalGift(gift: gift) {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    self.energyBuddyView.playConfettiAnimation()
                    self.showGameCompletionPopup()
                }
            }
        }
    }
}

// MARK: - GameEnrollmentViewControllerDelegate
extension GameHomeViewController: GameEnrollmentViewControllerDelegate {
    
    func gameEnrollmentViewControllerDidPressCTA(_ gameEnrollmentViewController: GameEnrollmentViewController) {
        tabBarController?.dismiss(animated: true) {
            if gameEnrollmentViewController.taskType == .eBill {
                self.performSegue(withIdentifier: "eBillSegue", sender: nil)
            } else { // Home Profile
                self.performSegue(withIdentifier: "homeProfileSegue", sender: nil)
            }
        }
    }
    
    func gameEnrollmentViewControllerDidPressNotInterested(_ gameEnrollmentViewController: GameEnrollmentViewController) {
        tabBarController?.dismiss(animated: true, completion: nil)
        
        energyBuddyView.setTaskIndicator(nil)
        viewModel.currentTask = nil
        
        viewModel.currentTaskIndex += 1
        viewModel.updateGameUser(taskIndex: viewModel.currentTaskIndex, advanceTaskTimer: true)
    }
}

// MARK: - PaperlessEBillViewControllerDelegate
extension GameHomeViewController: PaperlessEBillViewControllerDelegate {
    
    func paperlessEBillViewController(_ paperlessEBillViewController: PaperlessEBillViewController, didChangeStatus: PaperlessEBillChangedStatus) {
        if didChangeStatus == .enroll {
            viewModel.updateGameUserAnalytic(forKey: "pilotEBillEnrollment")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.view.showToast(NSLocalizedString("Enrolled in Paperless eBill", comment: ""))
                self.awardPoints(8, advanceTaskIndex: true)
            })
        }
    }
}

// MARK: - GameSurveyViewControllerDelegate
extension GameHomeViewController: GameSurveyViewControllerDelegate {
    
    func gameSurveyViewControllerDidFinish(_ viewController: GameSurveyViewController, surveyComplete: Bool) {
        if surveyComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.awardPoints(16, advanceTaskIndex: true, advanceTaskTimer: false)
            })
        } else {
            energyBuddyView.setTaskIndicator(nil)
            viewModel.currentTask = nil
            
            viewModel.currentTaskIndex += 1
            viewModel.updateGameUser(taskIndex: viewModel.currentTaskIndex, advanceTaskTimer: false)
        }
    }
}

// MARK: - GameCheckInViewControllerDelegate
extension GameHomeViewController: GameCheckInViewControllerDelegate {
    
    func gameCheckInViewController(_ gameCheckInViewController: GameCheckInViewController, selectedResponse: String) {
        energyBuddyView.setTaskIndicator(nil)
        viewModel.currentTask = nil
        
        viewModel.currentTaskIndex += 1
        viewModel.updateGameUserCheckInResponse(response: selectedResponse, taskIndex: viewModel.currentTaskIndex)
    }
    
    func gameCheckInViewControllerSelectedNotInterested(_ gameCheckInViewController: GameCheckInViewController) {
        energyBuddyView.setTaskIndicator(nil)
        viewModel.currentTask = nil
        
        viewModel.currentTaskIndex += 1
        viewModel.updateGameUser(taskIndex: viewModel.currentTaskIndex, advanceTaskTimer: false)
    }
}

// MARK: - WeeklyInsightViewControllerDelegate
extension GameHomeViewController: WeeklyInsightViewControllerDelegate {
    
    func weeklyInsightViewControllerWillDisappear(_ weeklyInsightViewController: WeeklyInsightViewController) {
        scrollView?.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    func weeklyInsightViewController(_ weeklyInsightViewController: WeeklyInsightViewController, wasDismissedAfterViewingUnread viewedUnread: Bool) {
        if viewedUnread {
            viewModel.weeklyInsightPublishSubject.onNext(())
            awardPoints(3)
        }
    }
}
