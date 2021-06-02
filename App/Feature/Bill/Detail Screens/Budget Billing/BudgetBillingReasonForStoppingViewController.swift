//
//  BudgetBillingReasonForStoppingViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 8/2/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class BudgetBillingReasonForStoppingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var unenrollButton: PrimaryButton!
    
    // Passed from BudgetBillingViewController
    var viewModel: BudgetBillingViewModel!
    var budgetBillingViewController: BudgetBillingViewController!
    weak var delegate: BudgetBillingViewControllerDelegate?
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()

        tableView.register(UINib(nibName: "RadioSelectionTableViewCell", bundle: nil), forCellReuseIdentifier: "ReasonForStoppingCell")
        tableView.estimatedRowHeight = 50
        
        viewModel.reasonForStoppingUnenrollButtonEnabled.drive(unenrollButton.rx.isEnabled).disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel.selectedUnenrollmentReason.accept(-1) // Reset if user dismisses this view
    }
    
    @IBAction func onUnenrollPress() {
        GoogleAnalytics.log(event: .budgetBillUnEnrollOffer)
        
    FirebaseUtility.logEvent(.budgetBillingSubmit)
        
        let message = NSLocalizedString("You will see your regular bill amount on your next billing cycle. Any credit balance remaining in your account will be applied to your bill until used, and any negative account balance will become due with your next bill.", comment: "")
        let alertVc = UIAlertController(title: NSLocalizedString("Unenroll from Budget Billing", comment: ""), message: message, preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
            GoogleAnalytics.log(event: .budgetBillUnEnrollCancel) }))
        alertVc.addAction(UIAlertAction(title: NSLocalizedString("Unenroll", comment: ""), style: .destructive, handler: { [weak self] _ in
            LoadingView.show()
            GoogleAnalytics.log(event: .budgetBillUnEnrollOK)
            
            guard let self = self else { return }
            self.viewModel.unenroll(onSuccess: { [weak self] in
                LoadingView.hide()
                guard let self = self else { return }
                self.delegate?.budgetBillingViewControllerDidUnenroll(self)
               
                FirebaseUtility.logEvent(.budgetBill(parameters: [.unenroll_complete]))
                
                FirebaseUtility.logEvent(.budgetBillingNetworkComplete)
                self.budgetBillingViewController.navigationController?.popViewController(animated: false)
                self.dismiss(animated: true, completion: nil)
            }, onError: { [weak self] errMessage in
                LoadingView.hide()
                guard let self = self else { return }
                let alertVc = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errMessage, preferredStyle: .alert)
                alertVc.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alertVc, animated: true, completion: nil)
            })
        }))
        present(alertVc, animated: true, completion: nil)
    }
    
}

extension BudgetBillingReasonForStoppingViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
        
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 16))
        view.backgroundColor = .white
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReasonForStoppingCell", for: indexPath) as! RadioSelectionTableViewCell
        
        cell.label.text = viewModel.reasonString(forIndex: indexPath.row)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedUnenrollmentReason.accept(indexPath.row)
    }
}
