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
    
    var accountNumber: String? // Passed from UnauthenticatedOutageStatusViewController
    var outageStatus: OutageStatus! // Passed from OutageViewController/UnauthenticatedOutageStatusViewController
    var selectedSegmentIndex = BehaviorRelay(value: 0)
    var phoneNumber = BehaviorRelay(value: "")
    var phoneExtension = BehaviorRelay(value: "")
    var comments = BehaviorRelay(value: "")
    var reportFormHidden = BehaviorRelay(value: false)
    
    required init() {
        
    }
    
    private(set) lazy var submitEnabled: Driver<Bool> = Driver.combineLatest(self.reportFormHidden.asDriver(),
                                                                             self.phoneNumber.asDriver())
    { [weak self] in
        guard let self = self else { return false }
        let digitsOnlyString = self.extractDigitsFrom($1)
        return Configuration.shared.opco.isPHI ? !$0 : !$0 && digitsOnlyString.count == 10
    }
    
    var footerTextViewText: NSAttributedString {
        var localizedString: String
        let phoneNumbers: [String]
        switch Configuration.shared.opco {
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
            let phone2 = "1-844-841-4151"
            phoneNumbers = [phone1, phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                To report a downed or sparking power line, please call %@.\n
                If you smell natural gas, leave the area immediately and call %@ or %@.
                """
                , phone1, phone1, phone2)
        case .pepco:
            let phone1 = "1-877-737-2662"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("If you see downed power lines, leave the area immediately and call Pepco at %@.", phone1)
        case .ace:
            let phone1 = "1-800-833-7476"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat("If you see downed power lines, leave the area immediately and call Atlantic City Electric at %@.", phone1)
        case .delmarva:
            let phone1 = "302-454-0317"
            let phone2 = "1-800-898-8042"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, leave the area immediately and then call %@.\n
                If you see downed power lines, leave the area immediately and call Delmarva at %@.
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
        return outageStatus.isActiveOutage == false &&
            outageStatus.isSmartMeter == true
    }()
    
    lazy var shouldPingPHIMeter: Bool = {
        return shouldPingMeter && (Configuration.shared.opco == .pepco || Configuration.shared.opco == .delmarva)
    }()
    
    func reportOutage(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var outageIssue = OutageIssue.allOut
        if selectedSegmentIndex.value == 1 {
            outageIssue = OutageIssue.partOut
        } else if selectedSegmentIndex.value == 2 {
            outageIssue = OutageIssue.flickering
        }
        
        var outageRequest = OutageRequest(accountNumber: accountNumber ?? AccountsStore.shared.currentAccount.accountNumber,
                                          issue: outageIssue,
                                          phoneNumber: extractDigitsFrom(phoneNumber.value))
        
        var comment = ""
        let unwrappedComment = comments.value
        if !unwrappedComment.isEmpty {
            if let data = unwrappedComment.data(using: .nonLossyASCII) { // Emojis would cause request to fail
                comment = String(data: data, encoding: .utf8) ?? ""
            } else {
                comment = unwrappedComment
            }
        }
        
        if !comment.isEmpty {
            outageRequest.isUnusual = .yes
            outageRequest.unusualMessage = comment
        }
        
        if phoneExtension.value.count > 0 {
            outageRequest.phoneExtension = phoneExtension.value
        }
        if let locationId = self.outageStatus?.locationId {
            outageRequest.locationId = locationId
        }
        
        OutageService.reportOutage(outageRequest: outageRequest) { result in
            switch result {
            case .success:
                onSuccess()
                try? WatchSessionController.shared.updateApplicationContext(applicationContext: [WatchSessionController.Key.outageReported : true])
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    func reportOutageAnon(onSuccess: @escaping (ReportedOutageResult) -> Void, onError: @escaping (String) -> Void) {
        var outageIssue = OutageIssue.allOut
        if selectedSegmentIndex.value == 1 {
            outageIssue = OutageIssue.partOut
        } else if selectedSegmentIndex.value == 2 {
            outageIssue = OutageIssue.flickering
        }
        
        
        var outageRequest = OutageRequest(accountNumber: accountNumber ?? outageStatus.accountNumber!,
                                          issue: outageIssue,
                                          phoneNumber: extractDigitsFrom(phoneNumber.value))
        
        var comment = ""
        let unwrappedComment = comments.value
        if !unwrappedComment.isEmpty {
            if let data = unwrappedComment.data(using: .nonLossyASCII) { // Emojis would cause request to fail
                comment = String(data: data, encoding: .utf8) ?? ""
            } else {
                comment = unwrappedComment
            }
        }
        
        if !comment.isEmpty {
            outageRequest.isUnusual = .yes
            outageRequest.unusualMessage = comment
        }
        
        if phoneExtension.value.count > 0 {
            outageRequest.phoneExtension = phoneExtension.value
        }
        if let locationId = self.outageStatus?.locationId {
            outageRequest.locationId = locationId
        }
        
        if let auid = self.outageStatus?.auid {
            outageRequest.auid = auid
        }
                
        OutageService.reportOutageAnon(outageRequest: outageRequest) { result in
            switch result {
            case .success(let reportedOutage):
                onSuccess(reportedOutage)
            case .failure(let error):
                onError(error.description)
            }
        }
    }
    
    func meterPingGetStatus(onComplete: @escaping (MeterPingResult) -> Void, onError: @escaping () -> Void) {
        OutageService.pingMeter(accountNumber: AccountsStore.shared.currentAccount.accountNumber,
                                premiseNumber: AccountsStore.shared.premiseNumber) { result in
            switch result {
            case .success(let meterPingInfo):
                onComplete(meterPingInfo)
            case .failure:
                onError()
            }
        }
    }
    
    func meterPingGetStatusAnon(onComplete: @escaping (MeterPingResult) -> Void, onError: @escaping () -> Void) {
        OutageService.pingMeterAnon(accountNumber: accountNumber!) { result in
            switch result {
            case .success(let meterPingInfo):
                onComplete(meterPingInfo)
            case .failure:
                onError()
            }
        }
    }

    
    private lazy var currentPremiseNumber: Observable<String?> = Observable.just(AccountsStore.shared.currentAccount)
        .flatMap { account -> Observable<String?> in
            if let premiseNumber = account.currentPremise?.premiseNumber {
                return Observable.just(premiseNumber)
            }
            else {
                return AccountService.rx.fetchAccountDetails().map { return $0.premiseNumber }
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
