//
//  UsageTabCollectionViewDelegate.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/13/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import SafariServices

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
            performSegue(withIdentifier: "usageWebViewSegue", sender: nil)
            // open the Usage web view in a new screen
            dLog("vmud")
        case "PeakRewards":
            // Legacy PeakRewards users will be directed to the "PeakRewards" screen
            // This icon will not be displayed to PeakRewards WiFi (Ecobee) users. They will access the Ecobee web view via the OpCo Template card.
            dLog("pr")
        case "Hourly Pricing":
            guard let accountDetail = viewModel.accountDetail else { return }
            if accountDetail.isHourlyPricing {
                Analytics.log(event: .HourlyPricing,
                              dimensions: [.HourlyPricingEnrollment: "enrolled"])
                performSegue(withIdentifier: "hourlyPricingSegue", sender: nil)
            } else {
                Analytics.log(event: .HourlyPricing,
                              dimensions: [.HourlyPricingEnrollment: "unenrolled"])
                let safariVc = SFSafariViewController.createWithCustomStyle(url: URL(string: "https://hourlypricing.comed.com")!)
                present(safariVc, animated: true, completion: nil)
            }
            // ?? Hourly Pricing card
            dLog("hp")
        case "Top 5 Energy Tips":
            performSegue(withIdentifier: "top5EnergyTipsSegue", sender: nil)
            // Tapping on the "Tips" button will display a full-screen modal with the top 5 OpCo-specific, personalized tips from oPower
            dLog("t5")
        case "My Home Profile":
            performSegue(withIdentifier: "updateYourHomeProfileSegue", sender: nil)
            // Tapping on this button will display a form where users can enter more details about their home to receive better neighbor comparison data
            dLog("myhp")
        case "Smart Energy Rewards":
            performSegue(withIdentifier: "smartEnergyRewardsSegue", sender: nil)
            // Peak Time Savings/Smart Energy Rewards card
            dLog("ser")
        case "Peak Time Savings":
            performSegue(withIdentifier: "smartEnergyRewardsSegue", sender: nil)
            // Peak Time Savings/Smart Energy Rewards card
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
