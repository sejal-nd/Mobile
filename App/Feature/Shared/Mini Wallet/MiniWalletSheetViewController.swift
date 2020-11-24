//
//  MiniWalletSheetViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/25/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

protocol MiniWalletSheetViewControllerDelegate: class {
    func miniWalletSheetViewController(_ miniWalletSheetViewController: MiniWalletSheetViewController, didSelect walletItem: WalletItem)
    func miniWalletSheetViewControllerDidSelectAddBank(_ miniWalletSheetViewController: MiniWalletSheetViewController)
    func miniWalletSheetViewControllerDidSelectAddCard(_ miniWalletSheetViewController: MiniWalletSheetViewController)
}

class MiniWalletSheetViewController: UIViewController {
    enum SheetLevel {
        case top
        case middle
        case closed
    }
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var bottomSheetView: UIView!
    @IBOutlet weak var gestureView: UIView!
    @IBOutlet weak var handleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableHeaderLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomSheetViewTopConstraint: NSLayoutConstraint!

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
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.9, options: .curveEaseOut, animations: { [weak self] in
                self?.view.layoutIfNeeded()
                }, completion: nil)
            
            // Animate Background
            guard lastSheetLevel == .closed else { return }
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.backgroundView.alpha = 0.0
            }, completion: { [weak self] _ in
                self?.dismiss(animated: false, completion: nil)
            })
        }
    }
    
    
    let viewModel = MiniWalletSheetViewModel()
    
    weak var delegate: MiniWalletSheetViewControllerDelegate?
    
    var isBankAccountDisabled: Bool {
        return accountDetail.isCashOnly
    }
    var isCreditCardDisabled = false // Disabled from BGE AutoPay
    var allowTemporaryItems = true // Disabled from BGE AutoPay
    var accountDetail: AccountDetail!
    var titleText = NSLocalizedString("Select Payment Method", comment: "") // Set to override if necessary
    var tableHeaderText: String? = Environment.shared.opco.isPHI ? NSLocalizedString("We accept: VISA, MasterCard, Discover and American Express Credit Cards or Check Cards.", comment: "") : NSLocalizedString("We accept: Amex, Discover, MasterCard, Visa Credit Cards or Check Cards, and ATM Debit Cards with a PULSE, STAR, NYCE, or ACCEL logo.", comment: "") // Set to override if necessary
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCardView()
        
        configureTableView()
        
        configureGestures()
        
        style()
        
        hideBottomSheet()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
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

    // MARK: - Actions - Sheet
    
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
                UIView.animate(withDuration: 0.1) { [weak self] in
                    self?.view.layoutIfNeeded()
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
    
    
    // MARK: - Helper - Sheet
    
    private func configureCardView() {
        backgroundView.accessibilityIdentifier = "Back"
        
        bottomSheetView.layer.masksToBounds = true
        
        handleView.layer.cornerRadius = handleView.bounds.height / 2
        
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.semibold.of(textStyle: .headline)
        titleLabel.text = titleText
        tableHeaderLabel.text = tableHeaderText
    }
    
    private func configureTableView() {
        let walletRow = UINib(nibName: MiniWalletItemRow.className, bundle: nil)
        tableView.register(walletRow, forCellReuseIdentifier: MiniWalletItemRow.className)
        
        let buttonRow = UINib(nibName: ButtonRow.className, bundle: nil)
        tableView.register(buttonRow, forCellReuseIdentifier: ButtonRow.className)
        
        tableView.accessibilityIdentifier = "miniWalletTableView"
        
        tableView.tableFooterView = UIView()
        
        // Determine selected indexPath
        if let selectedWalletItem = viewModel.selectedWalletItem,
            let row = viewModel.tableViewWalletItems.firstIndex(of: selectedWalletItem) {
            selectedIndexPath = IndexPath(row: row, section: 0)
        }
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
    
    private func style() {
        tableHeaderLabel.textColor = .deepGray
        tableHeaderLabel.font = SystemFont.regular.of(textStyle: .caption1)
    }
    
    private func presentBottomSheet() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.backgroundView.alpha = 1.0
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

extension MiniWalletSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        let walletItems = viewModel.tableViewWalletItems
        
        if walletItems.count - 1 >= indexPath.row { // Wallet Item
            let walletItem = walletItems[indexPath.row]

            guard !walletItem.isExpired else { return }
            
            if walletItem.bankOrCard == .card && !isCreditCardDisabled {
                // Card
                didSelectWalletItem(walletItem, at: indexPath)
            } else if walletItem.bankOrCard == .bank && !isBankAccountDisabled {
                // Bank
                didSelectWalletItem(walletItem, at: indexPath)
            } else {
                // Disabled
                return
            }
        } else if walletItems.count == indexPath.row && !isBankAccountDisabled { // Bank Button
            lastSheetLevel = .closed // Close Sheet
            delegate?.miniWalletSheetViewControllerDidSelectAddBank(self)
        } else if walletItems.count + 1 == indexPath.row && !isCreditCardDisabled { // Card Button
            lastSheetLevel = .closed // Close Sheet
            delegate?.miniWalletSheetViewControllerDidSelectAddCard(self)
        }
    }
    
    func didSelectWalletItem(_ walletItem: WalletItem, at indexPath: IndexPath) {
        // Toggle new checkmark on
        guard let newCell = tableView.cellForRow(at: indexPath) as? MiniWalletItemRow else {
            return }
        if newCell.checkmarkImageView.isHidden {
            newCell.checkmarkImageView.isHidden = false
        }

        // Toggle old checkmark off
        if let unwrappedSelectedIndexPath = selectedIndexPath,
            let oldCell = tableView.cellForRow(at: unwrappedSelectedIndexPath) as? MiniWalletItemRow {
            if !oldCell.checkmarkImageView.isHidden {
                oldCell.checkmarkImageView.isHidden = true
            }
        }
        
        selectedIndexPath = indexPath
        
        // Only trigger delegate if not the editing item
        if walletItem != viewModel.editingWalletItem {
            delegate?.miniWalletSheetViewController(self, didSelect: walletItem)
        }
        
        // Close Sheet
        lastSheetLevel = .closed
    }
    
}


// MARK: - Table View Data Source

extension MiniWalletSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tableViewWalletItems.count + 2 // + 2 for Button Rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let walletItems = viewModel.tableViewWalletItems
        if walletItems.count - 1 >= indexPath.row { // Wallet Item
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MiniWalletItemRow.className, for: indexPath) as? MiniWalletItemRow else { fatalError("Incorrect Cell Type") }
            cell.configure(with: walletItems[indexPath.row],
                           isCreditCardDisabled: isCreditCardDisabled,
                           isBankAccountDisabled: isBankAccountDisabled,
                           indexPath: indexPath,
                           selectedIndexPath: selectedIndexPath)
            return cell
        } else if walletItems.count == indexPath.row { // Bank Button
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ButtonRow.className, for: indexPath) as? ButtonRow else { fatalError("Incorrect Cell Type") }
            cell.configure(image: UIImage(named: "ic_add"), title: "Add Bank Account", isEnabled: !isBankAccountDisabled)
            return cell
        } else if walletItems.count + 1 == indexPath.row { // Card Button
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ButtonRow.className, for: indexPath) as? ButtonRow else { fatalError("Incorrect Cell Type") }
            cell.configure(image: UIImage(named: "ic_add"), title: "Add Credit/Debit Card", isEnabled: !isCreditCardDisabled)
            return cell
        } else {
            fatalError("Invalid IndexPath")
        }
    }
}


// MARK: - UIGestureRecognizerDelegate

extension MiniWalletSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
