//
//  NewOutageViewModel.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import RxSwift

class OutageViewModel {
    let disposeBag = DisposeBag()
    
    private var accountService: AccountService
    private var outageService: OutageService
    private var authService: AuthenticationService
    
    private var currentGetMaintenanceModeStatusDisposable: Disposable?
    private var currentGetOutageStatusDisposable: Disposable?
    
    var outageStatus: OutageStatus?
    var hasJustReportedOutage = false
    
    required init(accountService: AccountService,
                  outageService: OutageService,
                  authService: AuthenticationService) {
        self.accountService = accountService
        self.outageService = outageService
        self.authService = authService
    }
    
    deinit {
        currentGetMaintenanceModeStatusDisposable?.dispose()
        currentGetOutageStatusDisposable?.dispose()
    }
    
    func fetchData(onSuccess: @escaping (OutageStatus) -> Void,
                   onError: @escaping (ServiceError) -> Void,
                   onMaintenance: @escaping () -> Void) {
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        currentGetMaintenanceModeStatusDisposable?.dispose()
        currentGetOutageStatusDisposable?.dispose()
        
        currentGetMaintenanceModeStatusDisposable = authService.getMaintenanceMode()
            .subscribe(onNext: { [weak self] status in
                if status.allStatus {
                    onError(ServiceError(serviceCode: ServiceErrorCode.tcUnknown.rawValue))
                } else if status.outageStatus {
                    onMaintenance()
                } else {
                    self?.getOutageStatus(onSuccess: onSuccess, onError: onError)
                }
                }, onError: { [weak self] _ in
                    self?.getOutageStatus(onSuccess: onSuccess, onError: onError)
            })
    }
    
    func getOutageStatus(onSuccess: @escaping (OutageStatus) -> Void, onError: @escaping (ServiceError) -> Void) {
        // Unsubscribe before starting a new request to prevent race condition when quickly swiping through accounts
        currentGetOutageStatusDisposable?.dispose()
        
        currentGetOutageStatusDisposable = outageService.fetchOutageStatus(account: AccountsStore.shared.currentAccount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { outageStatus in
                self.outageStatus = outageStatus
                onSuccess(outageStatus)
            }, onError: { error in
                guard let serviceError = error as? ServiceError else { return }
                
                if serviceError.serviceCode == ServiceErrorCode.fnAccountFinaled.rawValue {
                    if let outageStatus = OutageStatus.from(["flagFinaled": true]) {
                        self.outageStatus = outageStatus
                        onSuccess(outageStatus)
                    }
                } else if serviceError.serviceCode == ServiceErrorCode.fnAccountNoPay.rawValue {
                    if let outageStatus = OutageStatus.from(["flagNoPay": true]) {
                        self.outageStatus = outageStatus
                        onSuccess(outageStatus)
                    }
                } else if serviceError.serviceCode == ServiceErrorCode.fnNonService.rawValue {
                    if let outageStatus = OutageStatus.from(["flagNonService": true]) {
                        self.outageStatus = outageStatus
                        onSuccess(outageStatus)
                    }
                } else {
                    onError(serviceError)
                }
            })
    }
    
    
    var reportedOutage: ReportedOutageResult? {
        return outageService.getReportedOutageResult(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage {
            let timeString = DateFormatter.outageOpcoDateFormatter.string(from: reportedOutage.reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        
        return NSLocalizedString("Reported", comment: "")
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
        }
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: SystemFont.regular.of(textStyle: .caption1)])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: SystemFont.semibold.of(textStyle: .caption1), range: $0)
            }
        }
        return attributedText
    }
}
