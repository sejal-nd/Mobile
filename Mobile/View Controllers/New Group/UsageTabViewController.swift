//
//  UsageTabViewController.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UsageTabViewController: AccountPickerViewController {
    
    @IBOutlet weak var backgroundScrollConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var segmentControl: BillAnalysisSegmentedControl! {
        didSet {
            segmentControl.leftLabel.text = "Electric"
            segmentControl.rightLabel.text = "Gas"
        }
    }
    
    @IBOutlet weak var compareBillTitlelabel: UILabel! {
        didSet {
            compareBillTitlelabel.font = OpenSans.semibold.of(textStyle: .headline)
        }
    }
    
    @IBOutlet weak var leftGraphView: UIView! {
        didSet {
            leftGraphView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet weak var centerGraphView: UIView! {
        didSet {
            centerGraphView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet weak var rightGraphBackgroundView: UIView! {
        didSet {
            rightGraphBackgroundView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet weak var rightGraphForegroundImageView: UIImageView! {
        didSet {
            rightGraphForegroundImageView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet weak var leftGraphButton: UIButton! {
        didSet {
            leftGraphButton.layer.cornerRadius = 16
            leftGraphButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    
    @IBOutlet weak var rightGraphButton: UIButton! {
        didSet {
            rightGraphButton.layer.cornerRadius = 16
            rightGraphButton.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        }
    }
    
    @IBOutlet weak var myUsageToolsLabel: UILabel! {
        didSet {
            myUsageToolsLabel.font = OpenSans.semibold.of(size: 18)
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
        }
    }
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!

    // Bill Graph
    @IBOutlet weak var billGraphDetailView: UIView! {
        didSet {
            billGraphDetailView.layer.cornerRadius = 10
            billGraphDetailView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0.0, height: 2.0), radius: 4)
        }
    }
    
    @IBOutlet weak var barGraphStackView: UIStackView!
    @IBOutlet weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noDataContainerButton: ButtonControl!
    @IBOutlet weak var noDataDateLabel: UILabel! {
        didSet {
            noDataDateLabel.font = OpenSans.semibold.of(size: 14)
            noDataDateLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var previousContainerButton: ButtonControl!
    @IBOutlet weak var previousBarView: UIView!
    @IBOutlet weak var previousBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var previousMonthGraphValueLabel: UILabel! {
        didSet {
            previousMonthGraphValueLabel.font = OpenSans.semibold.of(size: 14)
            previousMonthGraphValueLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var previousMonthGraphDateLabel: UILabel! {
        didSet {
            previousMonthGraphDateLabel.font = OpenSans.semibold.of(size: 14)
            previousMonthGraphDateLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var currentContainerButton: ButtonControl!
    @IBOutlet weak var currentBarView: UIView!
    @IBOutlet weak var currentBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentMonthGraphValueLabel: UILabel! {
        didSet {
            currentMonthGraphValueLabel.font = OpenSans.semibold.of(size: 14)
            currentMonthGraphValueLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var currentMonthGraphDateLabel: UILabel! {
        didSet {
            currentMonthGraphDateLabel.font = OpenSans.semibold.of(size: 14)
            currentMonthGraphDateLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var projectedContainerButton: ButtonControl!
    @IBOutlet weak var projectedBarImageView: UIImageView!
    @IBOutlet weak var projectedBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextMonthGraphValueLabel: UILabel! {
        didSet {
            nextMonthGraphValueLabel.font = OpenSans.semibold.of(size: 14)
            nextMonthGraphValueLabel.textColor = .deepGray
        }
    }
    @IBOutlet weak var nextMonthGraphDateLabel: UILabel! {
        didSet {
            nextMonthGraphDateLabel.font = OpenSans.semibold.of(size: 14)
            nextMonthGraphDateLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var projectionNotAvailableContainerButton: ButtonControl!
    @IBOutlet weak var projectedNotAvailableDateLabel: UILabel! {
        didSet {
            projectedNotAvailableDateLabel.font = OpenSans.semibold.of(size: 14)
            projectedNotAvailableDateLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var projectedNotAvailableDaysRemainingLabel: UILabel! {
        didSet {
            projectedNotAvailableDaysRemainingLabel.font = OpenSans.semibold.of(size: 14)
            projectedNotAvailableDaysRemainingLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var graphDetailDateLabel: UILabel! {
        didSet {
            graphDetailDateLabel.font = OpenSans.semibold.of(size: 14)
            graphDetailDateLabel.textColor = .blackText
        }
    }
    
    @IBOutlet weak var graphDetailTemperatureLabel: UILabel! {
        didSet {
            graphDetailTemperatureLabel.font = OpenSans.regular.of(size: 12)
            graphDetailTemperatureLabel.textColor = .blackText
        }
    }
    
    @IBOutlet weak var graphDetailDescriptionLabel: UILabel! {
        didSet {
            graphDetailDescriptionLabel.font = OpenSans.regular.of(size: 12)
            graphDetailDescriptionLabel.textColor = .black
        }
    }
    
    @IBOutlet weak var previousYearButton: UIButton!
    @IBOutlet weak var nextYearButton: UIButton!
    @IBOutlet weak var dropdownView: BillImpactDropdownView!
    
    private var isViewingCurrentYear = true {
        didSet {
            fetchData()
            
            if isViewingCurrentYear {
                viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 1
                nextYearButton.isEnabled = false
                previousYearButton.isEnabled = true
                
                Analytics.log(event: .BillPreviousToggle)
            } else {
                viewModel.lastYearPreviousBillSelectedSegmentIndex.value = 0
                
                nextYearButton.isEnabled = true
                previousYearButton.isEnabled = false
                
                Analytics.log(event: .BillLastYearToggle)
            }
        }
    }
    
    let disposeBag = DisposeBag()
    
    let viewModel = UsageTabViewModel(accountService: ServiceFactory.createAccountService(), usageService: ServiceFactory.createUsageService())
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Account Picker
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        scrollView?.rx.contentOffset.asDriver()
            .map { min(0, $0.y) }
            .distinctUntilChanged()
            .drive(backgroundScrollConstraint.rx.constant)
            .disposed(by: disposeBag)
        
        // Register Collection View XIB Cells
        collectionView.register(UINib.init(nibName: MyUsageCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MyUsageCollectionViewCell.identifier)
        collectionView.register(UINib.init(nibName: UsageToolsCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: UsageToolsCollectionViewCell.identifier)
        
        bindViewModel()
        dropdownView.configureWithViewModel(viewModel)
        
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        reloadCollectionView()
    }
    
    
    // MARK: - Actions
    
    @IBAction func segmentDidChange(_ sender: BillAnalysisSegmentedControl) {
        dLog("SEGMENT DID CHANGE: \(sender.selectedIndex.value)")
    }
    
    @IBAction func previousBillPress(_ sender: Any) {
        isViewingCurrentYear = false
    }
    
    @IBAction func nextBillPress(_ sender: Any) {
        isViewingCurrentYear = true
    }
    
    @IBAction func barGraphPress(_ sender: ButtonControl) {
        dLog("BAR PRESS")
        let centerPoint = sender.center
        let convertedPoint = barGraphStackView.convert(centerPoint, to: billGraphDetailView)
        
        let centerXOffset = (billGraphDetailView.bounds.width / 2)
        if convertedPoint.x < centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = -1 * (centerXOffset - convertedPoint.x)
        } else if convertedPoint.x > centerXOffset {
            barDescriptionTriangleCenterXConstraint.constant = convertedPoint.x - centerXOffset
        } else {
            barDescriptionTriangleCenterXConstraint.constant = 0
        }
    }
    
    
    // MARK: - Helper
    
    private func styleViews() {
        view.backgroundColor = .white
    }
    
    private func bindViewModel() {
        // Segmented Control
        segmentControl.selectedIndex.asObservable().bind(to: viewModel.electricGasSelectedSegmentIndex).disposed(by: disposeBag)
        segmentControl.selectedIndex.asObservable().skip(1).distinctUntilChanged().subscribe(onNext: { [weak self] index in
            self?.fetchData()
            if index == 0 {
                Analytics.log(event: .BillElectricityToggle)
            } else {
                Analytics.log(event: .BillGasToggle)
            }
        }).disposed(by: disposeBag)
        
        // Graph Selection - todo: no longer a segment control.
//        billComparisonSegmentedControl.selectedIndex.asObservable().bind(to: viewModel.lastYearPreviousBillSelectedSegmentIndex).disposed(by: disposeBag)
//        billComparisonSegmentedControl.selectedIndex.asObservable().skip(1).distinctUntilChanged().subscribe(onNext: { [weak self] index in
//            self?.fetchData()
//            if index == 0 {
//                Analytics.log(event: .BillLastYearToggle)
//            } else {
//                Analytics.log(event: .BillPreviousToggle)
//            }
//        }).disposed(by: disposeBag)
        
        // Bar graph height constraints
        viewModel.previousBarHeightConstraintValue.drive(previousBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.currentBarHeightConstraintValue.drive(currentBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        viewModel.projectedBarHeightConstraintValue.drive(projectedBarHeightConstraint.rx.constant).disposed(by: disposeBag)
        
        // Bar graph corner radius
        viewModel.previousBarHeightConstraintValue.map { min(10, $0/2) }.drive(previousBarView.rx.cornerRadius).disposed(by: disposeBag)
        viewModel.currentBarHeightConstraintValue.map { min(10, $0/2) }.drive(currentBarView.rx.cornerRadius).disposed(by: disposeBag)
        viewModel.projectedBarHeightConstraintValue.map { min(10, $0/2) }.drive(projectedBarImageView.rx.cornerRadius).disposed(by: disposeBag)
        
        // Bar show/hide
        viewModel.noPreviousData.asDriver().not().drive(noDataContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.noPreviousData.asDriver().drive(previousContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowProjectedBar.not().drive(projectedContainerButton.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowProjectionNotAvailableBar.not().drive(projectionNotAvailableContainerButton.rx.isHidden).disposed(by: disposeBag)
        
        // Bar labels
        viewModel.noDataBarDateLabelText.drive(noDataDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.previousBarDollarLabelText.drive(previousMonthGraphValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.previousBarDateLabelText.drive(previousMonthGraphDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.currentBarDollarLabelText.drive(currentMonthGraphValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.currentBarDateLabelText.drive(currentMonthGraphDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDollarLabelText.drive(nextMonthGraphValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDateLabelText.drive(nextMonthGraphDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectedBarDateLabelText.drive(projectedNotAvailableDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.projectionNotAvailableDaysRemainingText.drive(projectedNotAvailableDaysRemainingLabel.rx.text).disposed(by: disposeBag)
        
        // Bar accessibility
        viewModel.noDataBarA11yLabel.drive(noDataContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.previousBarA11yLabel.drive(previousContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.currentBarA11yLabel.drive(currentContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.projectedBarA11yLabel.drive(projectedContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        viewModel.projectionNotAvailableA11yLabel.drive(projectionNotAvailableContainerButton.rx.accessibilityLabel).disposed(by: disposeBag)
        Observable.combineLatest(viewModel.noPreviousData.asObservable(), viewModel.shouldShowProjectedBar.asObservable(), viewModel.shouldShowProjectionNotAvailableBar.asObservable()).map { [weak self] in
            guard let `self` = self else { return }
            var a11yElementArray: [ButtonControl] = []
            if $0.0 {
                a11yElementArray.append(self.noDataContainerButton)
            } else {
                a11yElementArray.append(self.previousContainerButton)
            }
            a11yElementArray.append(self.currentContainerButton)
            if $0.1 {
                a11yElementArray.append(self.projectedContainerButton)
            }
            if $0.2 {
                a11yElementArray.append(self.projectionNotAvailableContainerButton)
            }
            self.barGraphStackView.accessibilityElements = a11yElementArray
            }.subscribe().disposed(by: disposeBag)
        
        // Bar description labels
        viewModel.barDescriptionDateLabelText.drive(graphDetailDateLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionAvgTempLabelText.drive(graphDetailTemperatureLabel.rx.text).disposed(by: disposeBag)
        viewModel.barDescriptionDetailLabelText.drive(graphDetailDescriptionLabel.rx.text).disposed(by: disposeBag)
    }
    
    private func reloadCollectionView() {
        collectionView.reloadData()
        collectionViewHeight.constant = collectionView.collectionViewLayout.collectionViewContentSize.height + 30
        self.view.setNeedsLayout()
    }
    
    private func fetchData() {
//        viewModel.fetchAccountData(onSuccess: { [weak self] in
//            guard let `self` = self else { return }
//            self.reloadCollectionView()
//        })
//
        viewModel.fetchData(onSuccess: { [weak self] in
            
            guard let `self` = self else { return }
            self.reloadCollectionView() // Congfigures bottom cards
         dLog("COMPLETE FETCHED DATA")
        })
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let accountDetail = viewModel.accountDetail else { return }
        
        switch segue.destination {
        case let vc as UsageWebViewController:
            vc.accountDetail = accountDetail
        case let vc as Top5EnergyTipsViewController:
            vc.accountDetail = accountDetail
        case let vc as MyHomeProfileViewController:
            vc.accountDetail = accountDetail
            vc.didSaveHomeProfile
                .delay(0.5)
                .drive(onNext: { [weak self] in
                    self?.view.showToast(NSLocalizedString("Home profile updated", comment: ""))
                })
                .disposed(by: disposeBag)
        case let vc as HourlyPricingViewController:
            vc.accountDetail = accountDetail
        case let vc as TotalSavingsViewController:
            vc.eventResults = accountDetail.serInfo.eventResults
        case let vc as PeakRewardsViewController:
            vc.accountDetail = accountDetail
        default:
            break
        }
    }
    
}

extension UsageTabViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        dLog("Fetch Account Details")
        //viewModel.fetchAccountDetail(isRefresh: false)
    }
    
}
