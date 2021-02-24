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

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as PeakEnergySavingsHistoryViewController:
            vc.accountDetail = accountDetail
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
        programDetailsLabel.textAlignment = .natural
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
            self?.loadingIndicator.isHidden = true
            self?.imageView.isHidden = false
        } failure: { [weak self] error in
            self?.imageView.isHidden = false
            self?.loadingIndicator.isHidden = true
        }
    }
}
