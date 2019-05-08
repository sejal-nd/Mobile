//
//  BGEChoiceIDViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 5/2/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift

class BGEChoiceIDViewController: AccountPickerViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var choiceIdBox: UIView!
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var electricRow: UIView!
    @IBOutlet weak var electricTitleLabel: UILabel!
    @IBOutlet weak var electricValueLabel: UILabel!
    
    @IBOutlet weak var dividerLine: UIView!
    
    @IBOutlet weak var gasRow: UIView!
    @IBOutlet weak var gasTitleLabel: UILabel!
    @IBOutlet weak var gasValueLabel: UILabel!
    
    @IBOutlet weak var errorEmptyStateView: UIView!
    @IBOutlet weak var errorEmptyStateLabel: UILabel!
    
    let viewModel = BGEChoiceIDViewModel(accountService: ServiceFactory.createAccountService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Choice ID", comment: "")

        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        headerLabel.textColor = .blackText
        headerLabel.font = OpenSans.regular.of(textStyle: .headline)
        headerLabel.text = NSLocalizedString("All customers in the BGE service area have the opportunity to choose their electricity or natural gas supplier. Research your options, but before choosing a new supplier, be certain the company is licensed by the PSC and registered with BGE.", comment: "")
    
        choiceIdBox.backgroundColor = .softGray
        
        electricTitleLabel.textColor = .blackText
        electricTitleLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        electricTitleLabel.text = NSLocalizedString("Electric Choice ID", comment: "")
        electricValueLabel.textColor = .blackText
        electricValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        dividerLine.backgroundColor = .accentGray
        
        gasTitleLabel.textColor = .blackText
        gasTitleLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        gasTitleLabel.text = NSLocalizedString("Gas Choice ID", comment: "")
        gasValueLabel.textColor = .blackText
        gasValueLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        
        errorEmptyStateLabel.textColor = .blackText
        errorEmptyStateLabel.font = OpenSans.regular.of(textStyle: .headline)
        errorEmptyStateLabel.text = NSLocalizedString("Your Choice ID could not be retrieved at this time.", comment: "")
        
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setColoredNavBar(hidesBottomBorder: true)
    }

    private func bindViewModel() {
        viewModel.loading.asDriver().not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.electricChoiceId.asDriver().isNil().drive(electricRow.rx.isHidden).disposed(by: disposeBag)
        viewModel.electricChoiceId.asDriver().drive(electricValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.gasChoiceId.asDriver().isNil().drive(gasRow.rx.isHidden).disposed(by: disposeBag)
        viewModel.gasChoiceId.asDriver().drive(gasValueLabel.rx.text).disposed(by: disposeBag)
        viewModel.shouldShowDividerLine.not().drive(dividerLine.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorEmptyState.not().drive(errorEmptyStateView.rx.isHidden).disposed(by: disposeBag)
    }
    
}

extension BGEChoiceIDViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchChoiceIds()
    }
    
}
