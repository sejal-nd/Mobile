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
    
    let defaultNamesOrder = ["Bill", "Usage", "Template", "Projected Bill", "Outage Status", "PeakRewards", "Test1", "Test2"]
    lazy var names = [Array(self.defaultNamesOrder[0..<3]), Array(self.defaultNamesOrder[3...])]
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
            .drive(onNext: {
                
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
                                   y: max(55, min(CGFloat(55 + 70 * (self.names[0].count - 1)), gesture.location(in: collectionView).y)))
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
        return names[section].count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditCardCell.className, for: indexPath) as! HomeEditCardCell
        let name = names[indexPath.section][indexPath.item]
        let otherSection = (indexPath.section + 1) % 2
        
        cell.configure(withTitle: name,
                       canReorder: indexPath.section == 0,
                       canRemove: indexPath.section == 0,
                       isAlwaysAvailable: name != "Usage")
        
        let removeTapped = { [weak self] in
            guard let `self` = self else { return }
            let sourceIndexPath = IndexPath(item: self.names[indexPath.section].index(of: name)!, section: indexPath.section)
            self.names[indexPath.section].remove(at: sourceIndexPath.item)
            
            self.names[otherSection].append(name)
            let destinationIndexPath = IndexPath(item: self.names[otherSection].count - 1, section: otherSection)
            
            self.collectionView?.performBatchUpdates({
                self.collectionView?.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            }, completion: { success in
                guard success else { return }
                self.collectionView?.reloadItems(at: [destinationIndexPath])
            })
        }
        
        let addTapped = { [weak self] in
            guard let `self` = self else { return }
            let sourceIndexPath = IndexPath(item: self.names[indexPath.section].index(of: name)!, section: indexPath.section)
            self.names[indexPath.section].remove(at: sourceIndexPath.item)
            self.names[otherSection].append(name)
            let destinationIndexPath = IndexPath(item: self.names[otherSection].count - 1, section: otherSection)
            
            self.collectionView?.performBatchUpdates({
                self.collectionView?.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            }, completion: { success in
                guard success else { return }
                self.collectionView?.reloadItems(at: [destinationIndexPath])
            })
        }
        
        if indexPath.section == 0 {
            cell.addRemoveButton.rx.tap.asDriver().drive(onNext: removeTapped).disposed(by: cell.disposeBag)
        } else {
            cell.addRemoveButton.rx.tap.asDriver().drive(onNext: addTapped).disposed(by: cell.disposeBag)
        }
        
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
        let name = names[sourceIndexPath.section][sourceIndexPath.item]
        names[sourceIndexPath.section].remove(at: sourceIndexPath.item)
        names[destinationIndexPath.section].insert(name, at: destinationIndexPath.item)
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
            return CGSize(width: collectionView.bounds.size.width, height: 67)
        default:
            return CGSize(width: collectionView.bounds.size.width, height: 15)
        }
    }
    
}
