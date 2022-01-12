//
//  OutageTrackerViewController.swift
//  EUMobile
//
//  Created by Cody Dillon on 12/1/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class OutageTrackerViewController: UIViewController {
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var progressAnimationView: StateAnimationView!
    @IBOutlet weak var statusTextView: StatusTextView!
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
    @IBOutlet weak var etaInfoButtonView: UIView!
    @IBOutlet weak var countContainerView: UIView!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var neighborCountLabel: UILabel!
    @IBOutlet weak var outageCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewContainer: UIView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var trackerStatusContainer: UIView!
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    @IBOutlet weak var surveyContainer: UIView!
    @IBOutlet weak var powerOnContainer: UIView!
    
    let disposeBag = DisposeBag()
    let viewModel = OutageTrackerViewModel()
    let infoView = StatusInfoView()
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
                self?.update()
                self?.scrollView.isHidden = false
                self?.loadingIndicator.isHidden = true
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupUI() {
        infoView.frame = self.view.bounds
        self.view.addSubview(infoView)
        self.infoView.delegate = self
        self.infoView.isHidden = true
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
            statusTextView.isHidden = true
            etaContainerView.isHidden = true
            countContainerView.isHidden = true
            trackerStatusContainer.isHidden = true
            surveyContainer.isHidden = true
            powerOnContainer.isHidden = true
            
            if viewModel.isActiveOutage == false {
                powerOnContainer.isHidden = false
                progressAnimationView.configure(withStatus: .restored)
            } else {
                progressAnimationView.configure(withStatus: viewModel.status)
                
                statusTextView.isHidden = false
                statusTextView.configure(withTitle: viewModel.statusTitle, detail: viewModel.statusDetails, status: viewModel.status)
                
                if viewModel.status != .none {
                    etaContainerView.isHidden = false
                    countContainerView.isHidden = false
                    trackerStatusContainer.isHidden = false
                    surveyContainer.isHidden = false
                    
                    if viewModel.status == .restored {
                        countContainerView.isHidden = true
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
                        trackerStatusView.configure(withEvents: viewModel.events, lastUpdated: viewModel.lastUpdated, isPaused: viewModel.isPaused)
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
        etaDetailLabel.text = viewModel.etaDetail
        
        etaCauseLabel.text = viewModel.etaCause
        etaCauseLabel.isHidden = viewModel.etaCause.isEmpty
        etaCauseLabel.font = SystemFont.bold.of(textStyle: .footnote)
        
        etaDetailLabel.isHidden = false
        etaInfoButtonView.isHidden = false
        etaUpdatedView.isHidden = true
        
        switch viewModel.status {
            case .onSite:
                etaDetailLabel.text = viewModel.etaOnSiteDetail
            case .restored, .none:
                etaDetailLabel.isHidden = true
                etaInfoButtonView.isHidden = true
                etaCauseLabel.font = SystemFont.regular.of(textStyle: .footnote)
            default:
                break
        }
        if let detailText = etaDetailLabel.text, !detailText.isEmpty {
            etaUpdatedView.isHidden = viewModel.hideETAUpdatedIndicator(detailText: detailText)
        }
    }
    
    private func reportOutage() {
        let storyboard = UIStoryboard(name: "Outage", bundle: Bundle.main)
        if let reportOutageVC = storyboard.instantiateViewController(withIdentifier: "ReportOutageViewController") as?  ReportOutageViewController {
            if let outageStatus = viewModel.outageStatus.value {
                reportOutageVC.viewModel.outageStatus = outageStatus
                reportOutageVC.viewModel.phoneNumber.accept(outageStatus.contactHomeNumber ?? "")
                navigationController?.pushViewController(reportOutageVC, animated: true)
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
            info = viewModel.isDefinitive ? StatusInfoMessage.hasOutageDef : StatusInfoMessage.hasOutageNondef
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
        reportOutage()
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
