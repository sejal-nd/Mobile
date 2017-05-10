//
//  BillViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 4/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt

class BillViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService

    let fetchAccountDetailSubject = PublishSubject<Void>()
    let currentAccountDetail = Variable<AccountDetail?>(nil)
    let isFetchingAccountDetail: Driver<Bool>
    
    required init(accountService: AccountService) {
        self.accountService = accountService
        
        
        let fetchingAccountDetailTracker = ActivityTracker()
        isFetchingAccountDetail = fetchingAccountDetailTracker.asDriver()
        
        fetchAccountDetailSubject
            .flatMapLatest {
                accountService
                    .fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
                    .trackActivity(fetchingAccountDetailTracker)
                    .do(onError: {
                        dLog(message: $0.localizedDescription)
                    })
            }
            .bind(to: currentAccountDetail)
            .addDisposableTo(disposeBag)
    }
    
    func fetchAccountDetail() {
        fetchAccountDetailSubject.onNext()
    }
    
    lazy var currentAccountDetailUnwrapped: Driver<AccountDetail> = {
        return self.currentAccountDetail.asObservable()
            .unwrap()
            .asDriver(onErrorDriveWith: Driver.empty())
    }()
    
    lazy var shouldHideAlertBanner: Driver<Bool> = {
        return self.currentAccountDetailUnwrapped.map { _ in false }
    }()
    
    lazy var totalAmountText: Driver<String> = {
        return self.currentAccountDetailUnwrapped
            .map { $0.billingInfo.netDueAmount?.currencyString ?? "--" }
    }()
    
    lazy var shouldHideBudget: Driver<Bool> = {
        return self.currentAccountDetailUnwrapped.map {
            !$0.isBudgetBillEligible && Environment.sharedInstance.opco != .bge
        }
    }()
    
    lazy var shouldHidePaperless: Driver<Bool> = {
        return self.currentAccountDetailUnwrapped.map { !$0.isEBillEligible }
    }()
    
    lazy var autoPayButtonText: Driver<NSAttributedString> = {
        return self.currentAccountDetailUnwrapped.map { accountDetail in
            if accountDetail.isAutoPay || accountDetail.isBGEasy {
                let text = NSLocalizedString("AutoPay\n", comment: "")
                let enrolledText = accountDetail.isBGEasy ? NSLocalizedString("enrolled in BGEasy", comment: ""): NSLocalizedString("enrolled", comment: "")
                let mutableText = NSMutableAttributedString(string: text + enrolledText)
                mutableText.addAttribute(NSFontAttributeName, value: OpenSans.bold.ofSize(16), range: NSMakeRange(0, text.characters.count))
                mutableText.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackText, range: NSMakeRange(0, text.characters.count))
                mutableText.addAttribute(NSFontAttributeName, value: OpenSans.regular.ofSize(14), range: NSMakeRange(text.characters.count, enrolledText.characters.count))
                mutableText.addAttribute(NSForegroundColorAttributeName, value: UIColor.successGreenText, range: NSMakeRange(text.characters.count, enrolledText.characters.count))
                return mutableText
            } else {
                let text = NSLocalizedString("Would you like to enroll in ", comment: "")
                let autoPayText = NSLocalizedString("AutoPay?", comment: "")
                let mutableText = NSMutableAttributedString(string: text + autoPayText, attributes: [NSForegroundColorAttributeName: UIColor.blackText])
                mutableText.addAttribute(NSFontAttributeName, value: OpenSans.regular.ofSize(16), range: NSMakeRange(0, text.characters.count))
                mutableText.addAttribute(NSFontAttributeName, value: OpenSans.bold.ofSize(16), range: NSMakeRange(text.characters.count, autoPayText.characters.count))
                return mutableText
            }
        }
    }()
    
    lazy var budgetButtonText: Driver<NSAttributedString> = {
        return self.currentAccountDetailUnwrapped.map { accountDetail in
            NSAttributedString(string: "enrolled")
        }
    }()
    
    lazy var paperlessButtonText: Driver<NSAttributedString> = {
        return self.currentAccountDetailUnwrapped.map { accountDetail in
            NSAttributedString(string: "enrolled")
        }
    }()
    
}




