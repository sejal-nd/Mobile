//
//  UpdatesViewController.swift
//  BGE
//
//  Created by Joseph Erlandson on 8/9/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class UpdatesViewController: UIViewController {

    let disposeBag = DisposeBag()

    @IBOutlet weak var noNetworkConnectionView: NoNetworkConnectionView!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updatesEmptyStateView: UIView!
    @IBOutlet weak var updatesEmptyStateLabel: UILabel!

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!

    let viewModel = UpdatesViewModel(alertsService: ServiceFactory.createAlertsService())

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleViews()
        
        bindViewModel()
        
        viewModel.fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }

    
    // MARK: - Helper
    
    private func styleViews() {
        title = NSLocalizedString("News and Updates", comment: "")
        
        view.backgroundColor = .primaryColor
        
        tableView.contentInset = UIEdgeInsetsMake(8, 0, 8, 0)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")

        updatesEmptyStateLabel.textColor = .middleGray
        updatesEmptyStateLabel.font = OpenSans.regular.of(textStyle: .title1)
        updatesEmptyStateLabel.text = NSLocalizedString("There are no updates at\nthis time.", comment: "")
    }

    private func bindViewModel() {
        noNetworkConnectionView.reload
            .subscribe(onNext: { [weak self] in self?.viewModel.fetchData() })
            .disposed(by: disposeBag)

        viewModel.shouldShowLoadingIndicator.asDriver().not().drive(loadingIndicator.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorLabel.not().drive(errorLabel.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowNoNetworkConnectionView.not().drive(noNetworkConnectionView.rx.isHidden).disposed(by: disposeBag)

        viewModel.shouldShowTableView.not().drive(tableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowUpdatesEmptyState.not().drive(updatesEmptyStateView.rx.isHidden).disposed(by: disposeBag)

        viewModel.reloadTableViewEvent.asObservable().subscribe(onNext: { [weak self] in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.a11yScreenChangedEvent.asObservable().subscribe(onNext: { [weak self] in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self?.view)
        }).disposed(by: disposeBag)
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UpdatesDetailViewController,
            let opcoUpdates = viewModel.currentOpcoUpdates.value,
            let indexPath = sender as? IndexPath {
            vc.opcoUpdate = opcoUpdates[indexPath.row]
        }
    }

}
