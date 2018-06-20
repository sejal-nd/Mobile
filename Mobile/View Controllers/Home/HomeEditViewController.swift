//
//  HomeEditViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 6/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxGesture

class HomeEditViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let disposeBag = DisposeBag()
    let topSectionHeaderHeight: CGFloat = 15
    
    lazy var cards: [[HomeCard]] = {
        let selectedCards = HomeCardPrefsStore.shared.list
        
        // generate the sorted array of rejected cards
        var rejectedCards = HomeCard.allCards.removingAll { selectedCards.contains($0) }
        if rejectedCards.isEmpty {
            rejectedCards.append(.nothing)
        }
        
        return [selectedCards, rejectedCards]
    }()
    
    var isReordering = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primaryColor
        collectionView?.backgroundColor = .clear
        collectionView?.collectionViewLayout = HomeEditFlowLayout()
        
        cancelButton.tintColor = .white
        saveButton.tintColor = .white
        
        cancelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        installsStandardGestureForInteractiveMovement = false
        
        saveButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let this = self else { return }
                HomeCardPrefsStore.shared.list = this.cards[0]
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }
    
    func handleDragToReorder(gesture: UIPanGestureRecognizer) {
        guard let collectionView = collectionView else { return }
        
        switch(gesture.state) {
        case .began:
            isReordering = true
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else { break }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            // Prevent dragging to reorder outside of the first section
            guard let layout = collectionView.collectionViewLayout as? HomeEditFlowLayout else { return }
            let touchLocation = gesture.location(in: collectionView)
            let xOffset = touchLocation.x - collectionView.bounds.width / 2
            let initialYOffset = layout.sectionInset.top + (layout.itemSize.height / 2) + topSectionHeaderHeight
            let rowDistance = layout.minimumLineSpacing + layout.itemSize.height
            let maxYValue = initialYOffset + rowDistance * CGFloat(self.cards[0].count - 1)
            
            let location = CGPoint(x: touchLocation.x - xOffset,
                                   y: max(initialYOffset, min(maxYValue, touchLocation.y)))
            
            collectionView.updateInteractiveMovementTargetPosition(location)
        case .ended:
            isReordering = false
            collectionView.endInteractiveMovement()
        case .cancelled, .failed, .possible:
            isReordering = false
            collectionView.cancelInteractiveMovement()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension HomeEditViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return cards[section].count + 1
        } else {
            return cards[section].count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 && indexPath.item == cards[1].count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditRestoreDefaultCell.className, for: indexPath) as! HomeEditRestoreDefaultCell
            cell.button.rx.tap.asDriver().drive(onNext: { [weak self] in
                guard let this = self else { return }
                
                let selectedCards = HomeCardPrefsStore.defaultList
                
                // generate the sorted array of rejected cards
                var rejectedCards = HomeCard.allCards.removingAll { selectedCards.contains($0) }
                if rejectedCards.isEmpty {
                    rejectedCards.append(.nothing)
                }
                
                this.cards = [selectedCards, rejectedCards]
                this.collectionView?.reloadData()
            }).disposed(by: cell.disposeBag)
            
            return cell
        }
        
        if indexPath.section == 1 && cards[1][0] == .nothing {
            return collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditEmptyCell.className, for: indexPath)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditCardCell.className,
                                                      for: indexPath) as! HomeEditCardCell
        let card = cards[indexPath.section][indexPath.item]
        let otherSection = (indexPath.section + 1) % 2
        
        let addRemoveTapped = { [weak self] in
            guard let this = self else { return }
            let sourceIndexPath = IndexPath(item: this.cards[indexPath.section].index(of: card)!, section: indexPath.section)
            this.cards[indexPath.section].remove(at: sourceIndexPath.item)
            
            let destinationIndex: Int
            if indexPath.section == 0 {
                 destinationIndex = this.cards[otherSection].enumerated()
                    .first(where: { $1.rawValue > card.rawValue })?.0 ??
                    this.cards[otherSection].count
            } else {
                destinationIndex = this.cards[otherSection].count
            }
            
            let destinationIndexPath = IndexPath(item: destinationIndex, section: otherSection)
            this.cards[otherSection].insert(card, at: destinationIndex)
            
            this.collectionView?.performBatchUpdates({
                this.collectionView?.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            }, completion: { success in
                guard success else { return }
                this.collectionView?.reloadItems(at: [destinationIndexPath])
                
                if this.cards[1].isEmpty {
                    this.cards[1].append(.nothing)
                    this.collectionView?.reloadSections(IndexSet(integer: 1))
                } else if this.cards[1].last == .nothing {
                    this.cards[1].removeLast()
                    this.collectionView?.reloadSections(IndexSet(integer: 1))
                }
            })
        }
        
        cell.configure(withCard: card,
                       isActive: indexPath.section == 0,
                       addRemoveTapped: addRemoveTapped)
        
        cell.gripView.rx.panGesture(minimumNumberOfTouches: 1, maximumNumberOfTouches: 1) { _, delegate in
            delegate.beginPolicy = .custom { [weak self] _ in !(self?.isReordering ?? false) }
            delegate.simultaneousRecognitionPolicy = .never
            }
            .asDriver()
            .drive(onNext: { [weak self] in self?.handleDragToReorder(gesture: $0)})
            .disposed(by: cell.disposeBag)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let name = cards[sourceIndexPath.section][sourceIndexPath.item]
        cards[sourceIndexPath.section].remove(at: sourceIndexPath.item)
        cards[destinationIndexPath.section].insert(name, at: destinationIndexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeEditSectionHeaderView.className, for: indexPath) as! HomeEditSectionHeaderView
             headerView.label.isHidden = indexPath.section != 1
            return headerView
        default:
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 1:
            return CGSize(width: collectionView.bounds.size.width - 2 * collectionView.layoutMargins.left, height: 67)
        default:
            return CGSize(width: collectionView.bounds.size.width - 2 * collectionView.layoutMargins.left, height: topSectionHeaderHeight)
        }
    }
    
}
