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
    @IBOutlet weak var scrollView: UIScrollView!
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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    
    let disposeBag = DisposeBag()
    let viewModel = OutageTrackerViewModel()
    let infoView = StatusInfoView()
    var progressAnimation = AnimationView(name: "outage_reported")
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
        self.viewModel.getOutageTracker {
            print("fetching tracker")
        } onError: { error in
            print("error fetching tracker: \(error.localizedDescription)")
        }
    }
    
    private func configureTableView() {
        let titleDetailCell = UINib(nibName: TitleSubTitleRow.className, bundle: nil)
        tableView.register(titleDetailCell, forCellReuseIdentifier: TitleSubTitleRow.className)
        tableView.accessibilityLabel = "outageTableView"
        tableView.reloadData()
    }
    
    private func configureFooterTextView() {
        // todo  make phone numbers work
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
            })
            .disposed(by: self.disposeBag)
        
        self.viewModel.outageStatus
            .subscribe(onNext: { [weak self] _ in
                self?.reportOutage()
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setupUI() {
        
        infoView.frame = self.view.bounds
        self.view.addSubview(infoView)
        self.infoView.delegate = self
        self.infoView.isHidden = true
        
        etaView.roundCorners(.allCorners, radius: 10, borderColor: .successGreenText, borderWidth: 1.0)
        
        let radius = etaUpdatedView.frame.size.height / 2
        etaUpdatedView.roundCorners(.allCorners, radius: radius, borderColor: .successGreenText, borderWidth: 1.0)
        
        countView.roundCorners(.allCorners, radius: 10, borderColor: .accentGray, borderWidth: 1.0)
        
        tableView.roundCorners(.allCorners, radius: 0, borderColor: .accentGray, borderWidth: 1.0)
    }
    
    private func update() {
        trackerStatusView.configure(withEvents: viewModel.events, lastUpdated: viewModel.lastUpdated)
        statusTitleLabel.text = viewModel.statusTitle
        statusDetailView.isHidden = viewModel.statusDetails.isEmpty
        statusDetailLabel.text = viewModel.statusDetails
        
        updateETA()
        refreshControl?.endRefreshing()
        setRefreshControlEnabled(enabled: true)
    }
    
    private func updateETA() {
        etaTitleLabel.text = viewModel.etaTitle
        etaDateTimeLabel.text = viewModel.etaDateTime
        etaDetailLabel.text = viewModel.etaDetail
        etaCauseLabel.text = viewModel.etaCause
        
        // show/hide info button
        // show/hide update view
        
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
        // todo: determine info
//        etrToolTip
//        hazardMessage
//        rerouted
//        hasOutageDef
//        hasOutageNondef
//        whyStop
        
        let info = StatusInfoMessage.etrToolTip
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
            viewModel.getOutageStatus()
        } else {
            let isStreetMap = indexPath.row == 1
            openOutageMap(forStreetMap: isStreetMap)
        }
    }
}
