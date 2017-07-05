//
//  ReviewPaymentViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 7/3/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ReviewPaymentViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    var viewModel: PaymentViewModel! // Passed from MakePaymentViewController

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContentView: UIView!
    var gradientLayer = CAGradientLayer()
    
    @IBOutlet weak var paymentAccountTextLabel: UILabel!
    @IBOutlet weak var paymentAccountMaskedAccountNumberLabel: UILabel!
    @IBOutlet weak var paymentAccountNicknameLabel: UILabel!
    
    @IBOutlet weak var receiptView: UIView!
    @IBOutlet weak var amountDueTextLabel: UILabel!
    @IBOutlet weak var amountDueValueLabel: UILabel!
    @IBOutlet weak var dueDateTextLabel: UILabel!
    @IBOutlet weak var dueDateValueLabel: UILabel!
    
    @IBOutlet weak var convenienceFeeView: UIView!
    @IBOutlet weak var paymentAmountTextLabel: UILabel!
    @IBOutlet weak var paymentAmountValueLabel: UILabel!
    @IBOutlet weak var convenienceFeeTextLabel: UILabel!
    @IBOutlet weak var convenienceFeeValueLabel: UILabel!
    
    @IBOutlet weak var totalPaymentView: UIView!
    @IBOutlet weak var paymentDateTextLabel: UILabel!
    @IBOutlet weak var paymentDateValueLabel: UILabel!
    @IBOutlet weak var totalPaymentTextLabel: UILabel!
    @IBOutlet weak var totalPaymentValueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Review Payment", comment: "")
        
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.rightBarButtonItem = submitButton
        viewModel.reviewPaymentSubmitButtonEnabled.drive(submitButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        gradientLayer.frame = scrollViewContentView.bounds
        gradientLayer.colors = [
            UIColor.softGray.cgColor,
            UIColor.white.cgColor,
        ]
        scrollViewContentView.layer.insertSublayer(gradientLayer, at: 0)
        
        paymentAccountTextLabel.textColor = .deepGray
        paymentAccountTextLabel.text = NSLocalizedString("Payment Account", comment: "")
        paymentAccountMaskedAccountNumberLabel.textColor = .blackText
        paymentAccountNicknameLabel.textColor = .middleGray
        
        receiptView.addShadow(color: .black, opacity: 0.1, offset: CGSize(width: 0, height: 0), radius: 2)
        
        amountDueTextLabel.textColor = .deepGray
        amountDueTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        amountDueTextLabel.text = NSLocalizedString("Amount Due", comment: "")
        amountDueValueLabel.textColor = .deepGray
        amountDueValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateTextLabel.textColor = .deepGray
        dueDateTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        dueDateTextLabel.text = NSLocalizedString("Due Date", comment: "")
        dueDateValueLabel.textColor = .deepGray
        dueDateValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        convenienceFeeView.backgroundColor = .softGray
        paymentAmountTextLabel.textColor = .deepGray
        paymentAmountTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        paymentAmountTextLabel.text = NSLocalizedString("Payment Amount", comment: "")
        paymentAmountValueLabel.textColor = .deepGray
        paymentAmountValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeTextLabel.textColor = .deepGray
        convenienceFeeTextLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        convenienceFeeTextLabel.text = NSLocalizedString("Convenience Fee", comment: "")
        convenienceFeeValueLabel.textColor = .deepGray
        convenienceFeeValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        totalPaymentView.backgroundColor = .softGray
        paymentDateTextLabel.textColor = .blackText
        paymentDateTextLabel.font = SystemFont.medium.of(textStyle: .headline)
        paymentDateTextLabel.text = NSLocalizedString("Payment Date", comment: "")
        paymentDateValueLabel.textColor = .blackText
        paymentDateValueLabel.font = SystemFont.medium.of(textStyle: .headline)
        totalPaymentTextLabel.textColor = .blackText
        totalPaymentTextLabel.font = SystemFont.medium.of(textStyle: .headline)
        totalPaymentTextLabel.text = NSLocalizedString("Total Payment", comment: "")
        totalPaymentValueLabel.textColor = .blackText
        totalPaymentValueLabel.font = SystemFont.medium.of(textStyle: .headline)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = scrollViewContentView.bounds
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        gradientLayer.frame = scrollViewContentView.bounds
    }
    
    func onSubmitPress() {
        performSegue(withIdentifier: "paymentConfirmationSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PaymentConfirmationViewController {
            vc.presentingNavController = self.navigationController!
        }
    }

}
