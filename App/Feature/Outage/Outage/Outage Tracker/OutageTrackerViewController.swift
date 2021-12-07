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
import RxSwift

class OutageTrackerViewController: UIViewController {
    
    @IBOutlet weak var progressAnimationContainer: UIView!
    @IBOutlet weak var statusTitleView: UIView!
    @IBOutlet weak var statusTitleLabel: UILabel!
    @IBOutlet weak var statusDetailView: UIView!
    @IBOutlet weak var statusDetailLabel: UILabel!
    @IBOutlet weak var etaContainerView: UIView!
    @IBOutlet weak var etaView: UIView!
    @IBOutlet weak var etaTitleLabel: UILabel!
    @IBOutlet weak var etaDateTimeLabel: UILabel!
    @IBOutlet weak var etaDetailLabel: UILabel!
    @IBOutlet weak var etaCauseLabel: UILabel!
    @IBOutlet weak var etaUpdatedView: UIView!
    @IBOutlet weak var etaInfoButton: UIButton!
    @IBOutlet weak var countContainerView: UIView!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var neighborCount: UILabel!
    @IBOutlet weak var outageCount: UILabel!
    
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    
    let disposeBag = DisposeBag()
    let viewModel = OutageTrackerViewModel()
    var progressAnimation = AnimationView(name: "appointment_tracker")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadOutageTracker()
        setupUI()
        setupBinding()
    }
    
    private func loadOutageTracker() {
        self.viewModel.getOutageTracker {
            print("fetching tracker")
        } onError: { error in
            print("error fetching tracker: \(error.localizedDescription)")
        }
    }
    
    private func setupBinding() {
        self.viewModel.outageTracker
            .subscribe(onNext: { [weak self] _ in
                self?.update()
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupUI() {
        // todo: get colors
        etaView.roundCorners(.allCorners, radius: 10, borderColor: UIColor.bgeGreen, borderWidth: 1.0)
        
        etaUpdatedView.roundCorners(.allCorners, radius: 10, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        
        countView.roundCorners(.allCorners, radius: 10, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
    }
    
    private func update() {
        trackerStatusView.configure(withEvents: viewModel.events)
        statusTitleLabel.text = viewModel.statusTitle
        statusDetailView.isHidden = viewModel.statusDetails.isEmpty
        statusDetailLabel.text = viewModel.statusDetails
        
        updateETA()
    }
    
    private func updateETA() {
        etaTitleLabel.text = viewModel.etaTitle
        etaDateTimeLabel.text = viewModel.etaDateTime
        etaDetailLabel.text = viewModel.etaDetail
        etaCauseLabel.text = viewModel.etaCause
        
        // show/hide info button
        // show/hide update view
        
    }
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        print("info button pressed")
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
