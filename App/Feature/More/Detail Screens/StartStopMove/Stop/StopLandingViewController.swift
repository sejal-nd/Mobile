//
//  StopLandingViewController.swift
//  EUMobile
//
//  Created by Salunke, Swapnil Uday on 07/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class StopLandingViewController: UIViewController {

    @IBOutlet weak var headerMessageLabel: UILabel! {
        didSet {
            headerMessageLabel.textColor = .deepGray
            headerMessageLabel.font = OpenSans.semibold.of(textStyle: .title3)
            headerMessageLabel.text = NSLocalizedString("Permanently stop your current service", comment: "")
        }
    }
    @IBOutlet weak var estimatedTimeLabel: UILabel! {
        didSet {
            estimatedTimeLabel.textColor = .deepGray
            estimatedTimeLabel.font = SystemFont.regular.of(textStyle: .caption1)
            estimatedTimeLabel.text = NSLocalizedString("EST. 4-7 MINUTES", comment: "")
        }
    }
    @IBOutlet weak var youWillNeedLabel: UILabel! {
        didSet {
            youWillNeedLabel.textColor = .deepGray
            youWillNeedLabel.font = SystemFont.regular.of(textStyle: .caption1)
            youWillNeedLabel.text = NSLocalizedString("You'll need:", comment: "")
        }
    }
    
    @IBOutlet weak var stopDateMessagingLabel: UILabel! {
        didSet {
            stopDateMessagingLabel.textColor = .deepGray
            stopDateMessagingLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            stopDateMessagingLabel.text = NSLocalizedString("Date to stop your service within 30 days, excluding holidays and Sundays.", comment: "")
        }
    }
    
    @IBAction func BeginTapped(_ sender: UIButton) {
        ///TODO:  Navigate to the first screen of the Stop Service Flow.
        if (viewModel.isDetailsLoading){
            viewModel.isBeginPressed = true;
            DispatchQueue.main.async {
                LoadingView.show()
            }
        }else {
            if isAccountResidential {
                navigateToStopServiceVC()
            }else {
                UIApplication.shared.openUrlIfCan(viewModel.stopCommercialServiceWebURL)
            }
        }
    }
    lazy var isAccountResidential: Bool = {
        if let currentAccount = viewModel.getAccountDetails(), let customerType = currentAccount.customerInfo.customerType {
            if customerType == "COMM" {
                return false
            }
        }
        return true
    }()
    let viewModel = StopLandingViewModel()

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        addCloseButton()
        setupUIBinding()

        viewModel.fetchAccountDetails()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    func setupUIBinding(){
        viewModel.accountDetailsEvent
            .subscribe (onNext: { [weak self] response in
                guard let `self` = self else { return }
                if response != nil {
                    if  !self.viewModel.isDetailsLoading, self.viewModel.isBeginPressed{
                        DispatchQueue.main.async {
                            LoadingView.hide()
                            if self.isAccountResidential {
                                self.navigateToStopServiceVC()
                            } else {
                                UIApplication.shared.openUrlIfCan(self.viewModel.stopCommercialServiceWebURL)
                            }
                        }
                    }
                }

            }).disposed(by: disposeBag)
        
        viewModel.apiError.asObservable()
            .subscribe ( onNext: { [weak self] _ in
                let exitAction = UIAlertAction(title: NSLocalizedString("Exit", comment: ""), style: .default)
                { [weak self] _ in
                    guard let `self` = self else { return }
                    self.dismiss(animated: true, completion: nil)
                }
                LoadingView.hide()
                DispatchQueue.main.async {
                    self?.presentAlert(title: NSLocalizedString("We're experiencing technical issues ", comment: ""),
                                       message: NSLocalizedString("We can't retrieve the data you requested. Please try again later. ", comment: ""),
                                       style: .alert,
                                       actions: [exitAction])
                }
            }).disposed(by: disposeBag)

    }

    func navigateToStopServiceVC(){
        let storyboard = UIStoryboard(name: "ISUMStop", bundle: nil)
        let stopServiceViewController = storyboard.instantiateViewController(withIdentifier: "StopServiceViewController") as! StopServiceViewController
        self.navigationController?.pushViewController(stopServiceViewController, animated: true)
    }


}
