//
//  TrackerStatusView.swift
//  EUMobile
//
//  Created by Gina Mullins on 12/3/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum TrackerState {
    case open
    case reported
    case complete
    
    var image: UIImage? {
        switch self {
            case .open:
                return UIImage(named: "todo")
            case .reported:
                return UIImage(named: "todo")
            case .complete:
                return UIImage(named: "todo")
        }
    }
}

class TrackerStatusView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var reportedStatusView: StatusView!
    @IBOutlet private weak var assignedStatusView: StatusView!
    @IBOutlet private weak var enRouteStatusView: StatusView!
    @IBOutlet private weak var onSiteStatusView: StatusView!
    @IBOutlet private weak var restoredStatusView: StatusView!
    @IBOutlet private weak var dateLabel: UILabel!
    
    let disposeBag = DisposeBag()
    var trackerStatus = BehaviorRelay<OutageTracker.Status>(value: .none)
    
    func configure() {
        reportedStatusView.configure(withStatus: .reported)
        assignedStatusView.configure(withStatus: .assigned)
        enRouteStatusView.configure(withStatus: .enRoute)
        onSiteStatusView.configure(withStatus: .onSite)
        restoredStatusView.configure(withStatus: .restored)
        
        self.trackerStatus.accept(.reported)
    }
    
    
    public func update(status: OutageTracker.Status) {
        self.trackerStatus.accept(status)
    }
    
    private func setupBinding() {
        self.trackerStatus
            .subscribe(onNext:{ [unowned self] status in
                self.updateUI()
            }).disposed(by: disposeBag)
    }
    
    private func updateUI() {
        let status = trackerStatus.value
        for view in stackView.subviews {
            view.next(status)
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
        contentView.layer.cornerRadius = 2
        contentView.backgroundColor = UIColor.softGray
        
        setupBinding()
        self.trackerStatus.accept(.reported)
    }

}
