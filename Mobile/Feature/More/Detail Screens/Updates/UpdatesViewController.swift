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
        
        style()
        
        bindViewModel()
        
        viewModel.fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    
    // MARK: - Helper
    
    private func style() {
        title = NSLocalizedString("News and Updates", comment: "")
        
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        errorLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorLabel.textColor = .blackText
        errorLabel.text = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")

        updatesEmptyStateLabel.textColor = .middleGray
        updatesEmptyStateLabel.font = OpenSans.regular.of(textStyle: .headline)
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
            UIAccessibility.post(notification: .screenChanged, argument: self?.view)
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

extension UpdatesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentOpcoUpdates.value?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UpdatesTableViewCell.className, for: indexPath) as? UpdatesTableViewCell,
            let opcoUpdates = viewModel.currentOpcoUpdates.value else { return UITableViewCell() }
        
        cell.configure(title: opcoUpdates[indexPath.row].title, detail: opcoUpdates[indexPath.row].message)
        cell.innerContentView.rx.touchUpInside.asDriver()
            .drive(onNext: { [weak self] in
                self?.performSegue(withIdentifier: "UpdatesDetailSegue", sender: indexPath)
            })
            .disposed(by: cell.disposeBag)
        
        return cell
    }
    
}
