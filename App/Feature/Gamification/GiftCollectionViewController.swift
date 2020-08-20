//
//  GiftCollectionViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 12/11/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import XLPagerTabStrip

protocol GiftCollectionViewControllerDelegate: class {
    func giftCollectionViewControllerDidChangeGift(_ giftCollectionViewController: GiftCollectionViewController)
}

class GiftCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, IndicatorInfoProvider {
    
    weak var delegate: GiftCollectionViewControllerDelegate?
    
    // Passed into create()
    var giftType: GiftType!
    var index: Int!
    
    var gifts = [Gift]()
    
    let currPoints = UserDefaults.standard.double(forKey: UserDefaultKeys.gamePointsLocal)
    
    var selectedGiftId: String? {
        get {
            switch giftType! {
            case .background:
                return UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedBackground)
            case .hat:
                return UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedHat)
            case .accessory:
                return UserDefaults.standard.string(forKey: UserDefaultKeys.gameSelectedAccessory)
            }
        }
        set {
            switch giftType! {
            case .background:
                UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.gameSelectedBackground)
            case .hat:
                UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.gameSelectedHat)
            case .accessory:
                UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.gameSelectedAccessory)
            }
        }
    }

    static func create(withType type: GiftType, index: Int) -> GiftCollectionViewController {
        let sb = UIStoryboard(name: "Game", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "GiftCollection") as! GiftCollectionViewController
        vc.giftType = type
        vc.index = index
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = giftType.inventoryTitle
        
        gifts = GiftInventory.shared.gifts(ofType: giftType)
        
        // The scroll indicator was extending past the bottom safe area. I figured setting this with bottom = safe area (34)
        // would do the trick, but that made it stop 34 points above the safe area. bottom = 0 produced the same result
        // as the original problem. This works, but I have no idea why. I'd imagine XLPagerTabStrip is messing with things out of our control.
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat.leastNonzeroMagnitude, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // `performBatchUpdates` ensures data is loaded before selection
        collectionView.performBatchUpdates(nil) { _ in
            if let index = self.gifts.firstIndex(where: { $0.id == self.selectedGiftId }) {
                let indexPath = IndexPath(row: index, section: 0)
                self.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        var indicator = IndicatorInfo(title: giftType.inventoryTitle)
        indicator.accessibilityLabel = String.localizedStringWithFormat("%@, %d of 3", giftType.inventoryTitle, index)
        return indicator
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.frame.size.width - 60 // 20 leading/trailing + 10 between items
        if availableWidth < 315 { // Default cell width (105) * 3
            let width = availableWidth / 3
            let height = width * 1.0285714286
            return CGSize(width: width, height: height)
        }
        return CGSize(width: 105, height: 108)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GiftCell", for: indexPath) as! GiftCollectionViewCell

        let gift = gifts[indexPath.row]
        
        if gift.requiredPoints > currPoints {
            cell.thumbImageView.isHidden = true
            cell.isUserInteractionEnabled = false
        } else {
            cell.thumbImageView.image = gift.thumbImage
            cell.thumbImageView.isHidden = false
            cell.isUserInteractionEnabled = true
        }
        
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gift = gifts[indexPath.row]
        
        if gift.id == selectedGiftId { // Deselect
            selectedGiftId = nil
            collectionView.deselectItem(at: indexPath, animated: false)
        } else {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            selectedGiftId = gift.id
            delegate?.giftCollectionViewControllerDidChangeGift(self)
        }
    }

}
