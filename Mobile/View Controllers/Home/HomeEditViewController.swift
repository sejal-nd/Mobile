//
//  HomeEditViewController.swift
//  Mobile
//
//  Created by Samuel Francis on 6/14/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeEditViewController: UICollectionViewController {

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let disposeBag = DisposeBag()
    
    var names = ["Bill", "Usage", "Template"]
    
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
    }
    
    @objc func handleLongGesture(gesture: UIPanGestureRecognizer) {
        guard let collectionView = collectionView else { return }
        
        let offset = gesture.location(in: collectionView).x - collectionView.bounds.width / 2
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            let location = CGPoint(x: gesture.location(in: collectionView).x - offset,
                                   y: gesture.location(in: collectionView).y)
            collectionView.updateInteractiveMovementTargetPosition(location)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension HomeEditViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return names.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditCardCell.className, for: indexPath) as! HomeEditCardCell
        cell.configure(withTitle: names[indexPath.item], canReorder: true, isAlwaysAvailable: names[indexPath.item] != "Usage")
        cell.addRemoveButton.rx.tap.asDriver()
            .drive(onNext: { dLog("ADD") })
            .disposed(by: cell.disposeBag)
        
        let longPressGesture = UIPanGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        cell.gripView.addGestureRecognizer(longPressGesture)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let name = names[sourceIndexPath.item]
        names.remove(at: sourceIndexPath.item)
        names.insert(name, at: destinationIndexPath.item)
    }
}
