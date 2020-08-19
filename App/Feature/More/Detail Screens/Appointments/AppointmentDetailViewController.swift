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
import SafariServices

class AppointmentDetailViewController: UIViewController, IndicatorInfoProvider {
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var topAnimationContainer: UIView!
    @IBOutlet private weak var appointmentDescriptionTextView: DataDetectorTextView!
    @IBOutlet private weak var progressView: UIView!
    @IBOutlet private weak var progressAnimationContainer: UIView!
    @IBOutlet private weak var addToCalendarButton: ButtonControl!
    @IBOutlet private weak var addToCalendarLabel: UILabel!
    
    @IBOutlet private weak var confirmedLabel: UILabel!
    @IBOutlet private weak var onOurWayLabel: UILabel!
    @IBOutlet private weak var inProgressLabel: UILabel!
    @IBOutlet private weak var completeLabel: UILabel!
    
    @IBOutlet private weak var adjustAlertPreferencesContainer: UIView!
    @IBOutlet private weak var wantNotificationsLabel: UILabel!
    @IBOutlet private weak var adjustAlertPreferencesButton: UIButton!
    
    var topAnimation = AnimationView()
    var progressAnimation = AnimationView(name: "appointment_tracker")
    
    var eventVC = EKEventEditViewController()
    
    let viewModel: AppointmentDetailViewModel
    
    let disposeBag = DisposeBag()
    
    var viewHasAppeared = false
    var viewHasLoaded = false
    
    var index = -1
    var totalCount = -1
    
