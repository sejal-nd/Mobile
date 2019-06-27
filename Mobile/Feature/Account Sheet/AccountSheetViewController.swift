//
//  AccountListViewController.swift
//  XibTest
//
//  Created by Joseph Erlandson on 6/12/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

import UIKit

protocol AccountSelectDelegate: class {
    func didSelectAccount(_ didSelectAccount: Account)
}

class AccountSheetViewController: UIViewController {
    enum SheetLevel {
        case top
        case middle
        case closed
    }
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var bottomSheetView: UIView!
    @IBOutlet weak var gestureView: UIView!
    @IBOutlet weak var handleView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomSheetViewTopConstraint: NSLayoutConstraint!

    /// Passes selection of both account & premise selection to account top bar
    weak var accountSelectDelegate: AccountSelectDelegate?
    
    /// Used for single cell selection
    private var selectedIndexPath: IndexPath?
    
    /// Recalculated on orientation change: `viewWillTransition`
    var defaultHeight = UIScreen.main.bounds.height * 0.55
    
    /// Determines when to "snap" to the top or middle state
    var threshHoldTop = UIScreen.main.bounds.height * 0.3
    /// Determines when to "snap" to the middle or closed state
    var threshHoldClosed = UIScreen.main.bounds.height * 0.7
    
    /// The current Y location of cardView
    var locationInView: CGFloat!
    
    /// Prevents Table `ContentOffset` from moving in scrollView Methods
    var shouldDisableTableScrolling = false
    
    /// Captures distance from `tableView` scroll to prevent unsightly bounch animation
    var initialTableViewContentOffset: CGFloat = 0

    /// Determines location of cardView via cardViewTopConstraint
    var lastSheetLevel: SheetLevel = .middle {
        didSet {
            switch self.lastSheetLevel {
            case .top:
                self.bottomSheetViewTopConstraint.constant = 0
                self.locationInView = 0
            case .middle:
                self.bottomSheetViewTopConstraint.constant = self.defaultHeight
                self.locationInView = self.defaultHeight
                
                // Reset TableView Content Offset
                self.tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: 0), animated: true)
            case .closed:
                let screenHeight = UIScreen.main.bounds.height
                self.bottomSheetViewTopConstraint.constant = screenHeight
                self.locationInView = screenHeight
            }
            
            
            // Animate Bottom Sheet
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.9, options: .curveEaseOut, animations: { [unowned self] in
                self.view.layoutIfNeeded()
            }, completion: nil)

            // Animate Background
            guard lastSheetLevel == .closed else { return }
            UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                self.backgroundView.alpha = 0.0
                }, completion: { [unowned self] _ in
                    self.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    private var accounts = AccountsStore.shared.accounts ?? [Account]()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCardView()
        
        configureTableView()
        
        configureGestures()
        
        hideBottomSheet()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presentBottomSheet()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        threshHoldTop = UIScreen.main.bounds.height * 0.3
        defaultHeight = UIScreen.main.bounds.height * 0.55
        threshHoldClosed = UIScreen.main.bounds.height * 0.7
        
        if lastSheetLevel == .middle {
            lastSheetLevel = .middle
        }
    }

    deinit {
        print("deinit")
    }
    
    
    // MARK: - Actions

    @objc
    private func backgroundTapGesture(_ gestureRecognizer: UIGestureRecognizer) {
        lastSheetLevel = .closed
    }
    
    @objc
    private func tapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        lastSheetLevel = lastSheetLevel == .middle ? .top : .middle
    }

    
    // MARK: - Handle gestures
    
    // Prevents TableView from scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == tableView, shouldDisableTableScrolling else { return }
        tableView.contentOffset.y = 0
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == tableView, shouldDisableTableScrolling else { return }
        targetContentOffset.pointee = scrollView.contentOffset
        shouldDisableTableScrolling = false
    }

    @objc
    private func panGestureDidOccur(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let originView = gestureRecognizer.view else { return }
        let velocityY = gestureRecognizer.velocity(in: tableView).y
        let state = gestureRecognizer.state
        
        switch state {
        case .began:

            // Capture table content offset, prevents jump animation
            if originView == tableView {
                initialTableViewContentOffset = tableView.contentOffset.y
            } else {
                initialTableViewContentOffset = 0
            }
        case .changed:
            let translation = gestureRecognizer.translation(in: bottomSheetView)
            var newLocation = locationInView + translation.y - initialTableViewContentOffset
            
            // Determine which view to animate: Table or Sheet
            let shouldAnimateBottomSheetView: Bool
            if (tableView.contentOffset.y >= 0 && velocityY <= 0 && bottomSheetViewTopConstraint.constant <= 0 && originView == tableView) || (velocityY >= 0 && tableView.contentOffset.y >= 0 && originView == tableView) {
                shouldDisableTableScrolling = false
                shouldAnimateBottomSheetView = false
            } else {
                // Prevents choppiness
                tableView.contentOffset.y = 0
                shouldDisableTableScrolling = true
                shouldAnimateBottomSheetView = true
            }
            
            // Normalize gesture - User could pan from say 2 -> -1 and thus would be stuck at a 2 constraint
            if newLocation < 3  {
                newLocation = 0
            }

            if shouldAnimateBottomSheetView {
                bottomSheetViewTopConstraint.constant = newLocation
                
                // Animate Constraint Change
                UIView.animate(withDuration: 0.1) { [unowned self] in
                    self.view.layoutIfNeeded()
                }
            }
        case .ended, .failed, .cancelled:
            // Commit the desired state of bottom sheet
            let endingLocationInView = bottomSheetViewTopConstraint.constant

            // Handle Velocity
            if velocityY > 300 {
                // Swipe Down
                
                // if end location is past default height, collapse
                if endingLocationInView > defaultHeight {
                    lastSheetLevel = .closed
                } else {
                    lastSheetLevel = lastSheetLevel == .top ? .middle : .closed
                }
            } else if velocityY < -300 {
                // Swipe Up
                lastSheetLevel = .top
            } else {
                // Handle Location
                if endingLocationInView <= threshHoldTop {
                    lastSheetLevel = .top
                } else if endingLocationInView > threshHoldTop && endingLocationInView < threshHoldClosed {
                    lastSheetLevel = .middle
                } else {
                    lastSheetLevel = .closed
                }
            }
        default:
            break
        }
    }
    
    
    // MARK: - Helper
    
    private func configureCardView() {
        bottomSheetView.roundCorners([.topLeft, .topRight], radius: 10.0)
        bottomSheetView.layer.masksToBounds = true
        
        handleView.layer.cornerRadius = handleView.bounds.height / 2

        navigationBar.titleTextAttributes = [NSAttributedString.Key.font: SystemFont.semibold.of(textStyle: .title3)]
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView()
        
        // Determine selected indexPath
        guard let row = accounts.firstIndex(of: AccountsStore.shared.currentAccount) else { return }
        selectedIndexPath = IndexPath(row: row, section: 0)
        tableView.reloadData()
    }
    
    private func configureGestures() {
        // Background Dismiss
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapGesture(_:)))
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureDidOccur(_:)))
        panGesture.delegate = self
        gestureView.addGestureRecognizer(panGesture)
        
        tableView.panGestureRecognizer.addTarget(self, action: #selector(panGestureDidOccur(_:)))
        
        // Tap to Toggle Sheet
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer(_:)))
        tapGesture.delegate = self
        gestureView.addGestureRecognizer(tapGesture)
    }
    
    private func presentBottomSheet() {
        UIView.animate(withDuration: 0.3) { [unowned self] in
            self.backgroundView.alpha = 1.0
        }
        
        lastSheetLevel = .middle
    }
    
    private func hideBottomSheet() {
        // Start with view hidden
        let screenHeight = UIScreen.main.bounds.height
        self.bottomSheetViewTopConstraint.constant = screenHeight
        self.locationInView = screenHeight
    }
}


