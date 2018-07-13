//
//  UsageTabViewController.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class UsageTabViewController: UIViewController {
    
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
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register Collection View XIB Cells
        collectionView.register(UINib.init(nibName: MyUsageCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MyUsageCollectionViewCell.identifier)
        collectionView.register(UINib.init(nibName: UsageToolsCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: UsageToolsCollectionViewCell.identifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadData()
    }
    
    
    private func reloadData() {
        collectionView.reloadData()
        collectionViewHeight.constant = collectionView.contentSize.height + 16
    }
    
}