    init(viewModel: AppointmentDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: AppointmentDetailViewController.className, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleViews()
        bindViewModel()
        bindActions()
        setUpTopAnimation()
        setUpProgressAnimation()
        makeTimelineAccessible()
        viewHasLoaded = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !viewHasAppeared {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                self.topAnimation.play()
                self.playProgressAnimation()
            }
        }
        viewHasAppeared = true
    }
    
    func update(withAppointment appointment: Appointment) {
        let currApptStatus = viewModel.appointment.statusType
        viewModel.appointment = appointment
        if viewHasLoaded {
            self.playProgressAnimation(fromStatus: currApptStatus)
            bindViewModel()
            bindActions()
            makeTimelineAccessible()
        }
    }
    
    func styleViews() {
        appointmentDescriptionTextView.textContainerInset = UIEdgeInsets(top: 14, left: 0, bottom: 8, right: 0) // top/bottom padding
        appointmentDescriptionTextView.textColor = .blackText
        appointmentDescriptionTextView.tintColor = .actionBlue // Color of the phone numbers
        appointmentDescriptionTextView.font = OpenSans.regular.of(textStyle: .headline)
        
        addToCalendarLabel.textColor = .actionBlue
        addToCalendarLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        addToCalendarButton.accessibilityLabel = addToCalendarLabel.text
        
        confirmedLabel.textColor = .deepGray
        onOurWayLabel.textColor = .deepGray
        inProgressLabel.textColor = .deepGray
        completeLabel.textColor = .deepGray
        
        wantNotificationsLabel.textColor = .blackText
        wantNotificationsLabel.font = OpenSans.regular.of(textStyle: .headline)
        
        adjustAlertPreferencesButton.setTitleColor(.actionBlue, for: .normal)
        adjustAlertPreferencesButton.titleLabel?.font = OpenSans.bold.of(textStyle: .headline)
    }
    
    func bindViewModel() {
        progressView.isHidden = !viewModel.showProgressView
        
        let regular = OpenSans.regular.of(textStyle: .headline)
        let bold = OpenSans.bold.of(textStyle: .headline)
        
        confirmedLabel.font = viewModel.status == .scheduled ? bold : regular
        onOurWayLabel.font = viewModel.status == .onOurWay || viewModel.status == .enRoute ? bold : regular
        inProgressLabel.font = viewModel.status == .inProgress ? bold : regular
        completeLabel.font = viewModel.status == .complete ? bold : regular
        
        adjustAlertPreferencesContainer.isHidden = !viewModel.showAdjustAlertPreferences
        
        appointmentDescriptionTextView.attributedText = viewModel.appointmentDescriptionText
        appointmentDescriptionTextView.accessibilityValue = viewModel.appointmentDescriptionText.string.replacingOccurrences(of: "-", with: "and")
        
        addToCalendarButton.isHidden = !viewModel.showCalendarButton
    }
    
    func bindActions() {
        adjustAlertPreferencesButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                let storyboard = UIStoryboard(name: "Alerts", bundle: nil)
                guard let alertPrefsVC = storyboard.instantiateViewController(withIdentifier: "alertPreferences") as? AlertPreferencesViewController else {
                    return
                }
                
                alertPrefsVC.delegate = self
                
                let newNavController = LargeTitleNavigationController(rootViewController: alertPrefsVC)
                self.navigationController?.present(newNavController, animated: true)
            })
            .disposed(by: disposeBag)
        
        addToCalendarButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                switch EKEventStore.authorizationStatus(for: .event) {
                case .authorized:
                    self.addCalendarEvent()
                case .denied:
                    self.showCalendarPermissionsDeniedAlert()
                case .notDetermined:
                    EventStore.shared.requestAccess(to: .event) { [weak self] (granted, error) in
                        guard let self = self, error == nil && granted else { return }
                        DispatchQueue.main.async {
                            self.addCalendarEvent()
                        }
                    }
                case .restricted: fallthrough
                @unknown default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func makeTimelineAccessible() {
         confirmedLabel.accessibilityLabel = NSLocalizedString("Appointment progress tracker. Confirmed step, complete", comment: "")
        switch viewModel.status {
        case .scheduled:
            onOurWayLabel.accessibilityLabel = NSLocalizedString("On our way step, pending", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("In progress step, pending", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Complete step, pending", comment: "")
        case .onOurWay:
            fallthrough
        case .enRoute:
            onOurWayLabel.accessibilityLabel = NSLocalizedString("We are on our way", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("In progress step, pending", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Complete step, pending", comment: "")
        case .inProgress:
            onOurWayLabel.accessibilityLabel = NSLocalizedString("On our way step, complete", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("Appointment currently in progress", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Complete step, pending", comment: "")
        case .complete:
            onOurWayLabel.accessibilityLabel = NSLocalizedString("On our way step, complete", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("In progress step, complete", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Appointment complete", comment: "")
        case .canceled, .none:
            // Do nothing, these labels are not displayed
            break
        }
    }
    
    func addCalendarEvent() {
        eventVC = EKEventEditViewController()
        eventVC.event = self.viewModel.calendarEvent
        eventVC.eventStore = EventStore.shared
        eventVC.editViewDelegate = self
        present(self.eventVC, animated: true)
    }
    
    func showCalendarPermissionsDeniedAlert() {
        let title = String.localizedStringWithFormat("Adding to calendar is currently disabled on your device. Please visit your device settings to allow %@ to access your calendar.", Environment.shared.opco.displayString)
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Go to Settings", comment: ""), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func frameForStatus(_ status: Appointment.Status) -> CGFloat {
        switch status {
        case .scheduled:
            return 67
        case .onOurWay:
            fallthrough
        case .enRoute:
            return 136
        case .inProgress:
            return 206
        case .complete:
            return 270
        default:
            return 0
        }
    }
    
    func playProgressAnimation() {
        if viewModel.status == .canceled {
            return
        }
        
        let stopFrame = frameForStatus(viewModel.status)
        progressAnimation.stop()
        progressAnimation.play(fromFrame: 0.0, toFrame: stopFrame, loopMode: .playOnce, completion: nil)
    }
    
    func playProgressAnimation(fromStatus: Appointment.Status) {
        if viewModel.status == .canceled {
            return
        }
        
        let startFrame = frameForStatus(fromStatus)
        let stopFrame = frameForStatus(viewModel.status)
        
        progressAnimation.stop()
        progressAnimation.play(fromFrame: startFrame, toFrame: stopFrame, loopMode: .playOnce, completion: nil)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        var indicator = IndicatorInfo(title: viewModel.tabTitle)
        indicator.accessibilityLabel = String.localizedStringWithFormat("%@, %d of %d appointments", viewModel.tabTitle, index + 1, totalCount)
        return indicator
    }
    
    func setUpTopAnimation() {
        let animationName: String
        let loop: Bool
        switch viewModel.status {
        case .scheduled:
            animationName = "Appt_Confirmed-Flavor\(Environment.shared.opco.rawValue)"
            loop = false
        case .onOurWay:
            fallthrough
        case .enRoute:
            animationName = "Appt_otw-Flavor\(Environment.shared.opco.rawValue)"
            loop = true
        case .inProgress:
            animationName = "Appt_Inprogress-Flavor\(Environment.shared.opco.rawValue)"
            loop = false
        case .complete:
            animationName = "Appt_Complete-Flavor\(Environment.shared.opco.rawValue)"
            loop = false
        case .canceled, .none:
            animationName = "Appt_Canceled-Flavor\(Environment.shared.opco.rawValue)"
            loop = false
        }
        
        topAnimation = AnimationView(name: animationName)
        topAnimation.loopMode = loop ? .loop : .playOnce
        topAnimation.backgroundBehavior = .pauseAndRestore
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
}

extension AppointmentDetailViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        eventVC.dismiss(animated: true, completion: nil)
        
        switch action {
        case .saved:
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.view.showToast(NSLocalizedString("Appointment added to calendar", comment: ""))
            })
        case .canceled, .deleted: fallthrough
        @unknown default:
            break
        }
    }
}

extension AppointmentDetailViewController: AlertPreferencesViewControllerDelegate {
    
    func alertPreferencesViewControllerDidSavePreferences() {
        GoogleAnalytics.log(event: .alertsPrefCenterComplete)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Preferences saved", comment: ""))
        })
    }
}
