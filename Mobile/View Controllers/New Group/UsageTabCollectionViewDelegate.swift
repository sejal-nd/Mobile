//
//  UsageTabCollectionViewDelegate.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

extension UsageTabViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.row {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyUsageCollectionViewCell.identifier, for: indexPath) as? MyUsageCollectionViewCell else { return UICollectionViewCell() }
            cell.configureCell(title: "Hello World", image: #imageLiteral(resourceName: "ic_commercial_mini_disabled"))
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UsageToolsCollectionViewCell.identifier, for: indexPath) as? UsageToolsCollectionViewCell else { return UICollectionViewCell() }
            cell.configureCell(title: "Hello World", image: #imageLiteral(resourceName: "ic_commercial_mini_disabled"))
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            break
        case 1:
            break
        case 2:
            break
        case 3:
            break
        case 4:
            break
        default:
            break
        }
    }
    
}
