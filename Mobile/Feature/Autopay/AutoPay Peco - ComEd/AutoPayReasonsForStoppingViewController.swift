//
//  AutoPayReasonsForStoppingViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 8/13/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AutoPayReasonsForStoppingViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var unenerollButton: PrimaryButtonNew!
    
    var viewModel: AutoPayViewModel!
    
    weak var delegate: AutoPayViewControllerDelegate?
    weak var parentVc: AutoPayViewController?
    
    let bag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        style()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeFooterToFit()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel.selectedUnenrollmentReason.value = nil
    }
    
    
    // MARK: - Helper
    
    private func configureView() {
        title = NSLocalizedString("Reason for Stopping", comment: "")
        
        addCloseButton()
        
        // Table View
        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ReasonForStoppingCell")
        tableView.estimatedRowHeight = 51
        
        viewModel.canSubmitUnenroll.drive(unenerollButton.rx.isEnabled).disposed(by: bag)
    }
    
    private func style() {
        footerLabel.textColor = .deepGray
        footerLabel.font = SystemFont.regular.of(textStyle: .caption2)
    }
    
    
    // MARK: - Actions
    
    @IBAction func unenroll(_ sender: Any) {
        LoadingView.show()
        viewModel.submit()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] enrolled in
                    LoadingView.hide()
                    guard let self = self else { return }
                    self.delegate?.autoPayViewController(self, enrolled: true)
                    self.parentVc?.navigationController?.popViewController(animated: true)
                    self.dismissModal()
                }, onError: { [weak self] error in
                    LoadingView.hide()
                    guard let self = self else { return }
                    let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                            message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: bag)
    }
    
}


// MARK: - Table View Delegate

extension AutoPayReasonsForStoppingViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


// MARK: - Table View DataSource

extension AutoPayReasonsForStoppingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonForStoppingCell", for: indexPath) as! RadioSelectionTableViewCell
        
        cell.label.text = viewModel.reasonStrings[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUnenrollmentReason.value = viewModel.reasonStrings[indexPath.row]
    }
}
