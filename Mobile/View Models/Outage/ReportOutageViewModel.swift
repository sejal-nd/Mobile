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
    
    var accountNumber: String? // Passed from UnauthenticatedOutageStatusViewController
    var outageStatus: OutageStatus! // Passed from OutageViewController/UnauthenticatedOutageStatusViewController
    var selectedSegmentIndex = Variable(0)
    var phoneNumber = Variable("")
    var phoneExtension = Variable("")
    var comments = Variable("")
    var reportFormHidden = Variable(false)
    
    required init(outageService: OutageService) {
        self.outageService = outageService
    }
    
    private(set) lazy var submitEnabled: Driver<Bool> = Driver.combineLatest(self.reportFormHidden.asDriver(),
                                                                             self.phoneNumber.asDriver())
    { [weak self] in
        guard let `self` = self else { return false }
        let digitsOnlyString = self.extractDigitsFrom($1)
        return !$0 && digitsOnlyString.count == 10
    }
    
    var footerTextViewText: String {
        switch Environment.shared.opco {
        case .bge:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123", comment: "")
        case .comEd:
            return NSLocalizedString("To report a downed or sparking power line, please call 1-800-334-7661", comment: "")
        case .peco:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
        }
    }
    
    lazy var shouldPingMeter: Bool = {
        return Environment.shared.opco == .comEd &&
            outageStatus.activeOutage == false &&
            outageStatus.smartMeterStatus == true
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
        
        var outageInfo = OutageInfo(accountNumber: accountNumber ?? outageStatus.accountNumber!, issue: outageIssue, phoneNumber: extractDigitsFrom(phoneNumber.value), comment:comments.value)
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
        outageService.pingMeter(account: AccountsStore.shared.currentAccount)
            .observeOn(MainScheduler.instance)
            .asObservable()
            .subscribe(onNext: { meterPingInfo in
                onComplete(meterPingInfo)
            }, onError: { _ in
                onError()
            }).disposed(by: disposeBag)
    }
    
    private(set) lazy var phoneNumberHasTenDigits: Driver<Bool> = self.phoneNumber.asDriver()
        .map { [weak self] text -> Bool in
            guard let `self` = self else { return false }
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.count == 10
        }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
    
}
