//
//  WeeklyInsightViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/25/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol WeeklyInsightViewControllerDelegate: class {
    func weeklyInsightViewControllerWillDisappear(_ weeklyInsightViewController: WeeklyInsightViewController)
    func weeklyInsightViewController(_ weeklyInsightViewController: WeeklyInsightViewController, wasDismissedAfterViewingUnread viewedUnread: Bool)
}

class WeeklyInsightViewController: UIViewController {
    
    weak var delegate: WeeklyInsightViewControllerDelegate?
     
    let coreDataManager = GameCoreDataManager()
    
    @IBOutlet weak var segmentedControlContainer: UIView!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var thisWeekDateLabel: UILabel!
    @IBOutlet weak var thisWeekBarView: UIView!
    @IBOutlet weak var thisWeekBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var lastWeekDateLabel: UILabel!
    @IBOutlet weak var lastWeekBarView: UIView!
    @IBOutlet weak var lastWeekBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var mostEnergyLabel: UILabel!
    @IBOutlet weak var leastEnergyLabel: UILabel!
    @IBOutlet weak var billProjectionLabel: UILabel!
    
    @IBOutlet weak var stickyFooterLabel: UILabel!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    let viewModel = WeeklyInsightViewModel()
    
    let bag = DisposeBag()
    
    var viewedUnread = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()

        title = NSLocalizedString("Weekly Insights by LUMI℠", comment: "")
        
        segmentedControl.items = [
            NSLocalizedString("Electric", comment: ""),
            NSLocalizedString("Gas", comment: "")
        ]
        segmentedControlContainer.isHidden = !viewModel.shouldShowSegmentedControl
                
        thisWeekDateLabel.textColor = .neutralDark
        thisWeekDateLabel.font = .footnoteSemibold
        
        thisWeekBarView.layer.cornerRadius = 7.5
        
        lastWeekDateLabel.textColor = .neutralDark
        lastWeekDateLabel.font = .footnoteSemibold
        
        lastWeekBarView.backgroundColor = .accentGray
        lastWeekBarView.layer.cornerRadius = 7.5

        comparisonLabel.textColor = .neutralDark
        comparisonLabel.font = .body
        
        mostEnergyLabel.textColor = .neutralDark
        mostEnergyLabel.font = .body
        
        leastEnergyLabel.textColor = .neutralDark
        leastEnergyLabel.font = .body
        
        billProjectionLabel.textColor = .neutralDark
        billProjectionLabel.font = .body
        
        stickyFooterLabel.textColor = .neutralDark
        stickyFooterLabel.font = .caption1
        stickyFooterLabel.text = NSLocalizedString("This is an estimate and the actual amount may vary based on your energy use, taxes, and fees.", comment: "")
        
        errorLabel.textColor = .neutralDark
        errorLabel.font = .headline
    
        bindViewModel()
        
        viewModel.fetchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        delegate?.weeklyInsightViewControllerWillDisappear(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        delegate?.weeklyInsightViewController(self, wasDismissedAfterViewingUnread: viewedUnread)
    }
    
    func bindViewModel() {
        viewModel.loading.asDriver().not().drive(loadingView.rx.isHidden).disposed(by: bag)
        
        viewModel.errorText.isNil().drive(errorView.rx.isHidden).disposed(by: bag)
        viewModel.errorText.drive(errorLabel.rx.text).disposed(by: bag)
        
        viewModel.shouldShowContent.not().drive(contentContainer.rx.isHidden).disposed(by: bag)
        
        // When data loads (shouldShowContent), add this weekly insight to Core Data
        viewModel.shouldShowContent
            .filter { $0 }
            .withLatestFrom(viewModel.thisWeekEndDate)
            .asObservable()
            .take(1)
            .subscribe(onNext: { [weak self] date in
                guard let self = self, let endDate = date else { return }
                self.viewedUnread = self.coreDataManager.addWeeklyInsight(accountNumber: self.viewModel.accountDetail.accountNumber, endDate: endDate)
            }).disposed(by: bag)
        
        viewModel.thisWeekBarColor.drive(thisWeekBarView.rx.backgroundColor).disposed(by: bag)
        viewModel.thisWeekDateLabelText.drive(thisWeekDateLabel.rx.text).disposed(by: bag)
        viewModel.thisWeekBarWidth.drive(thisWeekBarWidthConstraint.rx.constant).disposed(by: bag)
        
        viewModel.lastWeekDateLabelText.drive(lastWeekDateLabel.rx.text).disposed(by: bag)
        viewModel.lastWeekBarWidth.drive(lastWeekBarWidthConstraint.rx.constant).disposed(by: bag)
        
        viewModel.comparisonLabelText.drive(comparisonLabel.rx.text).disposed(by: bag)
        viewModel.mostEnergyLabelText.drive(mostEnergyLabel.rx.text).disposed(by: bag)
        viewModel.leastEnergyLabelText.drive(leastEnergyLabel.rx.text).disposed(by: bag)
        viewModel.billProjectionLabelText.drive(billProjectionLabel.rx.text).disposed(by: bag)
    }
    
    @IBAction func segmentValueChanged(_ sender: SegmentedControl) {
        viewModel.selectedSegmentIndex.accept(sender.selectedIndex.value)
        viewModel.fetchData()
    }

}
