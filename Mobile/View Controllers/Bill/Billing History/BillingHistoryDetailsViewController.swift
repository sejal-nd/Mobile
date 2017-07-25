//
//  BillingHistoryDetailsViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/26/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BillingHistoryDetailsViewController: DismissableFormSheetViewController {

    var billingHistoryItem: BillingHistoryItem!
    
    @IBOutlet weak var loadingIndicator: LoadingIndicator!
    @IBOutlet weak var mainStackView: UIScrollView!
    
    @IBOutlet weak var paymentTypeView: UIView!
    @IBOutlet weak var paymentTypeLabel: UILabel!
    @IBOutlet weak var paymentTypeDetailLabel: UILabel!
    
    @IBOutlet weak var paymentTypeSeparatorLine: UIView!
    
    @IBOutlet weak var paymentAccountView: UIView!
    @IBOutlet weak var paymentAccountLabel: UILabel!
    @IBOutlet weak var paymentAccountDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentAccountSeparatorLine: UIView!
    
    @IBOutlet weak var paymentDateView: UIView!
    @IBOutlet weak var paymentDateLabel: UILabel!
    @IBOutlet weak var paymentDateDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentDateSeparatorLine: UIView!
    
    @IBOutlet weak var paymentAmountView: UIView!
    @IBOutlet weak var paymentAmountLabel: UILabel!
    @IBOutlet weak var paymentAmountDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentAmountSeparatorLine: UIView!
    
    @IBOutlet weak var convenienceFeeView: UIView!
    @IBOutlet weak var convenienceFeeLabel: UILabel!
    @IBOutlet weak var convenienceFeeDetailsLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeSeparatorLine: UIView!
    
    @IBOutlet weak var totalAmountPaidView: UIView!
    @IBOutlet weak var totalAmountPaidLabel: UILabel!
    @IBOutlet weak var totalAmountPaidDetailsLabel: UILabel!
    
    @IBOutlet weak var totalAmountPaidSeparatorLine: UIView!
    
    @IBOutlet weak var paymentStatusView: UIView!
    @IBOutlet weak var paymentStatusLabel: UILabel!
    @IBOutlet weak var paymentStatusDetailsLabel: UILabel!
    
    @IBOutlet weak var paymentStatusSeparatorLine: UIView!
    
    @IBOutlet weak var confirmationNumberView: UIView!
    @IBOutlet weak var confirmationNumberLabel: UILabel!
    @IBOutlet weak var confirmationNumberDetailsLabel: UILabel!
    
    var viewModel: BillingHistoryDetailsViewModel!
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Payment Details", comment: "")
        
        viewModel = BillingHistoryDetailsViewModel.init(paymentService: ServiceFactory.createPaymentService(), billingHistoryItem: billingHistoryItem)
        
//        if viewModel.isSpeedpay {
//            mainStackView.isHidden = true
//        }
        formatViews()
        styleViews()
        bindLoadingStates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navController = navigationController as? MainBaseNavigationController {
            navController.setColoredNavBar(hidesBottomBorder: true)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func formatViews() {
        if !viewModel.isBGE {
            paymentTypeView.isHidden = true
            paymentTypeSeparatorLine.isHidden = true
            
            paymentAccountView.isHidden = true
            paymentAccountSeparatorLine.isHidden = true
            
            convenienceFeeView.isHidden = true
            convenienceFeeSeparatorLine.isHidden = true
            
            totalAmountPaidView.isHidden = true
            totalAmountPaidSeparatorLine.isHidden = true
            
            confirmationNumberView.isHidden = true
        } else {
            if viewModel.isSpeedpay {
                paymentTypeView.isHidden = true
                paymentTypeSeparatorLine.isHidden = true
            } else {
                paymentAccountView.isHidden = true
                paymentAccountSeparatorLine.isHidden = true
                
                convenienceFeeView.isHidden = true
                convenienceFeeSeparatorLine.isHidden = true
                
                totalAmountPaidView.isHidden = true
                totalAmountPaidSeparatorLine.isHidden = true
                
            }
        }
    }
    
    func styleViews() {
        
        paymentTypeLabel.textColor = .deepGray
        paymentTypeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentTypeDetailLabel.textColor = .black
        paymentTypeDetailLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentTypeSeparatorLine.backgroundColor = .softGray
        
        paymentAccountLabel.textColor = .deepGray
        paymentAccountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAccountDetailsLabel.textColor = .black
        paymentAccountDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentAccountSeparatorLine.backgroundColor = .softGray
        
        paymentDateLabel.textColor = .deepGray
        paymentDateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentDateDetailsLabel.textColor = .black
        paymentDateDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentDateSeparatorLine.backgroundColor = .softGray
        
        paymentAmountLabel.textColor = .deepGray
        paymentAmountLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountDetailsLabel.textColor = .successGreenText
        paymentAmountDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        paymentAmountSeparatorLine.backgroundColor = .softGray
        
        convenienceFeeLabel.textColor = .deepGray
        convenienceFeeLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeDetailsLabel.textColor = .successGreenText
        convenienceFeeDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        convenienceFeeSeparatorLine.backgroundColor = .softGray
        
        totalAmountPaidLabel.textColor = .deepGray
        totalAmountPaidLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        totalAmountPaidDetailsLabel.textColor = .successGreenText
        totalAmountPaidDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        totalAmountPaidSeparatorLine.backgroundColor = .softGray
        
        paymentStatusLabel.textColor = .deepGray
        paymentStatusLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentStatusDetailsLabel.textColor = .black
        paymentStatusDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)

        paymentStatusSeparatorLine.backgroundColor = .softGray
        
        confirmationNumberLabel.textColor = .deepGray
        confirmationNumberLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        confirmationNumberDetailsLabel.textColor = .black
        confirmationNumberDetailsLabel.font = SystemFont.bold.of(textStyle: .headline)
    }
    
    func bindLoadingStates() {
        
        viewModel.paymentAccount.drive(self.paymentAccountDetailsLabel.rx.text).addDisposableTo(self.bag)
        
        paymentTypeLabel.text = viewModel.paymentTypeLabel
        paymentTypeDetailLabel.text = viewModel.paymentType
        paymentDateDetailsLabel.text = viewModel.paymentDate
        paymentAmountLabel.text = viewModel.paymentAmountLabel
        paymentAmountDetailsLabel.text = viewModel.amountPaid
        
        viewModel.fetchingTracker.asDriver().drive(mainStackView.rx.isHidden).addDisposableTo(bag)
        viewModel.fetchingTracker.asDriver().filter(!).drive(loadingIndicator.rx.isHidden).addDisposableTo(bag)
        
        viewModel.convenienceFee.drive(self.convenienceFeeDetailsLabel.rx.text).addDisposableTo(self.bag)
        viewModel.totalAmountPaid.drive(self.totalAmountPaidDetailsLabel.rx.text).addDisposableTo(self.bag)
        
        paymentStatusDetailsLabel.text = viewModel.paymentStatus
        confirmationNumberDetailsLabel.text = viewModel.confirmationNumber
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
