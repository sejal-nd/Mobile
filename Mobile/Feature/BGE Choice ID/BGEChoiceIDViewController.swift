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
    @IBOutlet weak var electricValueTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var dividerLine: UIView!
    
    @IBOutlet weak var gasRow: UIView!
    @IBOutlet weak var gasTitleLabel: UILabel!
    @IBOutlet weak var gasValueTextView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var errorEmptyStateView: UIView!
    @IBOutlet weak var errorEmptyStateLabel: UILabel!
    
    let viewModel = BGEChoiceIDViewModel(accountService: ServiceFactory.createAccountService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Choice ID", comment: "")

        accountPicker.delegate = self
        accountPicker.parentViewController = self
        
        headerLabel.textColor = .deepGray
        headerLabel.font = SystemFont.regular.of(textStyle: .body)
        headerLabel.text = NSLocalizedString("All customers in the BGE service area have the opportunity to choose their electricity or natural gas supplier. Research your options, but before choosing a new supplier, be certain the company is licensed by the PSC and registered with BGE.", comment: "")
        headerLabel.setLineHeight(lineHeight: 24)
        
        choiceIdBox.layer.borderColor = UIColor.accentGray.cgColor
        choiceIdBox.layer.borderWidth = 1
        
        electricTitleLabel.textColor = .deepGray
        electricTitleLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        electricTitleLabel.text = NSLocalizedString("Electric Choice ID", comment: "")
        electricValueTextView.textColor = .deepGray
        electricValueTextView.font = SystemFont.regular.of(textStyle: .subheadline)
        electricValueTextView.dataDetectorTypes.remove(.all)
        
        dividerLine.backgroundColor = .accentGray
        
        gasTitleLabel.textColor = .deepGray
        gasTitleLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        gasTitleLabel.text = NSLocalizedString("Gas Choice ID", comment: "")
        gasValueTextView.textColor = .deepGray
        gasValueTextView.font = SystemFont.regular.of(textStyle: .subheadline)
        gasValueTextView.dataDetectorTypes.remove(.all)
        
        errorEmptyStateLabel.textColor = .deepGray
        errorEmptyStateLabel.font = SystemFont.regular.of(textStyle: .headline)
        errorEmptyStateLabel.text = NSLocalizedString("Your Choice ID could not be retrieved at this time.", comment: "")
        
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func bindViewModel() {
        viewModel.loading.asDriver().not().drive(loadingView.rx.isHidden).disposed(by: disposeBag)
        viewModel.electricChoiceId.asDriver().isNil().drive(electricRow.rx.isHidden).disposed(by: disposeBag)
        viewModel.electricChoiceId.asDriver().drive(electricValueTextView.rx.text).disposed(by: disposeBag)
        viewModel.gasChoiceId.asDriver().isNil().drive(gasRow.rx.isHidden).disposed(by: disposeBag)
        viewModel.gasChoiceId.asDriver().drive(gasValueTextView.rx.text).disposed(by: disposeBag)
        viewModel.shouldShowDividerLine.not().drive(dividerLine.rx.isHidden).disposed(by: disposeBag)
        viewModel.shouldShowErrorEmptyState.not().drive(errorEmptyStateView.rx.isHidden).disposed(by: disposeBag)
    }
    
}

extension BGEChoiceIDViewController: AccountPickerDelegate {
    
    func accountPickerDidChangeAccount(_ accountPicker: AccountPicker) {
        viewModel.fetchChoiceIds()
    }
    
}
