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
        return viewModel.usageToolCards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let usageToolCard = viewModel.usageToolCards[indexPath.row]
        
        switch indexPath.row {
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyUsageCollectionViewCell.identifier, for: indexPath) as? MyUsageCollectionViewCell else { return UICollectionViewCell() }
            cell.configureCell(myUsageToolCard: usageToolCard)
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UsageToolsCollectionViewCell.identifier, for: indexPath) as? UsageToolsCollectionViewCell else { return UICollectionViewCell() }
            cell.configureCell(myUsageToolCard: usageToolCard)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let usageToolCard = viewModel.usageToolCards[indexPath.row]
        
        switch usageToolCard.title {
        case "View My Usage Data":
            dLog("vmud")
        case "PeakRewards":
            dLog("pr")
        case "Hourly Pricing":
            dLog("hp")
        case "Top 5 Energy Tips":
            dLog("t5")
        case "My Home Profile":
            dLog("myhp")
        case "Smart Energy Rewards":
            dLog("ser")
        case "Peak Time Savings":
            dLog("pts")
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.row {
        case 0:
            return CGSize(width: collectionView.bounds.width, height: 110)
        default:
            return CGSize(width: (collectionView.bounds.width - 10) / 2, height: 110)
        }
    }
    
}

extension UsageTabViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
}
