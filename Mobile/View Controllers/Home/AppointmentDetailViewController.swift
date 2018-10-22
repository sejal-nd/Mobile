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
    @IBOutlet private weak var caseNumberLabel: UILabel!
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
    @IBOutlet private weak var upperContactButtonContainer: UIView!
    @IBOutlet private weak var upperContactButton: ButtonControl!
    @IBOutlet private weak var upperContactLabel: UILabel!
    
    @IBOutlet private weak var howToPrepareContainer: UIView!
    @IBOutlet private weak var howToPrepareHeaderLabel: UILabel!
    @IBOutlet private weak var howToPrepareBodyLabel: UILabel!
    @IBOutlet private weak var lowerContactButton: ButtonControl!
    @IBOutlet private weak var lowerContactLabel: UILabel!
    
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
        styleViews()
        bindViewModel()
        bindActions()
        setUpTopAnimation()
        setUpProgressAnimation()
        makeTimelineAccessible()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        topAnimation.setProgressWithFrame(NSNumber(integerLiteral: 0))
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.topAnimation.play()
            self.playProgressAnimation()
        }
    }
    
    func styleViews() {
        caseNumberLabel.textColor = .blackText
        caseNumberLabel.font = OpenSans.semibold.of(textStyle: .headline)
        
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
        adjustAlertPreferencesButton.titleLabel?.font = OpenSans.bold.of(textStyle: .title1)
        
        howToPrepareHeaderLabel.textColor = .blackText
        howToPrepareHeaderLabel.font = OpenSans.semibold.of(textStyle: .subheadline)
        
        howToPrepareBodyLabel.textColor = .blackText
        howToPrepareBodyLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        
        upperContactButton.layer.cornerRadius = 10
        upperContactButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        upperContactButton.accessibilityLabel = upperContactLabel.text
        
        upperContactLabel.textColor = .actionBlue
        upperContactLabel.font = SystemFont.bold.of(textStyle: .title1)
        
        lowerContactButton.layer.cornerRadius = 10
        lowerContactButton.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
        lowerContactButton.accessibilityLabel = lowerContactLabel.text
        
        lowerContactLabel.textColor = .actionBlue
        lowerContactLabel.font = SystemFont.bold.of(textStyle: .title1)
    }
    
    func bindViewModel() {
        if viewModel.showHowToPrepare {
            // So the bottom stays gray when the scroll view rubber bands
            scrollView.rx.contentOffset.asDriver()
                .map { $0.y < 0 }
                .distinctUntilChanged()
                .map { $0 ? UIColor.white : UIColor.softGray }
                .drive(scrollView.rx.backgroundColor)
                .disposed(by: disposeBag)
        }
        
        progressView.isHidden = !viewModel.showProgressView
        
        let regular = OpenSans.regular.of(textStyle: .headline)
        let bold = OpenSans.bold.of(textStyle: .headline)
        
        confirmedLabel.font = viewModel.status == .scheduled ? bold : regular
        onOurWayLabel.font = viewModel.status == .enRoute ? bold : regular
        inProgressLabel.font = viewModel.status == .inProgress ? bold : regular
        completeLabel.font = viewModel.status == .complete ? bold : regular
        
        adjustAlertPreferencesContainer.isHidden = !viewModel.showAdjustAlertPreferences
        upperContactButtonContainer.isHidden = !viewModel.showUpperContactButton
        howToPrepareContainer.isHidden = !viewModel.showHowToPrepare
        
        caseNumberLabel.text = viewModel.caseNumberText
        appointmentDescriptionTextView.attributedText = viewModel.appointmentDescriptionText
    }
    
    func bindActions() {
        Driver.merge(upperContactButton.rx.touchUpInside.asDriver(),
                     lowerContactButton.rx.touchUpInside.asDriver())
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                switch self.viewModel.status {
                case .complete:
                    let safariVC = SFSafariViewController
                        .createWithCustomStyle(url: URL(string: "https://google.com")!)
                    self.present(safariVC, animated: true, completion: nil)
                case .scheduled, .enRoute, .inProgress, .canceled:
                    guard let url = URL(string: "tel://" + self.viewModel.contactNumber),
                        UIApplication.shared.canOpenURL(url) else {
                            return
                    }
                    
                    UIApplication.shared.open(url)
                }
            })
            .disposed(by: disposeBag)
        
        adjustAlertPreferencesButton.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                
                let storyboard = UIStoryboard(name: "Alerts", bundle: nil)
                guard let alertPrefsVC = storyboard.instantiateViewController(withIdentifier: "alertPreferences") as? AlertPreferencesViewController else {
                    return
                }
                
                alertPrefsVC.delegate = self
                self.navigationController?.pushViewController(alertPrefsVC, animated: true)
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
                        self.addCalendarEvent()
                    }
                case .restricted:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func makeTimelineAccessible() {
        switch viewModel.status {
        case .scheduled:
            confirmedLabel.accessibilityLabel = NSLocalizedString("Confirmed, complete", comment: "")
            onOurWayLabel.accessibilityLabel = NSLocalizedString("On our way, pending", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("In progress, pending", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Complete, pending", comment: "")
        case .enRoute:
            confirmedLabel.accessibilityLabel = NSLocalizedString("Confirmed, complete", comment: "")
            onOurWayLabel.accessibilityLabel = NSLocalizedString("On our way, complete", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("In progress, pending", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Complete, pending", comment: "")
        case .inProgress:
            confirmedLabel.accessibilityLabel = NSLocalizedString("Confirmed, complete", comment: "")
            onOurWayLabel.accessibilityLabel = NSLocalizedString("On our way, complete", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("In progress, complete", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Complete, pending", comment: "")
        case .complete:
            confirmedLabel.accessibilityLabel = NSLocalizedString("Confirmed, complete", comment: "")
            onOurWayLabel.accessibilityLabel = NSLocalizedString("On our way, complete", comment: "")
            inProgressLabel.accessibilityLabel = NSLocalizedString("In progress, complete", comment: "")
            completeLabel.accessibilityLabel = NSLocalizedString("Appointment complete", comment: "")
        case .canceled:
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
        
//        progressAnimation.setProgressWithFrame(NSNumber(integerLiteral: 0))
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
        
        switch action {
        case .saved:
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.view.showToast(NSLocalizedString("Appointment added to calendar", comment: ""))
            })
        case .canceled, .deleted:
            break
        }
    }
}

extension AppointmentDetailViewController: AlertPreferencesViewControllerDelegate {
    
    func alertPreferencesViewControllerDidSavePreferences() {
        Analytics.log(event: .alertsPrefCenterComplete)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Preferences saved", comment: ""))
        })
    }
}