// MARK: - Table View Delegate

extension AccountSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let account = accounts[indexPath.row]
        if account.isMultipremise {
            let cell = tableView.cellForRow(at: indexPath) as! AccountListRow
            cell.didSelect()
            tableView.beginUpdates()
            tableView.endUpdates()
        } else {
            didSelectIndexPath(indexPath: indexPath)
        }
    }
    
    func didSelectIndexPath(indexPath: IndexPath, shouldAllowSameCellSelection: Bool = false) {
        // Single Cell Selection

        // Same row selected -> return
        if indexPath == selectedIndexPath, !shouldAllowSameCellSelection {
            return
        }
        
        // Toggle old checkmark off and the new one on
        guard let newCell = tableView.cellForRow(at: indexPath) as? AccountListRow else {
            return }
        if newCell.checkmarkImageView.isHidden {
            newCell.checkmarkImageView.isHidden = false
        }
        
        guard let unwrappedSelectedIndexPath = selectedIndexPath, let oldCell = tableView.cellForRow(at: unwrappedSelectedIndexPath) as? AccountListRow else {
            return }
        if !oldCell.checkmarkImageView.isHidden {
            oldCell.checkmarkImageView.isHidden = true
        }
        
        selectedIndexPath = indexPath
        
        // Selection Action
        accountSelectDelegate?.didSelectAccount(accounts[indexPath.row])
        lastSheetLevel = .closed
    }
    
}


// MARK: - Table View Data Source

extension AccountSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountListRow.className, for: indexPath) as! AccountListRow
        let account = accounts[indexPath.row]
        cell.configure(withAccount: account, indexPath: indexPath, selectedIndexPath: selectedIndexPath, delegate: self)
        return cell
    }
}


// MARK: - UIGestureRecognizerDelegate

extension AccountSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension AccountSheetViewController: PremiseSelectDelegate {
    func didSelectPremise(at indexPath: IndexPath) {
        didSelectIndexPath(indexPath: indexPath, shouldAllowSameCellSelection: true)
    }
}
