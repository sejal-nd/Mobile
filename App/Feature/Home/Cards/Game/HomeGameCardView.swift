//
//  HomeGameCardView.swift
//  EUMobile
//
//  Created by Cody Dillon on 11/19/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation
import RxSwift

class HomeGameCardView: UIView {
    
    @IBOutlet private weak var clippingView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var tasksView: UIStackView!
    @IBOutlet private weak var contentChip: UILabel!
    @IBOutlet private weak var insightCip: UILabel!
    @IBOutlet weak var lumiButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    
    var taskType: GameTaskType? = nil
    var isInsightAvailable = false
    
    var viewModel: GameHomeViewModel = GameHomeViewModel()
    let disposeBag = DisposeBag()
    
    static func create(withViewModel viewModel: GameHomeViewModel) -> HomeGameCardView {
        let view = Bundle.main.loadViewFromNib() as HomeGameCardView
        view.viewModel = viewModel
        view.setup()
        return view
    }
    
    func setup() {
        viewModel.fetchData()
        viewModel.hasInsightsAvailable().drive(onNext: {
            self.insightCip.isHidden = !$0
        }).disposed(by: disposeBag)
        
        viewModel.gameUser.subscribe(onNext: {
            if $0 != nil {
                self.viewModel.currentTaskIndex = self.viewModel.gameUser.value?.taskIndex ?? 0
                self.taskType = self.viewModel.checkForAvailableTask()?.type
                self.styleViews()
            }
        }).disposed(by: disposeBag)
        
        viewModel.loading.not().bind(to: loadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.loading.bind(to: contentStackView.rx.isHidden).disposed(by: disposeBag)
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
//            contentView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            self.layoutIfNeeded()
            
            contentChip.isHidden = true
            insightCip.isHidden = true
            detailLabel.text = viewModel.nextAvaiableTaskTimeString
            
            return
        }
        
        contentChip.isHidden = taskType == nil
        insightCip.isHidden = !isInsightAvailable
        
        heightAnchor.constraint(equalToConstant: 164).isActive = true
//        contentView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
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
        contentChip.fullyRoundCorners(diameter: 20.0, borderColor: .primaryColor, borderWidth: 1.0)
        contentChip.textColor = .primaryColor
        
        insightCip.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        insightCip.fullyRoundCorners(diameter: 20.0, borderColor: .primaryColor, borderWidth: 1.0)
        insightCip.textColor = .primaryColor
    }
    
    
}
