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
    var accountDetail: AccountDetail!

    private lazy var viewModel = PeakEnergySavingsViewModel(accountDetail: self.accountDetail)

    // MARK: - IBOutlets
    
    /// `UILabel` instance of the program Title Label
    @IBOutlet private weak var programTitleLabel: UILabel!
    
    @IBOutlet private weak var borderedBackgroundView: UIView!
    
    @IBOutlet private weak var programDescriptionLabel: UILabel!
    
    @IBOutlet private weak var programSuggestionView: UIView!
    
    @IBOutlet private weak var programSuggestionLabel: UILabel!
    
    @IBOutlet private weak var programInformationBackgroundView: UIView!
    
    @IBOutlet private weak var programActionLabel: UILabel!
    
    @IBOutlet private weak var programActionButton: UIButton!
    
    // MARK: - View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Peak Energy Savings", comment: "")
        programDescriptionLabel.text = viewModel.programDescription
        programSuggestionLabel.text = viewModel.programSuggestion
        programActionLabel.text = NSLocalizedString("Program Information", comment: "")
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
         programActionLabel.textColor = .deepGray
         programActionLabel.font = SystemFont.semibold.of(textStyle: .body)
         borderedBackgroundView.layer.borderColor = UIColor.accentGray.cgColor
         borderedBackgroundView.layer.borderWidth = 1.0
         programSuggestionView.addTopBorder(color: .accentGray, width: 1.0)
         programSuggestionView.addBottomBorder(color: .accentGray, width: 1.0)
         programInformationBackgroundView.addBottomBorder(color: .accentGray, width: 1.0)
        
    }
}
