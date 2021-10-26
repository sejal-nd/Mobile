//
//  MoveLandingViewController.swift
//  EUMobile
//
//  Created by Salunke, Swapnil Uday on 07/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MoveLandingViewController: UIViewController {
    @IBOutlet weak var headerLabel: UILabel! {
        didSet {
            headerLabel.textColor = .deepGray
            headerLabel.font = OpenSans.semibold.of(textStyle: .title3)
            headerLabel.text = NSLocalizedString("Stop current service and start new service at another address in BGE’s area", comment: "")
        }
    }
    @IBOutlet weak var estimatedTimeLabel: UILabel! {
        didSet {
            estimatedTimeLabel.textColor = .deepGray
            estimatedTimeLabel.font = SystemFont.regular.of(textStyle: .caption1)
            estimatedTimeLabel.text = NSLocalizedString("EST. 12-18 MINUTES", comment: "")
        }
    }
    @IBOutlet weak var youMightNeedLabel: UILabel! {
        didSet {
            youMightNeedLabel.textColor = .deepGray
            youMightNeedLabel.font = SystemFont.regular.of(textStyle: .caption1)
            youMightNeedLabel.text = NSLocalizedString("You might need:", comment: "")
        }
    }
    @IBOutlet weak var identificationInformationLabel: UILabel! {
        didSet {
            identificationInformationLabel.textColor = .deepGray
            identificationInformationLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            identificationInformationLabel.text = NSLocalizedString("Identification information", comment: "")
        }
    }
    @IBOutlet weak var socialSecurityTaxIdLabel: UILabel! {
        didSet {
            socialSecurityTaxIdLabel.textColor = .deepGray
            socialSecurityTaxIdLabel.font = SystemFont.regular.of(textStyle: .caption1)
            socialSecurityTaxIdLabel.text = NSLocalizedString("Social Security Number / Tax ID", comment: "")
        }
    }
    @IBOutlet weak var diversLicenseStateIdLabel: UILabel! {
        didSet {
            diversLicenseStateIdLabel.textColor = .deepGray
            diversLicenseStateIdLabel.font = SystemFont.regular.of(textStyle: .caption1)
            diversLicenseStateIdLabel.text = NSLocalizedString("Driver’s license / State ID", comment: "")
        }
    }
    @IBOutlet weak var dateOfBirthLabel: UILabel! {
        didSet {
            dateOfBirthLabel.textColor = .deepGray
            dateOfBirthLabel.font = SystemFont.regular.of(textStyle: .caption1)
            dateOfBirthLabel.text = NSLocalizedString("Date of birth", comment: "")
        }
    }
    @IBOutlet weak var startStopDateLabel: UILabel! {
        didSet {
            startStopDateLabel.textColor = .deepGray
            startStopDateLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            startStopDateLabel.text = NSLocalizedString("Dates to stop and start your service", comment: "")
        }
    }
    @IBOutlet weak var newServiceAddressLabel: UILabel! {
        didSet {
            newServiceAddressLabel.textColor = .deepGray
            newServiceAddressLabel.font = SystemFont.regular.of(textStyle: .subheadline)
            newServiceAddressLabel.text = NSLocalizedString("New service address", comment: "")
        }
    }
    
    @IBAction func BeginTapped(_ sender: PrimaryButton)  {
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
                UIApplication.shared.openUrlIfCan(viewModel.moveCommercialServiceWebURL)
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
    let viewModel = MoveLandingViewModel()

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        addCloseButton()
        setupUIBinding()
        viewModel.fetchAccountDetails()
    }
    func setupUIBinding(){
        viewModel.accountDetailsEvent
            .subscribe (onNext: { [weak self] response in
                guard let `self` = self else { return }
                if response != nil {
                    if  !self.viewModel.isDetailsLoading, self.viewModel.isBeginPressed{
                        DispatchQueue.main.async {
                            LoadingView.hide()
                            self.navigateToStopServiceVC()
                        }
                    }
                }

            }).disposed(by: disposeBag)
    }
    func navigateToStopServiceVC(){
        let storyboard = UIStoryboard(name: "ISUMMove", bundle: nil)
        let scheduleMoveServiceViewController = storyboard.instantiateViewController(withIdentifier: "ScheduleMoveServiceViewController") as! ScheduleMoveServiceViewController
        self.navigationController?.pushViewController(scheduleMoveServiceViewController, animated: true)
    }

}
