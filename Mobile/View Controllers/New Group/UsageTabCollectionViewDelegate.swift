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
            print("vmud")
        case "PeakRewards":
            print("pr")
        case "Hourly Pricing":
            print("hp")
        case "Top 5 Energy Tips":
            print("t5")
        case "My Home Profile":
            print("myhp")
        case "Smart Energy Rewards":
            print("ser")
        case "Peak Time Savings":
            print("pts")
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.row {
        case 0:
            return CGSize(width: collectionView.bounds.size.width - 32, height: 110)
        default:
            return CGSize(width: (collectionView.bounds.size.width - 40) / 2, height: 110)
        }
    }
    
}

extension UsageTabViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
}
