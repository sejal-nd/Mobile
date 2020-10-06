//
//  PeakEnergySavingsViewController.swift
//  Mobile
//
//  Created by Majumdar, Amit on 25/09/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import UIKit

final class PeakEnergySavingsViewController: DismissableFormSheetViewController {

    // MARK: - Properties
    
    /// `AccountDetail` instance
    var accountDetail: AccountDetail!
    
    /// `PeakEnergySavingsViewModel` instance
    private lazy var viewModel = PeakEnergySavingsViewModel(accountDetail: self.accountDetail)

    // MARK: - IBOutlets
    
    /// `UILabel` instance of the Program Title Label
    @IBOutlet private weak var programTitleLabel: UILabel!
    
    /// `UIView` instance of the Bordered Background View
    @IBOutlet private weak var borderedBackgroundView: UIView!
    
    /// `UILabel` instance of the Program Description Label
    @IBOutlet private weak var programDescriptionLabel: UILabel!
    
    /// `UIView` instance of the Program Suggestion View
    @IBOutlet private weak var programSuggestionView: UIView!

    /// `UILabel` instance of the Program Suggestion Label
    @IBOutlet private weak var programSuggestionLabel: UILabel!
    
    // MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Peak Energy Savings", comment: "")
        programDescriptionLabel.text = viewModel.programDescription
        programSuggestionLabel.text = viewModel.programSuggestion
        styleViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}

// MARK: - PeakEnergySavingsViewController Private Methods
extension PeakEnergySavingsViewController {
    
    /// This function customizes the UI Elements
    private func styleViews() {
        [programTitleLabel, programDescriptionLabel, programSuggestionLabel].forEach {
            $0?.textColor = .deepGray
            $0?.font = SystemFont.regular.of(textStyle: .body)
            $0?.setLineHeight(lineHeight: 24.0)
            $0?.textAlignment = .center
        }
        borderedBackgroundView.layer.borderColor = UIColor.accentGray.cgColor
        borderedBackgroundView.layer.borderWidth = 1.0
        programSuggestionView.addTopBorder(color: .accentGray, width: 1.0)
        programSuggestionView.addBottomBorder(color: .accentGray, width: 1.0)
        let helpButton = UIBarButtonItem(image: UIImage(named: "ic_tooltip"), style: .plain, target: self, action: #selector(onLearnMorePress))
        helpButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        navigationItem.rightBarButtonItem = helpButton
    }
    
    @objc
    func onLearnMorePress() {
        let modalDescription = NSLocalizedString("When the temperature rises in the summer, so does the demand for electricity. The Peak Energy Savings Credit lets you earn a credit off your bill when you reduce your energy use on specially designated Peak Savings Days.", comment: "")
        let infoModal = InfoModalViewController(title: NSLocalizedString("Program Information", comment: ""), image: UIImage(named: "ic_pesc")!, description: modalDescription)
        navigationController?.present(infoModal, animated: true, completion: nil)
    }
}
