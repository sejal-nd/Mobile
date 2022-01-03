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
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var progressAnimationContainer: UIView!
    @IBOutlet weak var statusTitleView: UIView!
    @IBOutlet weak var statusTitleLabel: UILabel!
    @IBOutlet weak var statusDetailView: UIView!
    @IBOutlet weak var statusDetailLabel: UILabel!
    @IBOutlet weak var whyButtonContainer: UIView!
    @IBOutlet weak var whyButtonView: UIView!
    @IBOutlet weak var whyButton: UIButton!
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
    @IBOutlet weak var neighborCountLabel: UILabel!
    @IBOutlet weak var outageCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewContainer: UIView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var trackerStatusContainer: UIView!
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    @IBOutlet weak var surveyContainer: UIView!
    @IBOutlet weak var powerOnContainer: UIView!
    
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailTrailingConstraint: NSLayoutConstraint!
    
    let disposeBag = DisposeBag()
    let viewModel = OutageTrackerViewModel()
    let infoView = StatusInfoView()
    var progressAnimation = AnimationView(name: "ot_reported")
    var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configureFooterTextView()
        setupUI()
        setupBinding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setRefreshControlEnabled(enabled: false)
        loadOutageTracker()
    }
    
    private func loadOutageTracker() {
        scrollView.isHidden = true
        loadingIndicator.isHidden = false
        self.viewModel.getOutageStatus()
        self.viewModel.fetchOutageTracker()
    }
    
    private func configureTableView() {
        let titleDetailCell = UINib(nibName: TitleSubTitleRow.className, bundle: nil)
        tableView.register(titleDetailCell, forCellReuseIdentifier: TitleSubTitleRow.className)
        tableView.accessibilityLabel = "outageTableView"
        tableView.reloadData()
    }
    
    private func configureFooterTextView() {
        footerTextView.font = SystemFont.regular.of(textStyle: .footnote)
        footerTextView.attributedText = viewModel.footerText
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
    }
    
    private func setupBinding() {
        self.viewModel.outageTracker
            .subscribe(onNext: { [weak self] _ in
                self?.setUpProgressAnimation()
                self?.update()
                self?.scrollView.isHidden = false
                self?.loadingIndicator.isHidden = true
            })
            .disposed(by: self.disposeBag)
        
        self.viewModel.outageStatus
            .subscribe(onNext: { _ in
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupUI() {
        infoView.frame = self.view.bounds
        self.view.addSubview(infoView)
        self.infoView.delegate = self
        self.infoView.isHidden = true
        self.errorImageView.isHidden = true
        self.etaUpdatedView.isHidden = true
        self.whyButtonContainer.isHidden = true
        
        etaView.roundCorners(.allCorners, radius: 10, borderColor: .successGreenText, borderWidth: 1.0)
        
        let updatedViewRadius = etaUpdatedView.frame.size.height / 2
        etaUpdatedView.roundCorners(.allCorners, radius: updatedViewRadius, borderColor: .successGreenText, borderWidth: 1.0)
        
        let whyViewRadius = whyButtonView.frame.size.height / 2
        whyButtonView.roundCorners(.allCorners, radius: whyViewRadius, borderColor: .accentGray, borderWidth: 1.0)
        
        countView.roundCorners(.allCorners, radius: 10, borderColor: .accentGray, borderWidth: 1.0)
        
        tableViewContainer.roundCorners(.allCorners, radius: 0, borderColor: .accentGray, borderWidth: 1.0)
    }
    
    private func update() {
        if viewModel.isGasOnly {
            let gasOnlyView = GasOnlyView()
            gasOnlyView.frame = self.view.bounds
            self.view.addSubview(gasOnlyView)
        } else {
            etaContainerView.isHidden = true
            countContainerView.isHidden = true
            trackerStatusContainer.isHidden = true
            surveyContainer.isHidden = true
            
            if viewModel.isActiveOutage == false {
                statusTitleView.isHidden = true
                statusDetailView.isHidden = true
                powerOnContainer.isHidden = false
            } else {
                statusTitleView.isHidden = false
                statusDetailView.isHidden = false
                powerOnContainer.isHidden = true
                
                statusTitleLabel.text = viewModel.statusTitle
                statusDetailLabel.text = viewModel.statusDetails
                
                if viewModel.status == .none {
                    progressAnimationContainer.isHidden = true
                    errorImageView.isHidden = false
                    errorImageView.image = UIImage(named: "ic_bigerror_sm")
                    
                    statusTitleLabel.textAlignment = .center
                    titleLeadingConstraint.constant = 30
                    titleTrailingConstraint.constant = 30
                    detailLeadingConstraint.constant = 50
                    detailTrailingConstraint.constant = 50
                } else {
                    etaContainerView.isHidden = false
                    countContainerView.isHidden = false
                    trackerStatusContainer.isHidden = false
                    surveyContainer.isHidden = false
                    errorImageView.isHidden = true
                    statusDetailView.isHidden = viewModel.statusDetails.isEmpty
                    
                    if viewModel.status == .restored {
                        statusTitleLabel.textAlignment = .center
                        countContainerView.isHidden = true
                        
                        statusTitleLabel.textAlignment = .center
                        titleLeadingConstraint.constant = 30
                        titleTrailingConstraint.constant = 30
                        detailLeadingConstraint.constant = 50
                        detailTrailingConstraint.constant = 50
                    } else {
                        statusTitleLabel.textAlignment = .left
                        titleLeadingConstraint.constant = 20
                        titleTrailingConstraint.constant = 20
                        detailLeadingConstraint.constant = 20
                        detailTrailingConstraint.constant = 20
                    }
                    
                    whyButtonContainer.isHidden = viewModel.hideWhyButton
                    whyButton.setTitle(viewModel.whyButtonText, for: .normal)
                    neighborCountLabel.text = viewModel.neighborCount
                    outageCountLabel.text = viewModel.outageCount
                    updateETA()
                    
                    if viewModel.events.isEmpty {
                        trackerStatusContainer.isHidden = true
                    } else {
                        trackerStatusContainer.isHidden = false
                        let paused = viewModel.isPaused
                        trackerStatusView.configure(withEvents: viewModel.events, lastUpdated: viewModel.lastUpdated, isPaused: paused)
                    }
                }
            }
            
            refreshControl?.endRefreshing()
            setRefreshControlEnabled(enabled: true)
        }
    }
    
    private func updateETA() {
        etaTitleLabel.text = viewModel.etaTitle
        etaDateTimeLabel.text = viewModel.etaDateTime
        
        etaCauseLabel.text = viewModel.etaCause
        etaCauseLabel.isHidden = viewModel.etaCause.isEmpty
        
        etaDetailLabel.isHidden = false
        etaInfoButton.isHidden = false
        switch viewModel.status {
            case .reported, .assigned, .enRoute:
                etaDetailLabel.text = viewModel.etaDetail
            case .onSite:
                etaDetailLabel.text = viewModel.etaOnSiteDetail
            case .restored, .none:
                etaDetailLabel.isHidden = true
                etaInfoButton.isHidden = true
        }
    }
    
    private func reportOutage() {
        let storyboard = UIStoryboard(name: "Outage", bundle: Bundle.main)
        if let reportOutageVC = storyboard.instantiateViewController(withIdentifier: "ReportOutageViewController") as?  ReportOutageViewController {
            if let outageStatus = viewModel.outageStatus.value {
                reportOutageVC.viewModel.outageStatus = outageStatus
                reportOutageVC.viewModel.phoneNumber.accept(outageStatus.contactHomeNumber ?? "")
                navigationController?.pushViewController(reportOutageVC, animated: true)
            } else {
                // show alert maybe
            }
        }
    }
    
    private func openOutageMap(forStreetMap isStreetMap: Bool) {
        let storyboard = UIStoryboard(name: "Outage", bundle: Bundle.main)
        if let outageMapVC = storyboard.instantiateViewController(withIdentifier: "OutageMapViewController") as?  OutageMapViewController {
            outageMapVC.hasPressedStreetlightOutageMapButton = isStreetMap
            navigationController?.pushViewController(outageMapVC, animated: true)
        }
    }
    
    @objc private func setRefreshControlEnabled(enabled: Bool) {
        if enabled {
            guard refreshControl == nil else { return }
            
            let rc = UIRefreshControl()
            
            rc.rx.controlEvent(.valueChanged)
                .subscribe(onNext: { [weak self] in
                    self?.loadOutageTracker()
                    self?.etaUpdatedView.isHidden = false
                })
                .disposed(by: disposeBag)
            
            scrollView?.insertSubview(rc, at: 0)
            scrollView?.alwaysBounceVertical = true
            refreshControl = rc
        } else {
            refreshControl?.endRefreshing()
            refreshControl?.removeFromSuperview()
            refreshControl = nil
            scrollView?.alwaysBounceVertical = false
        }
    }
    
    @objc func onPullToRefresh() {
        loadOutageTracker()
        FeatureFlagUtility.shared.fetchCloudValues()
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.refreshControl?.endRefreshing()
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        let info = StatusInfoMessage.etrToolTip
        infoView.configure(withInfo: info)
        infoView.isHidden = false
    }
    
    @IBAction func surveyButtonPressed(_ sender: Any) {
        guard let url = URL(string: viewModel.surveyURL) else { return }
        let survey = WebViewController(title: NSLocalizedString("", comment: ""),
                                         url: url)
        navigationController?.present(survey, animated: true, completion: nil)
    }
    
    @IBAction func whyButtonPressed(_ sender: Any) {
        guard let tracker = viewModel.outageTracker.value else { return }
        
        var info = StatusInfoMessage.none
        
        if tracker.isSafetyHazard == true {
            info = StatusInfoMessage.hazardMessage
        }
        if tracker.isCrewDiverted == true {
            info = StatusInfoMessage.rerouted
        }
        if tracker.isCrewLeftSite == true {
            info = StatusInfoMessage.whyStop
        }
        if viewModel.status == .restored {
            // todo: determine def vs non-def
            info = StatusInfoMessage.hasOutageDef
        }
        infoView.configure(withInfo: info)
        infoView.isHidden = false
    }
}

extension OutageTrackerViewController: StatusInfoViewDelegate {
    func dismissInfoView() {
        infoView.isHidden = true
    }
    func reportOutagePressed() {
        openOutageMap(forStreetMap: false)
    }
}

extension OutageTrackerViewController {
    
    // MARK - Lottie Animation
    
    func setUpProgressAnimation() {
        let animationName = viewModel.animationName
        progressAnimation.removeFromSuperview()
        progressAnimation = AnimationView(name: animationName)
        
        progressAnimation.frame = CGRect(x: 0, y: 1, width: progressAnimationContainer.frame.size.width, height: progressAnimationContainer.frame.size.height)
        progressAnimation.loopMode = .loop
        progressAnimation.backgroundBehavior = .pauseAndRestore
        progressAnimation.contentMode = .scaleAspectFill
        
        progressAnimationContainer.addSubview(progressAnimation)
        
        progressAnimation.play()
    }
}

// MARK: - Table View Data Source

extension OutageTrackerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = 3
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleSubTitleRow.className, for: indexPath) as? TitleSubTitleRow else { fatalError("Invalid cell type.") }
        cell.backgroundColor = .softGray
        
        switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_reportoutage"), title: "Report Outage", detail: nil)
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_streetlightoutage"), title: "Report Streetlight Outage", detail: nil)
            case 2:
                cell.configure(image: UIImage(named: "ic_mapoutage"), title: "View Outage Map", detail: nil)
            default:
                fatalError("Invalid index path.")
        }
        
        return cell
    }
    
}


// MARK: - Table View Delegate

extension OutageTrackerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? TitleSubTitleRow, cell.isEnabled else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            reportOutage()
        } else {
            let isStreetMap = indexPath.row == 1
            openOutageMap(forStreetMap: isStreetMap)
        }
    }
}
