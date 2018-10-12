//
//  AppointmentDetailViewController.swift
//  Mobile
//
//  Created by Sam Francis on 10/11/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import XLPagerTabStrip
import Lottie
import EventKit
import EventKitUI

class AppointmentDetailViewController: UIViewController, IndicatorInfoProvider {
    
    @IBOutlet private weak var topAnimationContainer: UIView!
    @IBOutlet private weak var progressView: UIView!
    @IBOutlet private weak var progressAnimationContainer: UIView!
    @IBOutlet private weak var addToCalendarButton: ButtonControl!
    
    var topAnimation = LOTAnimationView()
    var progressAnimation = LOTAnimationView(name: "appointment_tracker")
    
    var eventVC = EKEventEditViewController()
    
    let viewModel: AppointmentDetailViewModel
    
    let disposeBag = DisposeBag()
    
    init(viewModel: AppointmentDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: AppointmentDetailViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTopAnimation()
        setUpProgressAnimation()
        
        addToCalendarButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                self.eventVC = EKEventEditViewController()
                self.eventVC.event = self.viewModel.calendarEvent
                self.eventVC.eventStore = self.viewModel.eventStore
                self.eventVC.editViewDelegate = self
                
                self.present(self.eventVC, animated: true)
            })
            .disposed(by: disposeBag)
        
//        addToCalendarButton.rx.touchUpInside
//            .toAsyncRequest { [weak self] in
//                self?.viewModel.addCalendarEvent() ?? .empty()
//            }
//            .errors()
//            .asDriver(onErrorDriveWith: .empty())
//            .drive(onNext: { [weak self] _ in
//                guard let self = self else { return }
//
//                let title = String.localizedStringWithFormat("Adding to calendar is currently disabled on your device. Please visit your device settings to allow %@ to access your calendar.", Environment.shared.opco.displayString)
//
//                let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
//                alert.addAction(UIAlertAction(title: NSLocalizedString("Go to Settings", comment: ""), style: .default) { _ in
//                    if let url = URL(string: UIApplication.openSettingsURLString) {
//                        UIApplication.shared.openURL(url)
//                    }
//                })
//
//                self.present(alert, animated: true, completion: nil)
//            })
//            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        topAnimation.play()
        playProgressAnimation()
    }
    
    func playProgressAnimation() {
        let stopFrame: Int
        switch viewModel.status {
        case .scheduled:
            stopFrame = 67
        case .enRoute:
            stopFrame = 136
        case .inProgress:
            stopFrame = 206
        case .complete:
            stopFrame = 270
        case .canceled:
            return // no progress animation if canceled
        }
        
        progressAnimation.play(fromFrame: NSNumber(integerLiteral: 0),
                               toFrame: NSNumber(integerLiteral: stopFrame),
                               withCompletion: nil)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: viewModel.tabTitle)
    }
    
    func setUpTopAnimation() {
        let animationName: String
        let loop: Bool
        switch viewModel.status {
        case .scheduled:
            animationName = "Appt_Confirmed"
            loop = false
        case .enRoute:
            animationName = "Appt_otw"
            loop = true
        case .inProgress:
            animationName = "Appt_Inprogress"
            loop = false
        case .complete:
            animationName = "Appt_Complete"
            loop = false
        case .canceled:
            animationName = "Appt_Canceled"
            loop = false
        }
        
        topAnimation = LOTAnimationView(name: animationName)
        topAnimation.loopAnimation = loop
        topAnimation.translatesAutoresizingMaskIntoConstraints = false
        topAnimation.contentMode = .scaleAspectFill
        
        topAnimation.setContentHuggingPriority(.required, for: .horizontal)
        topAnimation.setContentHuggingPriority(.required, for: .vertical)
        topAnimation.setContentCompressionResistancePriority(.required, for: .horizontal)
        topAnimation.setContentCompressionResistancePriority(.required, for: .vertical)
        
        topAnimationContainer.addSubview(topAnimation)
        
        topAnimationContainer.addConstraints([
            topAnimation.topAnchor.constraint(equalTo: topAnimationContainer.topAnchor),
            topAnimation.bottomAnchor.constraint(equalTo: topAnimationContainer.bottomAnchor),
            topAnimation.leadingAnchor.constraint(equalTo: topAnimationContainer.leadingAnchor),
            topAnimation.trailingAnchor.constraint(equalTo: topAnimationContainer.trailingAnchor)
            ])
    }
    
    func setUpProgressAnimation() {
        progressAnimation.loopAnimation = false
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
}

extension AppointmentDetailViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        eventVC.dismiss(animated: true, completion: nil)
    }
    
    
}
