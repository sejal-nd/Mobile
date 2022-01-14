//
//  SurveyView.swift
//  EUMobile
//
//  Created by Gina Mullins on 1/14/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

protocol SurveyViewDelegate: AnyObject {
    func surveySelected(url: URL)
}

class SurveyView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var feedbackLabel: UILabel!
    @IBOutlet private weak var surveyButton: UIButton!
    @IBOutlet private weak var topBarView: UIView!
    @IBOutlet private weak var bottomBarView: UIView!
    
    weak var delegate: SurveyViewDelegate?
    var status: OutageTracker.Status?
    
    var isStormMode: Bool {
        return StormModeStatus.shared.isOn
    }
    
    var surveyURL: String {
        guard let status = self.status else { return "" }
        switch status {
            case .reported:
                return "https://www.surveymonkey.com/r/HHCD7YP"
            case .assigned:
                return "https://www.surveymonkey.com/r/HPSN8XX"
            case .enRoute:
                return "https://www.surveymonkey.com/r/HPTDG6T"
            case .onSite:
                return "https://www.surveymonkey.com/r/HPXXPCW"
            case .restored:
                return "https://www.surveymonkey.com/r/HPXZBBD"
            default:
                return ""
        }
    }
    
    func configure(status: OutageTracker.Status) {
        self.status = status
        if isStormMode {
            feedbackLabel.textColor = .white
            surveyButton.setTitleColor(.white, for: .normal)
            topBarView.backgroundColor = UIColor(white: 1, alpha: 0.3)
            bottomBarView.backgroundColor = UIColor(white: 1, alpha: 0.3)
        } else {
            feedbackLabel.textColor = .blackText
            surveyButton.setTitleColor(.actionBlue, for: .normal)
            topBarView.backgroundColor = .accentGray
            bottomBarView.backgroundColor = .clear
        }
    }

    @IBAction func surveyButtonPressed(_ sender: Any) {
        guard let url = URL(string: surveyURL) else { return }
        guard let delegate = delegate else { return }
        delegate.surveySelected(url: url)
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
