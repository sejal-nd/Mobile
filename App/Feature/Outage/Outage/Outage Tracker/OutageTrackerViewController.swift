//
//  OutageTrackerViewController.swift
//  EUMobile
//
//  Created by Cody Dillon on 12/1/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class OutageTrackerViewController: UIViewController {
    
    @IBOutlet weak var progressAnimationContainer: UIView!
    @IBOutlet weak var statusTitleView: UIView!
    @IBOutlet weak var statusTitleLabel: UILabel!
    
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    
    let disposeBag = DisposeBag()
    let viewModel = OutageTrackerViewModel()
    var progressAnimation = AnimationView(name: "appointment_tracker")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBinding()
    }
    
    private func setupBinding() {
        self.viewModel.outageTracker
            .subscribe(onNext: { [weak self] tracker in
                self?.updateTracker(forStatus: viewModel.status)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func updateTracker(forStatus status: OutageTracker.Status) {
        let title = NSLocalizedString(viewModel.status.statusTitleString, comment: "")
        statusTitleLabel.text = title
        trackerStatusView.update(status: status)
    }
    
    
}

extension OutageTrackerViewController {
    
    // MARK - Lottie Animation
    
    func setUpProgressAnimation() {
        progressAnimation.loopMode = .playOnce
        progressAnimation.translatesAutoresizingMaskIntoConstraints = false
        progressAnimation.contentMode = .scaleAspectFill
        
        progressAnimation.setContentHuggingPriority(.required, for: .horizontal)
        progressAnimation.setContentHuggingPriority(.required, for: .vertical)
        progressAnimation.setContentCompressionResistancePriority(.required, for: .horizontal)
        progressAnimation.setContentCompressionResistancePriority(.required, for: .vertical)
        
        progressAnimationContainer.addSubview(progressAnimation)
        
        progressAnimationContainer.addConstraints([
            progressAnimation.topAnchor.constraint(equalTo: progressAnimationContainer.topAnchor),
            progressAnimation.bottomAnchor.constraint(equalTo: progressAnimationContainer.bottomAnchor),
            progressAnimation.leadingAnchor.constraint(equalTo: progressAnimationContainer.leadingAnchor),
            progressAnimation.trailingAnchor.constraint(equalTo: progressAnimationContainer.trailingAnchor)
        ])
    }
    
    func frameForStatus(_ status: OutageTracker.Status) -> CGFloat {
        switch status {
            case .reported:
                return 67
            case .assigned:
                fallthrough
            case .enRoute:
                return 136
            case .onSite:
                return 206
            case .restored:
                return 270
            default:
                return 0
        }
    }
    
    func playProgressAnimation() {
        let stopFrame = frameForStatus(viewModel.status)
        progressAnimation.stop()
        progressAnimation.play(fromFrame: 0.0, toFrame: stopFrame, loopMode: .playOnce, completion: nil)
    }
    
    func playProgressAnimation(fromStatus: OutageTracker.Status) {
        let startFrame = frameForStatus(fromStatus)
        let stopFrame = frameForStatus(viewModel.status)
        
        progressAnimation.stop()
        progressAnimation.play(fromFrame: startFrame, toFrame: stopFrame, loopMode: .playOnce, completion: nil)
    }
    
}
