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

enum FetchingAccountState {
	case refresh, switchAccount
}

class BillViewModel {
    
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService

    let fetchAccountDetail = PublishSubject<FetchingAccountState>()
    let currentAccountDetail = Variable<AccountDetail?>(nil)
    let isFetchingAccountDetail: Driver<Bool>
    
    required init(accountService: AccountService) {
        self.accountService = accountService
        
        let fetchingAccountDetailTracker = ActivityTracker()
        isFetchingAccountDetail = fetchingAccountDetailTracker.asDriver()
		
		let sharedFetchAccountDetail = fetchAccountDetail.share()
		
		sharedFetchAccountDetail
			.filter { $0 != .refresh }
			.map { _ in nil }
			.bind(to: currentAccountDetail)
			.addDisposableTo(disposeBag)
		
        sharedFetchAccountDetail
            .flatMapLatest { _ in
                accountService
                    .fetchAccountDetail(account: AccountsStore.sharedInstance.currentAccount)
                    .trackActivity(fetchingAccountDetailTracker)
            }
			.bind(to: currentAccountDetail)
			.addDisposableTo(disposeBag)
    }
	
	func fetchAccountDetail(isRefresh: Bool) {
		fetchAccountDetail.onNext(isRefresh ? .refresh: .switchAccount)
    }
    
    lazy var currentAccountDetailUnwrapped: Driver<AccountDetail> = {
        return self.currentAccountDetail.asObservable()
            .unwrap()
            .asDriver(onErrorDriveWith: Driver.empty())
	}()
	
	
	// MARK: - Show/Hide Views -
	
	lazy var isFetchingDifferentAccount: Driver<Bool> = {
		return self.currentAccountDetail.asDriver().map { $0 == nil }
	}()
    
    let shouldHideAmountDueTooltip = Environment.sharedInstance.opco != .peco
	
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
	
	lazy var shouldShowRestoreService: Driver<Bool> = {
		return self.currentAccountDetail.asDriver().map {
			return $0?.billingInfo.restorationAmount ?? 0 > 0
		}
	}()
	
	lazy var shouldShowCatchUpAmount: Driver<Bool> = {
		let showCatchup = self.currentAccountDetail.asDriver().map {
			return $0?.billingInfo.amtDpaReinst ?? 0 > 0
		}
		return Driver.zip(self.shouldShowRestoreService, showCatchup) { !$0 && $1 }
	}()
	
	
	
	
	// MARK: - View Content -
	
	lazy var totalAmountText: Driver<String?> = {
		return self.currentAccountDetail.asDriver()
			.map {
				guard let accountDetail = $0 else { return nil }
				return accountDetail.billingInfo.netDueAmount?.currencyString ?? "--"
		}
	}()
	
	lazy var totalAmountDescriptionText: Driver<String?> = {
		return self.currentAccountDetail.asDriver().map {
			let localizedText = NSLocalizedString("Total Amount Due By %@", comment: "")
			return String(format: localizedText, $0?.billingInfo.dueByDate?.mmDdYyyyString ?? "--")
		}
	}()
	
    lazy var pendingPayments: Driver<[String]> = {
        return self.currentAccountDetail.asDriver()
            .map {
                guard let pendingPaymentAmount = $0?.billingInfo.pendingPaymentAmount else { return [] }
                return [pendingPaymentAmount].map { $0.currencyString ?? "--" }
        }
    }()
    
    
    //MARK: Banner Alert Text
    
    lazy var alertBannerText: Driver<String?> = {
        return Driver.combineLatest(self.restoreServiceAlertText, self.avoidShutoffDueDateAlertText, self.paymentFailedAlertText) {
            $0 ?? $1 ?? $2
        }
    }()
    
    lazy var restoreServiceAlertText: Driver<String?> = {
        return self.currentAccountDetail.asDriver().map {
            guard let accountDetail = $0,
                !(accountDetail.billingInfo.restorationAmount ?? 0 > 0 && accountDetail.billingInfo.amtDpaReinst ?? 0 > 0) &&
                accountDetail.isCutOutNonPay else {
                    return nil
            }
            return NSLocalizedString("Your service is off due to non-payment.", comment: "")
        }
    }()
    
