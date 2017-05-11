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
		
		let sharedFetchAccountDetail = fetchAccountDetailSubject.share()
		
		sharedFetchAccountDetail
			.map { nil }
			.bind(to: currentAccountDetail)
			.addDisposableTo(disposeBag)
		
        sharedFetchAccountDetail
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
	
	
	// MARK: - Should Hide Views
	
    lazy var shouldHideAlertBanner: Driver<Bool> = {
        return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return true }
				// TODO: Implement logic for this
				return false
		}
	}()
	
	lazy var shouldHideNeedHelpUnderstanding: Driver<Bool> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return true }
				// TODO: Add logic for residential users based on forthcoming web service response additions
				return UserDefaults.standard.bool(forKey: UserDefaultKeys.IsCommercialUser)
		}
	}()
	
	lazy var shouldHideAutoPay: Driver<Bool> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return true }
				return !(accountDetail.isAutoPay || accountDetail.isBGEasy || accountDetail.isAutoPayEligible)
		}
	}()
	
	lazy var shouldHidePaperless: Driver<Bool> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return true }
				
				if accountDetail.isEBillEnrollment {
					return false
				}
				
				switch accountDetail.eBillEnrollStatus {
				case .canEnroll, .canUnenroll: return false
				case .ineligible, .finaled: return true
				}
		}
	}()
	
	lazy var shouldHideBudget: Driver<Bool> = {
		return self.currentAccountDetail.asDriver().map {
			guard let accountDetail = $0 else { return true }
			return !accountDetail.isBudgetBillEligible &&
				!accountDetail.isBudgetBillEnrollment &&
				Environment.sharedInstance.opco != .bge
		}
	}()
	
	
	// MARK: - View Content
	
	lazy var totalAmountText: Driver<String?> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return nil }
				return accountDetail.billingInfo.netDueAmount?.currencyString ?? "--"
		}
	}()
	
	lazy var pendingPayments: Driver<[String]> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard
					let pendingPaymentAmount = $0?.billingInfo.pendingPaymentAmount
					else { return [] }
				
				return [pendingPaymentAmount].map { $0.currencyString ?? "--" }
		}
	}()
	
	lazy var autoPayButtonText: Driver<NSAttributedString?> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return nil }
				if accountDetail.isAutoPay || accountDetail.isBGEasy {
					let text = NSLocalizedString("AutoPay", comment: "")
					let enrolledText = accountDetail.isBGEasy ?
						NSLocalizedString("enrolled in BGEasy", comment: "") :
						NSLocalizedString("enrolled", comment: "")
					return BillViewModel.isEnrolledText(topText: text, bottomText: enrolledText)
				} else {
					return BillViewModel.canEnrollText(boldText: NSLocalizedString("AutoPay?", comment: ""))
				}
		}
	}()
	
	lazy var paperlessButtonText: Driver<NSAttributedString?> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return nil }
				switch accountDetail.eBillEnrollStatus {
				case .canEnroll:
					return BillViewModel.canEnrollText(boldText: NSLocalizedString("Paperless eBill?", comment: ""))
				case .canUnenroll:
					return BillViewModel.isEnrolledText(topText: NSLocalizedString("Paperless eBill", comment: ""),
					                                    bottomText: NSLocalizedString("enrolled", comment: ""))
				case .ineligible, .finaled:
					return nil
				}
		}
	}()
	
	lazy var budgetButtonText: Driver<NSAttributedString?> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return nil }
				if accountDetail.isBudgetBillEnrollment {
					return BillViewModel.isEnrolledText(topText: NSLocalizedString("Budget Billing", comment: ""),
					                                    bottomText: NSLocalizedString("enrolled", comment: ""))
				} else {
					return BillViewModel.canEnrollText(boldText: NSLocalizedString("Budget Billing?", comment: ""))
				}
		}
	}()
	
	
	// MARK: - Conveniece functions
	
    private static func isEnrolledText(topText: String, bottomText: String) -> NSAttributedString {
        let mutableText = NSMutableAttributedString(string: topText + "\n" + bottomText)
        let topTextRange = NSMakeRange(0, topText.characters.count)
        let bottomTextRange = NSMakeRange(topText.characters.count + 1, bottomText.characters.count)
        
        mutableText.addAttribute(NSFontAttributeName,
                                 value: OpenSans.bold.ofSize(16),
                                 range: topTextRange)
        mutableText.addAttribute(NSForegroundColorAttributeName,
                                 value: UIColor.blackText,
                                 range: topTextRange)
        mutableText.addAttribute(NSFontAttributeName,
                                 value: OpenSans.regular.ofSize(14),
                                 range: bottomTextRange)
        mutableText.addAttribute(NSForegroundColorAttributeName,
                                 value: UIColor.successGreenText,
                                 range: bottomTextRange)
        
        return mutableText
    }
    
    private static func canEnrollText(boldText: String) -> NSAttributedString {
        let text = NSLocalizedString("Would you like to enroll in ", comment: "")
        let mutableText = NSMutableAttributedString(string: text + boldText, attributes: [NSForegroundColorAttributeName: UIColor.blackText])
        
        mutableText.addAttribute(NSFontAttributeName,
                                 value: OpenSans.regular.ofSize(16),
                                 range: NSMakeRange(0, text.characters.count))
        
        mutableText.addAttribute(NSFontAttributeName,
                                 value: OpenSans.bold.ofSize(16),
                                 range: NSMakeRange(text.characters.count, boldText.characters.count))
        
        return mutableText
    }
    
}




