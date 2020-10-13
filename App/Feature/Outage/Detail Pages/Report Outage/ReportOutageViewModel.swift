//
//  ReportOutageViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 3/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class ReportOutageViewModel {
    
    let disposeBag = DisposeBag()
    
    private var outageService: OutageService
    private var accountService: AccountService
    
    var accountNumber: String? // Passed from UnauthenticatedOutageStatusViewController
    var outageStatus: OutageStatus! // Passed from OutageViewController/UnauthenticatedOutageStatusViewController
    var selectedSegmentIndex = BehaviorRelay(value: 0)
    var phoneNumber = BehaviorRelay(value: "")
    var phoneExtension = BehaviorRelay(value: "")
    var comments = BehaviorRelay(value: "")
    var reportFormHidden = BehaviorRelay(value: false)
    
    required init(outageService: OutageService, accountService: AccountService) {
        self.outageService = outageService
        self.accountService = accountService
    }
    
    private(set) lazy var submitEnabled: Driver<Bool> = Driver.combineLatest(self.reportFormHidden.asDriver(),
                                                                             self.phoneNumber.asDriver())
    { [weak self] in
        guard let self = self else { return false }
        let digitsOnlyString = self.extractDigitsFrom($1)
        return !$0 && digitsOnlyString.count == 10
    }
    
    var footerTextViewText: NSAttributedString {
        var localizedString: String
        let phoneNumbers: [String]
        switch Environment.shared.opco {
        case .bge:
            let phone1 = "1-800-685-0123"
            let phone2 = "1-877-778-7798"
            let phone3 = "1-877-778-2222"
            phoneNumbers = [phone1, phone2, phone3]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, leave the area immediately and call %@ or %@\n
                For downed or sparking power lines, please call %@ or %@
                """
                , phone1, phone2, phone1, phone3)
        case .comEd:
            let phone1 = "1-800-334-7661"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a downed or sparking power line, please call %@", phone1)
        case .peco:
            let phone1 = "1-800-841-4141"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a gas emergency or a downed or sparking power line, please call %@", phone1)
        case .pepco:
            let phone1 = "1-877-737-2662"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a downed or sparking power line, please call %@.", phone1)
        case .ace:
            let phone1 = "1-800-833-7476"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("To report a downed or sparking power line, please call %@.", phone1)
        case .delmarva:
            let phone1 = "302-454-0317"
            let phone2 = "1-800-898-8042"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, leave the area immediately and then call %@.\n
                To report a downed or sparking power line, please call %@.
                """
                , phone1, phone2)
        }
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [
            .font: SystemFont.regular.of(textStyle: .caption1),
            .foregroundColor: UIColor.deepGray
        ])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: SystemFont.bold.of(textStyle: .caption1), range: $0)
            }
        }
        return attributedText
    }
    
    lazy var shouldPingMeter: Bool = {
        return outageStatus.activeOutage == false &&
            outageStatus.smartMeterStatus == true
    }()
    
    lazy var shouldPingPHIMeter: Bool = {
        return shouldPingMeter && (Environment.shared.opco == .pepco || Environment.shared.opco == .delmarva)
    }()
    
    func reportOutage(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var outageIssue = OutageIssue.allOut
        if selectedSegmentIndex.value == 1 {
            outageIssue = OutageIssue.partOut
        } else if selectedSegmentIndex.value == 2 {
            outageIssue = OutageIssue.flickering
        }
        
        var outageInfo = OutageInfo(accountNumber: AccountsStore.shared.currentAccount.accountNumber, issue: outageIssue, phoneNumber: extractDigitsFrom(phoneNumber.value), comment:comments.value)
        if phoneExtension.value.count > 0 {
            outageInfo.phoneExtension = phoneExtension.value
        }
        if let locationId = self.outageStatus?.locationId {
            outageInfo.locationId = locationId
        }
        
        outageService.reportOutage(outageInfo: outageInfo)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { _ in
                onSuccess()
                try? WatchSessionManager.shared.updateApplicationContext(applicationContext: [keychainKeys.outageReported : true])
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func reportOutageAnon(onSuccess: @escaping (ReportedOutageResult) -> Void, onError: @escaping (String) -> Void) {
        var outageIssue = OutageIssue.allOut
        if selectedSegmentIndex.value == 1 {
            outageIssue = OutageIssue.partOut
        } else if selectedSegmentIndex.value == 2 {
            outageIssue = OutageIssue.flickering
        }
        
        var outageInfo = OutageInfo(accountNumber: accountNumber ?? outageStatus.accountNumber!, issue: outageIssue, phoneNumber: extractDigitsFrom(phoneNumber.value), comment: comments.value)
        if phoneExtension.value.count > 0 {
            outageInfo.phoneExtension = phoneExtension.value
        }
        if let locationId = self.outageStatus!.locationId {
            outageInfo.locationId = locationId
        }
        
        outageService.reportOutageAnon(outageInfo: outageInfo)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { reportedOutage in
                onSuccess(reportedOutage)
            }, onError: { error in
                onError(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func meterPingGetStatus(onComplete: @escaping (MeterPingInfo) -> Void, onError: @escaping () -> Void) {
        currentPremiseNumber.flatMap { self.outageService.pingMeter(account: AccountsStore.shared.currentAccount, premiseNumber: $0) }.observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { meterPingInfo in
                onComplete(meterPingInfo)
            }, onError: { _ in
                onError()
            }).disposed(by: disposeBag)
    }
    
    func meterPingGetStatusAnon(onComplete: @escaping (MeterPingInfo) -> Void, onError: @escaping () -> Void) {
        
        self.outageService.pingMeterAnon(accountNumber: self.accountNumber!)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { meterPingInfo in
               onComplete(meterPingInfo)
            }, onError: { _ in
                onError()
            }).disposed(by: disposeBag)
    }

    
    private lazy var currentPremiseNumber: Observable<String?> = Observable.just(AccountsStore.shared.currentAccount)
        .flatMap { account -> Observable<String?> in
            if let premiseNumber = account.currentPremise?.premiseNumber {
                return Observable.just(premiseNumber)
            }
            else {
                return self.accountService.fetchAccountDetail(account: AccountsStore.shared.currentAccount).map { return $0.premiseNumber }
            }
    }
    
    private(set) lazy var phoneNumberHasTenDigits: Driver<Bool> = self.phoneNumber.asDriver()
        .map { [weak self] text -> Bool in
            guard let self = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
}
