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

    @IBOutlet weak var updatesTableView: UITableView!
    @IBOutlet weak var updatesEmptyStateView: UIView!
    @IBOutlet weak var updatesEmptyStateLabel: UILabel!

    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var errorLabel: UILabel!

    //override var defaultStatusBarStyle: UIStatusBarStyle { return .lightContent }

    let viewModel = UpdatesViewModel(accountService: ServiceFactory.createAccountService(), alertsService: ServiceFactory.createAlertsService())

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .softGray
        
        //updatesTableView.backgroundColor = .softGray
        //updatesTableView.contentInset = UIEdgeInsetsMake(22, 0, 22, 0)

        styleViews()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let navController = navigationController as? MainBaseNavigationController else {
            return
        }

        navController.setColoredNavBar(hidesBottomBorder: true)
    }

    private func styleViews() {
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

        viewModel.shouldShowUpdatesTableView.not().drive(updatesTableView.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowUpdatesEmptyState.not().drive(updatesEmptyStateView.rx.isHidden).disposed(by: disposeBag)

        viewModel.reloadUpdatesTableViewEvent.asObservable().subscribe(onNext: { [weak self] in
            self?.updatesTableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.a11yScreenChangedEvent.asObservable().subscribe(onNext: { [weak self] in
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self?.view)
        }).disposed(by: disposeBag)
    }

    @objc func onUpdateCellTap(sender: ButtonControl) {
        performSegue(withIdentifier: "opcoUpdateDetailSegue", sender: sender) // this should be moved into did select row
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? OpcoUpdateDetailViewController, let button = sender as? ButtonControl {
            vc.opcoUpdate = viewModel.currentOpcoUpdates.value![button.tag]
        }
    }

}

extension UpdatesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        if let opcoUpdates = viewModel.currentOpcoUpdates.value {
            return opcoUpdates.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == updatesTableView {
            return 1
        }
        return 0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == updatesTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpdatesCell", for: indexPath) as! UpdatesTableViewCell
            cell.titleLabel.text = viewModel.currentOpcoUpdates.value![indexPath.section].title
            cell.detailLabel.text = viewModel.currentOpcoUpdates.value![indexPath.section].message

            cell.innerContentView.tag = indexPath.section
            cell.innerContentView.removeTarget(self, action: nil, for: .touchUpInside) // Must do this first because of cell reuse
            cell.innerContentView.addTarget(self, action: #selector(onUpdateCellTap(sender:)), for: .touchUpInside)

            cell.innerContentView.accessibilityLabel = "\(cell.titleLabel.text ?? ""): \(cell.detailLabel.text ?? "")"

            return cell
        }
        return UITableViewCell()
    }
}