    lazy var avoidShutoffDueDateAlertText: Driver<String?> = {
        return self.currentAccountDetail.asDriver().map {
            guard let billingInfo = $0?.billingInfo,
                (!(billingInfo.restorationAmount ?? 0 > 0 && billingInfo.amtDpaReinst ?? 0 > 0) &&
                    billingInfo.disconnectNoticeArrears > 0 &&
                    billingInfo.isDisconnectNotice) else {
                        return nil
            }
            if Environment.sharedInstance.opco == .bge {
                let localizedText = NSLocalizedString("Due by %@", comment: "")
                let dueByDateString = billingInfo.dueByDate?.mmDdYyyyString ?? "--"
                return String(format: localizedText, dueByDateString)
            } else {
                return NSLocalizedString("Due Immediately", comment: "")
            }
        }
    }()
    
    lazy var paymentFailedAlertText: Driver<String?> = {
        return self.currentAccountDetail.asDriver().map {
            guard let accountDetail = $0 else { return nil }
            //TODO: Implement this alert text
            let localizedText = NSLocalizedString("Your payment of %@ made with $@ failed processing. Please select an alternative payment account", comment: "")
            return nil
        }
    }()
    
    lazy var catchUpDisclaimerText: Driver<String?> = {
        return self.currentAccountDetail.asDriver().map {
            guard let billingInfo = $0?.billingInfo
                else { return nil }
            let localizedText = NSLocalizedString("You are entitled to one free reinstatement per plan. Any additional reinstatement will incur a %@ fee on your next bill.", comment: "")
            return String(format: localizedText, billingInfo.atReinstateFee?.currencyString ?? "--")
        }
    }()
    
    lazy var paymentStatusText: Driver<String?> = {
        return self.currentAccountDetail.asDriver()
            .map {
                //TODO: Add check for BGE credit amount?
                guard let accountDetail = $0 else { return nil }
                if let scheduledPaymentAmount = accountDetail.billingInfo.scheduledPaymentAmount, scheduledPaymentAmount > 0.0 {
                    if accountDetail.isAutoPay {
                        if Environment.sharedInstance.opco == .bge {
                            return NSLocalizedString("You are enrolled in AutoPay", comment: "")
                        } else {
                            let paymentString = scheduledPaymentAmount.currencyString ?? "--"
                            let dueByDateString = accountDetail.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
                            let localizedText = NSLocalizedString("You have an automatic payment of %@ for %@", comment: "")
                            return String(format: localizedText, paymentString, dueByDateString)
                        }
                    } else {
                        let paymentString = scheduledPaymentAmount.currencyString ?? "--"
                        let dueByDateString = accountDetail.billingInfo.dueByDate?.mmDdYyyyString ?? "--"
                        let localizedText = NSLocalizedString("Thank you for scheduling your %@ payment for %@", comment: "")
                        return String(format: localizedText, paymentString, dueByDateString)
                    }
                } else if let pendingPaymentAmount = accountDetail.billingInfo.pendingPaymentAmount, pendingPaymentAmount > 0 {
                    let paymentString = pendingPaymentAmount.currencyString ?? "--"
                    let localizedText = NSLocalizedString("You have a payment of %@ processing", comment: "")
                    return String(format: localizedText, paymentString)
                } else if let lastPaymentAmount = accountDetail.billingInfo.lastPaymentAmount, lastPaymentAmount > 0 {
                    let paymentString = lastPaymentAmount.currencyString ?? "--"
                    let dueByDateString = accountDetail.billingInfo.lastPaymentDate?.mmDdYyyyString ?? "--"
                    let localizedText = NSLocalizedString("Thank you for %@ payment on %@", comment: "")
                    return String(format: localizedText, paymentString, dueByDateString)
                } else {
                    return nil
                }
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
				if accountDetail.isEBillEnrollment {
					return BillViewModel.isEnrolledText(topText: NSLocalizedString("Paperless eBill", comment: ""),
					                                    bottomText: NSLocalizedString("enrolled", comment: ""))
				}
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




