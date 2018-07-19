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
    @IBOutlet weak var usageScrollView: UIScrollView!
    @IBOutlet weak var compareBillTitlelabel: UILabel! {
        didSet {
            compareBillTitlelabel.font = OpenSans.semibold.of(textStyle: .headline)
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
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Account Picker
        navigationController?.navigationBar.isHidden = true
        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        // Register Collection View XIB Cells
        collectionView.register(UINib.init(nibName: MyUsageCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MyUsageCollectionViewCell.identifier)
        collectionView.register(UINib.init(nibName: UsageToolsCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: UsageToolsCollectionViewCell.identifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadData()
    }
    
    
    // MARK: - Actions
    
    @IBAction func previousBillPress(_ sender: Any) {
    
    }
    
    @IBAction func nextBillPress(_ sender: Any) {
    
    }
    
    
    // MARK: - Helper
    
    private func styleViews() {
        view.backgroundColor = .white
    }
    
    private func reloadData() {
        collectionView.reloadData()
        collectionViewHeight.constant = collectionView.contentSize.height + 16
    }
    
}

extension UsageTabViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        print("Fetch Account Details")
        //viewModel.fetchAccountDetail(isRefresh: false)
    }
    
}
