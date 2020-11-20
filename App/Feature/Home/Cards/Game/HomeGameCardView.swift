//
//  HomeGameCardView.swift
//  EUMobile
//
//  Created by Cody Dillon on 11/19/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

class HomeGameCardView: UIView {
    
    @IBOutlet private weak var clippingView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var tasksView: UIStackView!
    @IBOutlet private weak var contentChip: UILabel!
    @IBOutlet private weak var insightCip: UILabel!
    @IBOutlet weak var lumiButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    
    var gameUser: GameUser!
    var accountDetail: AccountDetail!
    
    var currentTaskIndex = -1
    var taskType: GameTaskType? = nil
    var isInsightAvailable = false
    
    static func create(gameUser: GameUser, accountDetail: AccountDetail) -> HomeGameCardView {
        let view = Bundle.main.loadViewFromNib() as HomeGameCardView
        view.gameUser = gameUser
        view.accountDetail = accountDetail
        view.currentTaskIndex = gameUser.taskIndex
        view.taskType = view.checkForAvailableTask()?.type
        view.styleViews()
                
        return view
    }
    
    func styleViews() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.accentGray.cgColor
        layer.borderWidth = 1
        clippingView.layer.cornerRadius = 10
        clippingView.heightAnchor.constraint(equalToConstant: 164.0).isActive = true
        
        titleLabel.textColor = .deepGray
        detailLabel.textColor = .deepGray
        detailLabel.font = SystemFont.regular.of(textStyle: .footnote)
        
        styleContentChips()
    }
    
    func styleContentChips() {
        if taskType == nil && !isInsightAvailable {
            tasksView.isHidden = true
            heightAnchor.constraint(equalToConstant: 164).isActive = true
            contentView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            self.layoutIfNeeded()
            
            detailLabel.text = nextAvaiableTaskTimeString
            
            return
        } else if taskType == nil {
            contentChip.isHidden = true
        } else if !isInsightAvailable {
            insightCip.isHidden = true
        }
        
        heightAnchor.constraint(equalToConstant: 164).isActive = true
        contentView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        detailLabel.text = NSLocalizedString("New content available!", comment: "")
        
        let contentWidth: CGFloat
        
        switch taskType {
        case .tip:
            contentWidth = 38
        case .quiz:
            contentWidth = 44
        default:
            contentWidth = 44
        }
        
        contentChip.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        contentChip.fullyRoundCorners(diameter: contentWidth, borderColor: .primaryColor, borderWidth: 1.0)
        contentChip.textColor = .primaryColor
        
        insightCip.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        insightCip.fullyRoundCorners(diameter: 60.0, borderColor: .primaryColor, borderWidth: 1.0)
        insightCip.textColor = .primaryColor
    }
    
    private func checkForAvailableTask() -> GameTask? {
        if let lastTaskDate = UserDefaults.standard.object(forKey: UserDefaultKeys.gameLastTaskDate) as? Date {
            let daysSinceLastTask = abs(lastTaskDate.interval(ofComponent: .day, fromDate: Date.now, usingCalendar: Calendar.current))
            if daysSinceLastTask < 4 {
                return nil
            }
        }
        
        while true {
            if let task = GameTaskStore.shared.tasks.get(at: currentTaskIndex) {
                if shouldFilterOutTask(task: task, gameUser: gameUser, accountDetail: accountDetail) {
                    self.currentTaskIndex += 1
                } else {
                    return task
                }
            } else {
                break
            }
        }
        
        return nil
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
    
    var nextAvaiableTaskTimeString: String? {
        if currentTaskIndex >= GameTaskStore.shared.tasks.count {
            return nil
        }
        
        if let lastTaskDate = UserDefaults.standard.object(forKey: UserDefaultKeys.gameLastTaskDate) as? Date,
            let nextTaskDate = Calendar.current.date(byAdding: .day, value: 4, to: lastTaskDate) {
            let interval = Int(nextTaskDate.timeIntervalSinceNow)
            let days = interval / 86400
            let hours = (interval % 86400) / 3600
            let minutes = ((interval % 86400) % 3600) / 60

            var timeString = ""
            if days > 0 {
                timeString += "\(days) \(days == 1 ? "day" : "days")"
                if hours > 0 {
                    timeString += " and \(hours) \(hours == 1 ? "hour" : "hours")"
                }
                return "Check back in \(timeString) for your next challenge!"
            }
            if hours > 0 {
                timeString += "\(hours) \(hours == 1 ? "hour" : "hours")"
                if minutes > 0 {
                    timeString += " and \(minutes) \(minutes == 1 ? "minute" : "minutes")"
                }
                return "Check back in \(timeString) for your next challenge!"
            }
            if minutes > 0 {
                timeString += "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
                return "Check back in \(timeString) for your next challenge!"
            }

            return "Check back soon for your next challenge!"
        }
        
        return nil
    }
}
