//
//  StatusView.swift
//  EUMobile
//
//  Created by Gina Mullins on 12/3/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class StatusView: UIView {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var circleImageView: UIImageView!
    @IBOutlet private weak var barView: UIView!
    @IBOutlet private weak var statusTitleLabel: UILabel!
    @IBOutlet private weak var statusDateLabel: UILabel!
    @IBOutlet private weak var barWidthConstraint: NSLayoutConstraint!
    
    var trackerStatus = BehaviorRelay<OutageTracker.Status>(value: .none)
    var trackerState = BehaviorRelay<TrackerState>(value: .open)
    
    func configure(withStatus status: OutageTracker.Status) {
        self.trackerStatus.accept(status)
    }
    
    func next(status: OutageTracker.Status) {
        guard trackerState.value == .complete { return }
        if status == trackerStatus.value {
            trackerState.accept(.reported)
        } else {
            if trackerState.value == .reported {
                trackerState.accept(.complete)
            }
        }
    
    private func setupBinding() {
        self.trackerStatus
            .subscribe(onNext:{ [unowned self] status in
                self.statusTitleLabel.text = status.rawValue
                self.updateUI(forState: self.trackerState)
            }).disposed(by: disposeBag)
        
        self.trackerState
            .subscribe(onNext:{ [unowned self] state in
                self.updateUI(forState: state)
            }).disposed(by: disposeBag)
    }
    
    private func updateUI(forState state: TrackerState) {
        statusDateLabel.text = state == .open ? "" : Date().shortMonthDayAndTimeString
        barWidthConstraint.constant = state == .complete ? 5 : 2
        self.circleImageView.image = state.image
    }
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(self.className, owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.layer.cornerRadius = 2
        contentView.backgroundColor = UIColor.softGray
        
        setupBinding()
    }

}
