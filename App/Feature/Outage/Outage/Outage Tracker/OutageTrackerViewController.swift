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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var trackerStatusView: TrackerStatusView!
    
    let disposeBag = DisposeBag()
    let viewModel = OutageTrackerViewModel()
    var progressAnimation = AnimationView(name: "outage_reported")
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(loadOutageTracker(sender:)), for: .valueChanged)
        refreshControl.tintColor = .deepGray
        refreshControl.backgroundColor = .softGray
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadOutageTracker()
        configureTableView()
        configureFooterTextView()
        setupUI()
        setupBinding()
    }
    
    @objc
    private func loadOutageTracker(sender: UIRefreshControl? = nil) {
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
        // todo: get colors
        etaView.roundCorners(.allCorners, radius: 10, borderColor: UIColor.bgeGreen, borderWidth: 1.0)
        
        etaUpdatedView.roundCorners(.allCorners, radius: 10, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        
        countView.roundCorners(.allCorners, radius: 10, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
        
        tableView.roundCorners(.allCorners, radius: 0, borderColor: UIColor(red: 216.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1.0), borderWidth: 1.0)
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

// MARK: - Table View Data Source

extension OutageTrackerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = 3
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleSubTitleRow.className, for: indexPath) as? TitleSubTitleRow else { fatalError("Invalid cell type.") }
        cell.backgroundColor = UIColor.systemGray6
        
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
