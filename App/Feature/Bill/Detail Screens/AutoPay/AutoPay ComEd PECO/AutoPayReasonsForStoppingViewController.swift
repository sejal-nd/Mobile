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
    @IBOutlet weak var unenerollButton: PrimaryButton!
    
    var viewModel: AutoPayViewModel!
    
    weak var delegate: AutoPayViewControllerDelegate?
    weak var parentVc: AutoPayViewController?
    
    var presentingNavController: UINavigationController?
    
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
        
        viewModel.selectedUnenrollmentReason.accept(nil)
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
        
        FirebaseUtility.logEvent(.autoPay(parameters: [.unenroll_start]))
                
        FirebaseUtility.logEvent(.autoPaySubmit)
        
        viewModel.unenroll()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] enrolled in
                LoadingView.hide()
                guard let self = self else { return }
                
                FirebaseUtility.logEvent(.autoPay(parameters: [.unenroll_complete]))
                
                FirebaseUtility.logEvent(.autoPayNetworkComplete)
                
                
                let title = NSLocalizedString("Unenrolled from AutoPay", comment: "")
                let description = NSLocalizedString("You have successfully unenrolled from Autopay. If your current bill due date is less than 3 business days out, your current bill will still be paid with your Autopay bank account. If your current bill due date is more than 4 business days out, you will need to pay your current bill manually.", comment: "")
                let infoModal = InfoModalViewController(title: title,
                                                        image: #imageLiteral(resourceName: "img_confirmation"),
                                                        description: description,
                                                        onClose: { [weak self] in
                    self?.parentVc?.navigationController?.popViewController(animated: true)
                    self?.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                })
               
                self.navigationController?.present(infoModal, animated: true)
                
            }, onError: { [weak self] error in
                LoadingView.hide()
                guard let self = self,
                      let networkingError = error as? NetworkingError else { return }
                
                FirebaseUtility.logEvent(.autoPay(parameters: [.network_submit_error]))
                
                let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                        message: networkingError.description, preferredStyle: .alert)
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
        viewModel.selectedUnenrollmentReason.accept(viewModel.reasonStrings[indexPath.row])
    }
}
