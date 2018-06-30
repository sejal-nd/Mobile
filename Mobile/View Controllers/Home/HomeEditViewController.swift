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

fileprivate let topSectionHeaderHeight: CGFloat = 39

class HomeEditViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    
    private let disposeBag = DisposeBag()
    
    let isReordering = Variable(false)
    var reorderingCell: HomeEditCardCell?
    
    lazy var cards: Variable<[[HomeCard]]> = {
        let selectedCards = HomeCardPrefsStore.shared.list
        
        // generate the sorted array of rejected cards
        var rejectedCards = HomeCard.allCards.filter { !selectedCards.contains($0) }
        if rejectedCards.isEmpty {
            rejectedCards.append(.nothing)
        }
        
        return Variable([selectedCards, rejectedCards])
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primaryColor
        collectionView?.backgroundColor = .clear
        collectionView?.collectionViewLayout = HomeEditFlowLayout()
        
        cancelButton.tintColor = .white
        saveButton.tintColor = .white
        
        installsStandardGestureForInteractiveMovement = false
        collectionView?.addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                                          action: #selector(handleDragToReorder(gesture:))))
        
        cancelButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                guard let this = self, !this.isReordering.value else { return }
                HomeCardPrefsStore.shared.list = this.cards.value[0]
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
    
    // MARK - Drag Handling
    
    @objc func handleDragToReorder(gesture: UIGestureRecognizer) {
        guard let collectionView = collectionView else { return }
        
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)), selectedIndexPath.section == 0 else { break }
            isReordering.value = true
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            if let cell = collectionView.cellForItem(at: selectedIndexPath) as? HomeEditCardCell {
                reorderingCell = cell
                transformCardCell(pickUp: true)
            }
        case .changed:
            // Prevent dragging to reorder outside of the first section
            guard let layout = collectionView.collectionViewLayout as? HomeEditFlowLayout else { return }
            let touchLocation = gesture.location(in: collectionView)
            let xOffset = touchLocation.x - collectionView.bounds.width / 2
            let initialYOffset = layout.sectionInset.top + (layout.itemSize.height / 2) + topSectionHeaderHeight
            let rowDistance = layout.minimumLineSpacing + layout.itemSize.height
            let maxYValue = initialYOffset + rowDistance * CGFloat(self.cards.value[0].count - 1)
            
            let location = CGPoint(x: touchLocation.x - xOffset,
                                   y: max(initialYOffset, min(maxYValue, touchLocation.y)))
            
            collectionView.updateInteractiveMovementTargetPosition(location)
        case .ended:
            collectionView.endInteractiveMovement()
            transformCardCell(pickUp: false)
        case .cancelled, .failed:
            collectionView.cancelInteractiveMovement()
            transformCardCell(pickUp: false)
        case .possible:
            break
        }
    }
    
    func transformCardCell(pickUp: Bool) {
        guard let cell = reorderingCell else { return }
        
        if pickUp {
            UIView.animate(withDuration: 0.1) {
                cell.cardView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                cell.cardView.alpha = 0.95
            }
        } else {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.4,
                           initialSpringVelocity: 0.25,
                           options: .curveEaseIn,
                           animations: {
                            cell.cardView.transform = CGAffineTransform(scaleX: 1, y: 1)
                            cell.cardView.alpha = 1
            },
                           completion: { _ in
                            self.isReordering.value = false
                            self.reorderingCell = nil
            })
        }
    }
    
    // MARK: - Collection View Delegate
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return cards.value[section].count + 1
        } else {
            return cards.value[section].count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 && indexPath.item == cards.value[1].count {
            return restoreDefaultCell(collectionView: collectionView, indexPath: indexPath)
        } else if indexPath.section == 1 && cards.value[1][0] == .nothing {
            return collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditEmptyCell.className, for: indexPath)
        } else if 0...1 ~= indexPath.section {
            return editCardCell(collectionView: collectionView, indexPath: indexPath)
        } else {
            fatalError("There should only be 2 sections")
        }
    }
    
    func restoreDefaultCell(collectionView: UICollectionView, indexPath: IndexPath) -> HomeEditRestoreDefaultCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditRestoreDefaultCell.className, for: indexPath) as! HomeEditRestoreDefaultCell
        
        let isEnabled = cards.asDriver().map { $0[0] != HomeCardPrefsStore.defaultList }
            .distinctUntilChanged()
        
        cell.configure(isEnabled: isEnabled,
                       isReordering: isReordering.asDriver(),
                       onTap: { [weak self] in
                        guard let this = self, !this.isReordering.value else { return }
                        
                        let selectedCards = HomeCardPrefsStore.defaultList
                        
                        // generate the sorted array of rejected cards
                        var rejectedCards = HomeCard.allCards.filter { !selectedCards.contains($0) }
                        if rejectedCards.isEmpty {
                            rejectedCards.append(.nothing)
                        }
                        
                        this.cards.value = [selectedCards, rejectedCards]
                        this.collectionView?.reloadData()
        })
        return cell
    }
    
    func editCardCell(collectionView: UICollectionView, indexPath: IndexPath) -> HomeEditCardCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditCardCell.className,
                                                      for: indexPath) as! HomeEditCardCell
        let card = cards.value[indexPath.section][indexPath.item]
        let otherSection = (indexPath.section + 1) % 2
        
        let addRemoveTapped = { [weak self] in
            guard let this = self, !this.isReordering.value else { return }
            
            let sourceIndexPath = IndexPath(item: this.cards.value[indexPath.section].index(of: card)!, section: indexPath.section)
            this.cards.value[indexPath.section].remove(at: sourceIndexPath.item)
            
            let destinationIndex: Int
            if indexPath.section == 0 {
                destinationIndex = this.cards.value[otherSection].enumerated()
                    .first(where: { $1.rawValue > card.rawValue })?.0 ??
                    this.cards.value[otherSection].count
            } else {
                destinationIndex = this.cards.value[otherSection].count
            }
            
            let destinationIndexPath = IndexPath(item: destinationIndex, section: otherSection)
            this.cards.value[otherSection].insert(card, at: destinationIndex)
            
            this.collectionView?.performBatchUpdates({
                this.isReordering.value = true
                this.collectionView?.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            }, completion: { success in
                guard success else { return }
                
                this.collectionView?.performBatchUpdates({
                    this.collectionView?.reloadItems(at: [destinationIndexPath])
                    
                    if this.cards.value[1].isEmpty {
                        this.cards.value[1].append(.nothing)
                        this.collectionView?.reloadSections(IndexSet(integer: 1))
                    } else if this.cards.value[1].last == .nothing {
                        this.cards.value[1].removeLast()
                        this.collectionView?.reloadSections(IndexSet(integer: 1))
                    }
                }, completion: { success in
                    this.isReordering.value = false
                })
            })
        }
        
        cell.configure(withCard: card,
                       isActive: indexPath.section == 0,
                       addRemoveTapped: addRemoveTapped)
        
        cell.gripView.rx.panGesture(minimumNumberOfTouches: 1, maximumNumberOfTouches: 1) { _, delegate in
            delegate.beginPolicy = .custom { [weak self] _ in !(self?.isReordering.value ?? false) }
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
        let name = cards.value[sourceIndexPath.section][sourceIndexPath.item]
        cards.value[sourceIndexPath.section].remove(at: sourceIndexPath.item)
        cards.value[destinationIndexPath.section].insert(name, at: destinationIndexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeEditSectionHeaderView.className, for: indexPath) as! HomeEditSectionHeaderView
            switch indexPath.section {
            case 0:
                headerView.label.text = NSLocalizedString("Cards in Use", comment: "")
            case 1:
                headerView.label.text = NSLocalizedString("Additional Cards", comment: "")
            default:
                headerView.label.text = ""
            }
            return headerView
        default:
            fatalError("\(kind) not supported.")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 1:
            return CGSize(width: collectionView.bounds.size.width - 2 * collectionView.layoutMargins.left,
                          height: 67)
        default:
            return CGSize(width: collectionView.bounds.size.width - 2 * collectionView.layoutMargins.left,
                          height: topSectionHeaderHeight)
        }
    }
    
}
