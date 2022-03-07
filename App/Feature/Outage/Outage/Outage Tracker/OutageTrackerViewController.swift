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
    @IBOutlet weak var hazardContainerView: UIView!
    @IBOutlet weak var hazardView: UIView!
    @IBOutlet weak var progressAnimationView: StateAnimationView!
    @IBOutlet weak var statusTextView: StatusTextView!
    @IBOutlet weak var whyButtonContainer: UIView!
    @IBOutlet weak var whyButtonView: UIView!
    @IBOutlet weak var whyButton: UIButton!
    @IBOutlet weak var etaContainerView: UIView!
    @IBOutlet weak var etaView: ETAView!
    @IBOutlet weak var countContainerView: UIView!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var neighborCountLabel: UILabel!
    @IBOutlet weak var outageCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewContainer: UIView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    @IBOutlet weak var trackerStatusContainer: UIView!
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    @IBOutlet weak var surveyView: SurveyView!
    @IBOutlet weak var powerOnContainer: UIView!
    
    let disposeBag = DisposeBag()
    var viewModel: OutageTrackerViewModel!
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
        self.viewModel.fetchOutageTracker()
    }
    
    private func configureTableView() {
        let titleDetailCell = UINib(nibName: TitleSubTitleRow.className, bundle: nil)
        tableView.register(titleDetailCell, forCellReuseIdentifier: TitleSubTitleRow.className)
        tableView.separatorStyle = .none
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
        self.whyButtonContainer.isHidden = true
        
        etaView.delegate = self
        surveyView.delegate = self
        
        let whyViewRadius = whyButtonView.frame.size.height / 2
        whyButtonView.roundCorners(.allCorners, radius: whyViewRadius, borderColor: .accentGray, borderWidth: 1.0)
        
        countView.roundCorners(.allCorners, radius: 10, borderColor: .accentGray, borderWidth: 1.0)
        
        hazardView.roundCorners(.allCorners, radius: 10, borderColor: .accentGray, borderWidth: 1.0)
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
            surveyView.isHidden = true
            hazardContainerView.isHidden = true
            
            surveyView.configure(status: viewModel.status)

            if let tracker = viewModel.outageTracker.value {
                var show = tracker.isSafetyHazard ?? false
                if viewModel.status == .restored {
                    show = false
                }
                hazardContainerView.isHidden = !show
            }
            
            if viewModel.isActiveOutage == false {
                powerOnContainer.isHidden = false
                progressAnimationView.configure(withStatus: .restored)
            } else {
                powerOnContainer.isHidden = true
                progressAnimationView.configure(withStatus: viewModel.status)
                
                statusTextView.isHidden = false
                statusTextView.configure(tracker: viewModel.outageTracker.value, status: viewModel.status)
                
                if viewModel.status != .none {
                    etaContainerView.isHidden = false
                    countContainerView.isHidden = false
                    trackerStatusContainer.isHidden = false
                    surveyView.isHidden = false
                    
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
                    
                    logFirebaseEvents()
                }
            }
            
            refreshControl?.endRefreshing()
            setRefreshControlEnabled(enabled: true)
        }
    }
    
    private func logFirebaseEvents() {
        if viewModel.isGasOnly {
            FirebaseUtility.logEvent(.outageTracker(parameters: [.account_gas_only]))
        } else {
            guard let tracker = viewModel.outageTracker.value else { return }
            if viewModel.isActiveOutage == true {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.active_outage]))
            } else {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.power_on]))
            }
            
            if viewModel.status == .restored {
                if viewModel.isDefinitive {
                    FirebaseUtility.logEvent(.outageTracker(parameters: [.power_restored_definitive]))
                } else {
                    FirebaseUtility.logEvent(.outageTracker(parameters: [.power_restored_definitive]))
                }
            } else if viewModel.status == .enRoute && tracker.isCrewDiverted == true {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.crew_en_route_diverted]))
            } else if viewModel.status == .onSite && tracker.isCrewDiverted == true {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.crew_on_site_diverted]))
            }
            
            if tracker.isPartialRestoration == true {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.partial_restoration]))
            }
            
            if tracker.isCrewExtDamage == true {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.extensive_damage]))
            }
            
            if tracker.isSafetyHazard == true {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.safety_hazard]))
            }
            
            if tracker.isMultipleOutage == true {
                FirebaseUtility.logEvent(.outageTracker(parameters: [.nested_outage]))
            }
        }
    }
    
    private func updateETA() {
        guard let tracker = viewModel.outageTracker.value else { return }
        etaView.configure(tracker: tracker, status: viewModel.status)
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
    
    @IBAction func showHazardPressed(_ sender: Any) {
        let info = StatusInfoMessage.hazardMessage
        infoView.configure(withInfo: info)
        infoView.isHidden = false
    }
    
    @IBAction func whyButtonPressed(_ sender: Any) {
        guard let tracker = viewModel.outageTracker.value else { return }
        guard let isCrewLeftSite = tracker.isCrewLeftSite,
              let isCrewDiverted = tracker.isCrewDiverted else {
                  return
              }
        
        var info = StatusInfoMessage.none
        
        if isCrewDiverted {
            info = StatusInfoMessage.rerouted
        }
        if isCrewLeftSite {
            info = StatusInfoMessage.whyStop
        }
        if viewModel.status == .restored {
            info = viewModel.isDefinitive ? StatusInfoMessage.hasOutageDef : StatusInfoMessage.hasOutageNondef
        }
        if info != .none {
            infoView.configure(withInfo: info)
            infoView.isHidden = false
        }
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

extension OutageTrackerViewController: ETAViewDelegate {
    func showInfoView() {
        let info = StatusInfoMessage.etrToolTip
        infoView.configure(withInfo: info)
        infoView.isHidden = false
    }
}

extension OutageTrackerViewController: SurveyViewDelegate {
    func surveySelected(url: URL) {
        let survey = WebViewController(title: NSLocalizedString("", comment: ""),
                                       url: url)
        navigationController?.present(survey, animated: true, completion: nil)
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
        cell.hideSeparator = false
        
        switch indexPath.row {
            case 0:
                cell.configure(image: UIImage(named: "ic_reportoutage"), title: "Report Outage", detail: nil)
            case 1:
                cell.configure(image: #imageLiteral(resourceName: "ic_streetlightoutage"), title: "Report Streetlight Outage", detail: nil)
            case 2:
                cell.configure(image: UIImage(named: "ic_mapoutage"), title: "View Outage Map", detail: nil)
                cell.hideSeparator = true
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
