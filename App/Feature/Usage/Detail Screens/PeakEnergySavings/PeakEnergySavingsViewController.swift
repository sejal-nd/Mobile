//
//  PeakEnergySavingsViewController.swift
//  Mobile
//
//  Created by Majumdar, Amit on 25/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

final class PeakEnergySavingsViewController: DismissableFormSheetViewController {

    // MARK: - Properties
    
    /// `AccountDetail` instance
    var accountDetail: AccountDetail!
    
    /// `DisposeBag` instance
    let disposeBag = DisposeBag()
    
    /// `LoadingIndicator` instance
    @IBOutlet weak private var loadingIndicator: LoadingIndicator!
    
    /// `UIImageView` instance
    @IBOutlet weak private var imageView: UIImageView!
    
    // MARK: - IBOutlets
    
    /// `UILabel` instance of the Program Details Label
    @IBOutlet private weak var programDetailsLabel: UILabel!
    
    /// `SERResult` array instance
    var eventResults: [SERResult]? // If nil, fetch from the server
    
    /// `PeakEnergySavingsViewModel` instance
    var viewModel: PeakEnergySavingsViewModel = PeakEnergySavingsViewModel()
        
    // MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Peak Energy Savings", comment: "")
        styleViews()
        fetchBaselineInformation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func peakEnergySavingsHistoryButtonPress(_ sender: Any) {
        let segueIdentifier = FeatureFlagUtility.shared.bool(forKey: .isB2CAuthentication) ? "peakSavingsHistoryB2cSegue" : "peakSavingsHistorySegue"
        performSegue(withIdentifier: segueIdentifier, sender: accountDetail)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as PeakEnergySavingsHistoryViewController:
            vc.accountDetail = accountDetail
        case let vc as B2CUsageWebViewController:
            vc.viewModel.accountDetail = accountDetail
            vc.viewModel.widget = .pesc
        default:
            break
        }
    }
}

// MARK: - PeakEnergySavingsViewController Private Methods
extension PeakEnergySavingsViewController {
    
    /// This function customizes the UI Elements
    private func styleViews() {
        programDetailsLabel.textColor = .deepGray
        programDetailsLabel.font = SystemFont.regular.of(textStyle: .body)
        programDetailsLabel.setLineHeight(lineHeight: 24.0)
        programDetailsLabel.textAlignment = .center
        let helpButton = UIBarButtonItem(image: UIImage(named: "ic_tooltip"), style: .plain, target: self, action: #selector(onLearnMorePress))
        helpButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        navigationItem.rightBarButtonItem = helpButton
        imageView.isHidden = true
    }
    
    @objc
    func onLearnMorePress() {
        let modalDescription = NSLocalizedString("When the temperature rises in the summer, so does the demand for electricity. The Peak Energy Savings Credit lets you earn a credit off your bill when you reduce your energy use on specially designated Peak Savings Days.", comment: "")
        let infoModal = InfoModalViewController(title: NSLocalizedString("Program Information", comment: ""), image: UIImage(named: "ic_pesc")!, description: modalDescription)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    private func fetchBaselineInformation() {
        loadingIndicator.isHidden = false
        viewModel.fetchSERResults(accountNumber: accountDetail.accountNumber) { [weak self] result in
            guard let `self` = self else { return }
            self.renderBaselineInformation(result: result)
            self.loadingIndicator.isHidden = true
            self.imageView.isHidden = false
        } failure: { [weak self] error in
            guard let self = self else { return }
            self.renderBaselineInformation(result: [], error: error)
            self.imageView.isHidden = false
            self.loadingIndicator.isHidden = true
            
        }
    }
    
    /// This method takes in a parameter of an array of `SERResult` and formats the display string and renders the baseline information on UI
    /// - Parameter result: `SERResult` array instance
    /// - Parameter error: `NetworkingError` error instance
    private func renderBaselineInformation(result: [SERResult], error: NetworkingError? = nil) {
        var baselineInformation = ""
        if let _ = error {
            baselineInformation = NSLocalizedString("Please check back for your personalized baseline.", comment: "")
        } else {
            if result.isEmpty {
                //PHI baseline information when there is no events from the API
                baselineInformation = NSLocalizedString("Your Baseline will appear here when a Peak Savings Day is pending.", comment: "")
            } else {
                if let event = result.first {
                    let baselineDay = DateFormatter.dayMonthDayYearFormatter.string(from: event.eventStart)
                    let baselineStartTime = DateFormatter.hmmaFormatter.string(from: event.eventStart)
                    let baselineEndTime = DateFormatter.hmmaFormatter.string(from: event.eventEnd)
                    baselineInformation = NSLocalizedString("Reduce your energy use below \(event.baselineKWH) kWh during the Peak Savings Day on \(baselineDay), from \(baselineStartTime) to \(baselineEndTime). The more you reduce, the greater the opportunity to earn a credit.", comment: "")
                }
            }
        }
        programDetailsLabel.text = baselineInformation
    }
}
