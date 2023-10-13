//
//  AlertsViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 11/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class AlertsViewController: AccountPickerViewController {
    
    private let disposeBag = DisposeBag()

    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!
    
    @IBOutlet weak var topStackView: UIStackView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var preferencesButton: ButtonControl!
    @IBOutlet weak var preferencesButtonLabel: UILabel!
    @IBOutlet weak var alertsEmptyStateView: UIView!
    @IBOutlet weak var alertsEmptyStateLabel: UILabel!
    
    var shortcutToPrefs = false
    
    override var defaultStatusBarStyle: UIStatusBarStyle { return .darkContent }
    
    let viewModel = AlertsViewModel()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return StormModeStatus.shared.isOn ? .lightContent : .default
    }
    
    // MARK: - Helper
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("My Alerts", comment: "")
        
        tableView.backgroundColor = .white
        tableView.separatorColor = .accentGray
        tableView.isHidden = true
    
        styleViews()
        bindViewModel()
        
        accountPicker.delegate = self
        accountPicker.parentViewController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
          
        tableView.sizeHeaderToFit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shortcutToPrefs = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navController = segue.destination as? UINavigationController, let vc = navController.viewControllers.first as? AlertPreferencesViewController else { return }

        // Modal Dismiss iOS 13
        navController.presentationController?.delegate = vc

        vc.delegate = self
    }
    
    
    // MARK: - Helper
    
    private func styleViews() {
        preferencesButtonLabel.textColor = .actionBrand
        preferencesButtonLabel.font = .subheadlineSemibold
        preferencesButtonLabel.text = NSLocalizedString("Preferences", comment: "")
        preferencesButton.accessibilityLabel = preferencesButtonLabel.text
        
        alertsEmptyStateLabel.textColor = .middleGray
        alertsEmptyStateLabel.font = .headline
        alertsEmptyStateLabel.text = NSLocalizedString("You haven't received any\nnotifications yet.", comment: "")
    }
    
    private func bindViewModel() {
        viewModel.shouldShowAlertsEmptyState.not()
            .drive(alertsEmptyStateView.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.currentAlerts.asDriver()
            .distinctUntilChanged()
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    private func loadAlerts() {
        tableView.isHidden = false
        
        if AccountsStore.shared.accounts.count == 1 {
            accountPicker.isHidden = true
        }
        
        viewModel.fetchAlertsFromDisk()
        
        // Don't push straight to prefs for ComEd/PECO multi-account users
        if shortcutToPrefs && AccountsStore.shared.accounts.count == 1 {
            performSegue(withIdentifier: "preferencesSegue", sender: nil)
        }
        
        shortcutToPrefs = false
    }
    
    @IBAction func onPreferencesButtonTap(_ sender: Any) {
        performSegue(withIdentifier: "preferencesSegue", sender: self)
    }    
}

extension AlertsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentAlerts.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AlertRow.className, for: indexPath) as? AlertRow else { fatalError("Failed to deque cell: \(AlertRow.className)") }
        
        let message = viewModel.currentAlerts.value[indexPath.row].message
        cell.configure(with: message)
        
        return cell
    }
}

extension AlertsViewController: AccountPickerDelegate {
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        loadAlerts()
    }
}

extension AlertsViewController: AlertPreferencesViewControllerDelegate {
    func alertPreferencesViewControllerDidSavePreferences() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.view.showToast(NSLocalizedString("Preferences saved", comment: ""))
        })
    }
}
