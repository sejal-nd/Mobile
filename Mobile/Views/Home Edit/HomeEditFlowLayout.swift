//
//  HomeEditFlowLayout.swift
//  Mobile
//
//  Created by Samuel Francis on 6/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

class HomeEditFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        let horizontalInset = max(16.0, (collectionView.bounds.width - 460.0)/2.0)
        collectionView.layoutMargins = UIEdgeInsets(top: 0, left: horizontalInset,
                                                    bottom: 0, right: horizontalInset)
        
        itemSize = CGSize(width: collectionView.bounds.width - collectionView.layoutMargins.left,
                          height: 60)
        
        sectionInset = UIEdgeInsets(top: minimumInteritemSpacing, left: 0, bottom: 0, right: 0)
        
        if #available(iOS 11, *) {
            sectionInsetReference = .fromSafeArea
        }
    }
}
