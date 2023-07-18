//
//  SurveyView.swift
//  EUMobile
//
//  Created by Gina Mullins on 1/14/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

protocol SurveyViewDelegate: AnyObject {
    func surveySelected()
}

class SurveyView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var feedbackLabel: UILabel!
    @IBOutlet private weak var surveyButton: UIButton!
    @IBOutlet private weak var topBarView: UIView!
    @IBOutlet private weak var bottomBarView: UIView!
    @IBOutlet private weak var buttonBottomConstraint: NSLayoutConstraint!
    
    weak var delegate: SurveyViewDelegate?
    var status: OutageTracker.Status?
    
    var isStormMode: Bool {
        return StormModeStatus.shared.isOn
    }
    
    func configure(status: OutageTracker.Status) {
        self.status = status
        if isStormMode {
            feedbackLabel.textColor = .white
            surveyButton.setTitleColor(.white, for: .normal)
            topBarView.backgroundColor = UIColor(white: 1, alpha: 0.3)
            bottomBarView.backgroundColor = UIColor(white: 1, alpha: 0.3)
            buttonBottomConstraint.constant = 30
        } else {
            feedbackLabel.textColor = .blackText
            surveyButton.setTitleColor(.actionBrand, for: .normal)
            topBarView.backgroundColor = .accentGray
            bottomBarView.backgroundColor = .clear
            buttonBottomConstraint.constant = 10
        }
    }

    @IBAction func surveyButtonPressed(_ sender: Any) {
        guard let delegate = delegate else { return }
        delegate.surveySelected()
    }
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(self.className, owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
