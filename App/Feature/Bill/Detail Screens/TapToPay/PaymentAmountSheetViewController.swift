
import UIKit
import RxSwift
import RxCocoa


class PaymentAmountSheetViewController: UIViewController {
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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var paymentAmountsStack: UIStackView!
    @IBOutlet weak var bottomSheetViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var doneButton: PrimaryButton!

    @IBOutlet weak var paymentAmountTextField: FloatLabelTextField!
    /// Used for single cell selection
    private var selectedIndexPath: IndexPath?
    
    /// Recalculated on orientation change: `viewWillTransition`
    var defaultHeight = UIScreen.main.bounds.height * 0.40
    
    /// Determines when to "snap" to the top or middle state
    var threshHoldTop = UIScreen.main.bounds.height * 0.6
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
    
    
   var viewModel: TapToPayViewModel!
   var bag = DisposeBag()
    
   private var paymentAmount: Double = 0
   var hasPrecariousOtherAmountBeenSelected = false
   var titleText = NSLocalizedString("Enter Payment Amount", comment: "") // Set to override if necessary
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCardView()
        
        configureTableView()
        
        configureGestures()
        
        hideBottomSheet()
        
        paymentAmountTextField.placeholder = NSLocalizedString("Payment Amount*", comment: "")
        paymentAmountTextField.setKeyboardType(.decimalPad)
        
        viewModel.paymentAmountErrorMessage.asDriver().drive(onNext: { [weak self] errorMessage in
            self?.paymentAmountTextField.setError(errorMessage)
        }).disposed(by: bag)
           
        viewModel.paymentFieldsValid.asDriver().drive(doneButton.rx.isEnabled).disposed(by: bag)

        
        // Select Payment Amount - Radio Button Selection View
        viewModel.shouldShowSelectPaymentAmount.drive(onNext: { [weak self] shouldShow in
            guard let self = self else { return }
            self.paymentAmountsStack.isHidden = !shouldShow
            self.paymentAmountTextField.isHidden = shouldShow
            
            self.paymentAmountsStack.arrangedSubviews.forEach {
                self.paymentAmountsStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            
            if shouldShow {
                let radioControls = self.viewModel.paymentAmounts.map { (amount, subtitle) -> RadioSelectControl in
                    let title = amount?.currencyString ?? NSLocalizedString("Other", comment: "")
                    return RadioSelectControl.create(withTitle: title, subtitle: subtitle, showSeparator: true)
                }
                
                let radioPress = { [weak self] (control: RadioSelectControl, amount: Double?) -> () in
                    guard let self = self else { return }
                    
                    // Only set and animate `isHidden` if the value should change.
                    // Otherwise we get weird animation queue issues 🤷‍♂️
                    let shouldHideOtherTextField = control != radioControls.last
                    if shouldHideOtherTextField != self.paymentAmountTextField.isHidden {
                        if !shouldHideOtherTextField && !self.hasPrecariousOtherAmountBeenSelected {
                            // If user selects "Other", default the payment amount to $0.00. We use `hasPrecariousOtherAmountBeenSelected` to
                            // ensure this only happens once, i.e. if the user enters a custom amount, then selects another radio button,
                            // then selects "Other" again, the previously entered amount should persist.
                            self.hasPrecariousOtherAmountBeenSelected = true
                            self.paymentAmountTextField.textField.text = 0.currencyString
                            self.viewModel.paymentAmount.accept(0)
                        }
                        UIView.animate(withDuration: 0.2) {
                            self.paymentAmountTextField.isHidden = shouldHideOtherTextField
                        }
                    }
                    
                    radioControls.forEach { $0.isSelected = $0 == control }
                    
                    if let amount = amount {
                        self.paymentAmountTextField.textField.resignFirstResponder()
                        self.viewModel.paymentAmount.accept(amount)
                    } else {
                        self.paymentAmountTextField.textField.becomeFirstResponder()
                    }
                }
                
                zip(radioControls, self.viewModel.paymentAmounts.map { $0.0 }).forEach { control, amount in
                    control.rx.touchUpInside.asDriver()
                        .drive(onNext: { radioPress(control, amount) })
                        .disposed(by: control.bag)
                    
                    self.paymentAmountsStack.addArrangedSubview(control)
                }
                
                if let firstControl = radioControls.first, let firstAmount = self.viewModel.paymentAmounts.first?.0 {
                    radioPress(firstControl, firstAmount)
                }
            }
        }).disposed(by: bag)
        
        paymentAmountTextField.textField.rx.text.orEmpty.asObservable()
            .skip(1)
            .subscribe(onNext: { [weak self] entry in
                guard let self = self else { return }
                
                let amount: Double
                let textStr = String(entry.filter { "0123456789".contains($0) })
                if let intVal = Double(textStr) {
                    amount = intVal / 100
                } else {
                    amount = 0
                }
                
                self.paymentAmountTextField.textField.text = amount.currencyString

                self.paymentAmount = amount
                self.viewModel.paymentAmount.accept(amount)
            })
            .disposed(by: bag)
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
        
        threshHoldTop = UIScreen.main.bounds.height * 0.6
        defaultHeight = UIScreen.main.bounds.height * 0.40
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
    
    
    // MARK: - Helper - Sheet
    
    private func configureCardView() {
        backgroundView.accessibilityIdentifier = "Back"
        
        bottomSheetView.layer.masksToBounds = true
        
        handleView.layer.cornerRadius = handleView.bounds.height / 2
        
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.semibold.of(textStyle: .headline)
        titleLabel.text = titleText
    }
    
    private func configureTableView() {
        let walletRow = UINib(nibName: MiniWalletItemRow.className, bundle: nil)
        tableView.register(walletRow, forCellReuseIdentifier: MiniWalletItemRow.className)
        
        let buttonRow = UINib(nibName: ButtonRow.className, bundle: nil)
        tableView.register(buttonRow, forCellReuseIdentifier: ButtonRow.className)
        
        tableView.tableFooterView = UIView()
        
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
    
    @IBAction func doneAction(_ sender: Any) {
        lastSheetLevel = .closed
    }
}

// MARK: - Table View Data Source

extension PaymentAmountSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return .zero
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}


// MARK: - UIGestureRecognizerDelegate

extension PaymentAmountSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UITextFieldDelegate

extension PaymentAmountSheetViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count == 0 { // Allow backspace
            return true
        }
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == paymentAmountTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            
            let numDec = newString.components(separatedBy:".")
            
            if numDec.count > 2 {
                return false
            } else if numDec.count == 2 && numDec[1].count > 2 {
                return false
            }
            
            let containsDecimal = newString.contains(".")
            let containsBackslash = newString.contains("\\")
            
            return (CharacterSet.decimalDigits.isSuperset(of: characterSet) || containsDecimal) && newString.count <= 8 && !containsBackslash
        }
        return true
    }
}
