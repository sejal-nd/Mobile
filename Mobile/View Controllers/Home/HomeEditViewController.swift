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
    
    lazy var cards: [[HomeCard]] = {
        let selectedCards = HomeCardPrefsStore.shared.list
        
        // generate the sorted array of rejected cards
        var rejectedCards = HomeCard.allCards
        let partitionIndex = rejectedCards.partition(by: { selectedCards.contains($0) })
        rejectedCards.removeSubrange(partitionIndex...)
        rejectedCards.sort { $0.rawValue < $1.rawValue }
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
        
        cancelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        installsStandardGestureForInteractiveMovement = false
        
        saveButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let welf = self else { return }
                HomeCardPrefsStore.shared.list = welf.cards[0]
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
        
        let offset = gesture.location(in: collectionView).x - collectionView.bounds.width / 2
        switch(gesture.state) {
        case .began:
            isReordering = true
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            let location = CGPoint(x: gesture.location(in: collectionView).x - offset,
                                   y: max(55, min(CGFloat(55 + 70 * (self.cards[0].count - 1)), gesture.location(in: collectionView).y)))
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
                guard let welf = self else { return }
                
                let selectedCards = HomeCardPrefsStore.defaultList
                
                // generate the sorted array of rejected cards
                var rejectedCards = HomeCard.allCards
                let partitionIndex = rejectedCards.partition(by: { selectedCards.contains($0) })
                rejectedCards.removeSubrange(partitionIndex...)
                rejectedCards.sort { $0.rawValue < $1.rawValue }
                if rejectedCards.isEmpty {
                    rejectedCards.append(.nothing)
                }
                
                welf.cards = [selectedCards, rejectedCards]
                welf.collectionView?.reloadData()
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
            guard let welf = self else { return }
            let sourceIndexPath = IndexPath(item: welf.cards[indexPath.section].index(of: card)!, section: indexPath.section)
            welf.cards[indexPath.section].remove(at: sourceIndexPath.item)
            
            let destinationIndex: Int
            if indexPath.section == 0 {
                 destinationIndex = welf.cards[otherSection].enumerated()
                    .first(where: { $1.rawValue > card.rawValue })?.0 ??
                    welf.cards[otherSection].count
            } else {
                destinationIndex = welf.cards[otherSection].count
            }
            
            let destinationIndexPath = IndexPath(item: destinationIndex, section: otherSection)
            welf.cards[otherSection].insert(card, at: destinationIndex)
            
            welf.collectionView?.performBatchUpdates({
                welf.collectionView?.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            }, completion: { success in
                guard success else { return }
                welf.collectionView?.reloadItems(at: [destinationIndexPath])
                
                if welf.cards[1].isEmpty {
                    welf.cards[1].append(.nothing)
                    welf.collectionView?.reloadSections(IndexSet(integer: 1))
                } else if welf.cards[1].last == .nothing {
                    welf.cards[1].removeLast()
                    welf.collectionView?.reloadSections(IndexSet(integer: 1))
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
            return CGSize(width: collectionView.bounds.size.width - 2 * collectionView.layoutMargins.left, height: 15)
        }
    }
    
}
