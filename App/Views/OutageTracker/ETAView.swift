//
//  ETAView.swift
//  EUMobile
//
//  Created by Gina Mullins on 1/11/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

protocol ETAViewDelegate: AnyObject {
    func showInfoView()
}

class ETAView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet weak var etaTitleLabel: UILabel!
    @IBOutlet weak var etaDateTimeLabel: UILabel!
    @IBOutlet weak var etaDetailLabel: UILabel!
    @IBOutlet weak var etaCauseLabel: UILabel!
    @IBOutlet weak var etaUpdatedView: UIView!
    @IBOutlet weak var etaInfoButtonView: UIView!
    
    weak var delegate: ETAViewDelegate?
    
    var hideUpdatedView: Bool = true {
        didSet {
            etaUpdatedView.isHidden = hideUpdatedView
        }
    }
    var hideInfoButtonView: Bool = false {
        didSet {
            etaInfoButtonView.isHidden = hideInfoButtonView
        }
    }
    
    func configure(withETA eta: OutageTrackerETA, status: OutageTracker.Status) {
        etaTitleLabel.text = eta.etaTitle
        etaDateTimeLabel.text = eta.etaDateTime
        etaDetailLabel.text = eta.etaDetail
        etaCauseLabel.text = eta.etaCause
        
        etaCauseLabel.isHidden = eta.etaCause.isEmpty
        etaCauseLabel.font = SystemFont.bold.of(textStyle: .footnote)
        
        hideInfoButtonView = status == .restored
        hideUpdatedView = true
        
        switch status {
            case .restored, .none:
                etaDetailLabel.isHidden = true
                etaCauseLabel.font = SystemFont.regular.of(textStyle: .footnote)
            default:
                break
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.showInfoView()
        }
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
        
        let updatedViewRadius = etaUpdatedView.frame.size.height / 2
        etaUpdatedView.roundCorners(.allCorners, radius: updatedViewRadius, borderColor: .successGreenText, borderWidth: 1.0)
        etaUpdatedView.isHidden = true
    }

}
