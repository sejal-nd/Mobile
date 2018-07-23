//
//  UsageTabViewController.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class UsageTabViewController: AccountPickerViewController {
    
    // We may be able to remove this.
    @IBOutlet weak var contentView: UIView! {
        didSet {
            //contentView.addShadow(color: .black, opacity: 0.2, offset: .zero, radius: 3)
            //contentView.layer.cornerRadius = 10
        }
    }
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
    @IBOutlet weak var leftGraphButtonView: UIView! {
        didSet {
            leftGraphButtonView.layer.cornerRadius = 16
            leftGraphButtonView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
        }
    }
    @IBOutlet weak var rightGraphButtonView: UIView! {
        didSet {
            rightGraphButtonView.layer.cornerRadius = 16
            rightGraphButtonView.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 6)
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
            billGraphDetailView.addShadow(color: .black, opacity: 0.08, offset: CGSize(width: 0.0, height: 2.0), radius: 8)
        }
    }
    @IBOutlet weak var barGraphStackView: UIStackView!
    @IBOutlet weak var barDescriptionTriangleCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var previousMonthGraphValueLabel: UILabel! {
        didSet {
            previousMonthGraphValueLabel.font = OpenSans.semibold.of(size: 14)
            previousMonthGraphValueLabel.textColor = .deepGray
        }
    }
    @IBOutlet weak var currentMonthGraphValueLabel: UILabel! {
        didSet {
            currentMonthGraphValueLabel.font = OpenSans.semibold.of(size: 14)
            currentMonthGraphValueLabel.textColor = .deepGray
        }
    }
    @IBOutlet weak var nextMonthGraphValueLabel: UILabel! {
        didSet {
            nextMonthGraphValueLabel.font = OpenSans.semibold.of(size: 14)
            nextMonthGraphValueLabel.textColor = .deepGray
        }
    }
    
    @IBOutlet weak var previousMonthGraphDateLabel: UILabel! {
        didSet {
            previousMonthGraphDateLabel.font = OpenSans.semibold.of(size: 14)
            previousMonthGraphDateLabel.textColor = .deepGray
        }
    }
    @IBOutlet weak var currentMonthGraphDateLabel: UILabel! {
        didSet {
            currentMonthGraphDateLabel.font = OpenSans.semibold.of(size: 14)
            currentMonthGraphDateLabel.textColor = .deepGray
        }
    }
    @IBOutlet weak var nextMonthGraphDateLabel: UILabel! {
        didSet {
            nextMonthGraphDateLabel.font = OpenSans.semibold.of(size: 14)
            nextMonthGraphDateLabel.textColor = .deepGray
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
    
    private var isViewingCurrentYear = true {
        didSet {
            if isViewingCurrentYear {
                nextYearButton.isEnabled = false
                previousYearButton.isEnabled = true
            } else {
                nextYearButton.isEnabled = true
                previousYearButton.isEnabled = false
            }
        }
    }
    
    let viewModel = UsageTabViewModel(accountService: ServiceFactory.createAccountService(), usageService: ServiceFactory.createUsageService())
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Account Picker
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        // Register Collection View XIB Cells
        collectionView.register(UINib.init(nibName: MyUsageCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MyUsageCollectionViewCell.identifier)
        collectionView.register(UINib.init(nibName: UsageToolsCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: UsageToolsCollectionViewCell.identifier)
        
        // Load Data
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
        print("SEGMENT DID CHANGE: \(sender.selectedIndex.value)")
    }
    
    @IBAction func previousBillPress(_ sender: Any) {
        isViewingCurrentYear = false
    }
    
    @IBAction func nextBillPress(_ sender: Any) {
        isViewingCurrentYear = true
    }
    
    @IBAction func barGraphPress(_ sender: ButtonControl) {
        print("BAR PRESS")
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
    
    private func reloadCollectionView() {
        collectionView.reloadData()
        collectionViewHeight.constant = collectionView.collectionViewLayout.collectionViewContentSize.height + 16
        self.view.setNeedsLayout()
    }
    
    private func fetchData() {
        viewModel.fetchAccountData(onSuccess: { [weak self] in
            guard let `self` = self else { return }
            self.reloadCollectionView()
        })
    }
    
}

extension UsageTabViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        print("Fetch Account Details")
        //viewModel.fetchAccountDetail(isRefresh: false)
    }
    
}
