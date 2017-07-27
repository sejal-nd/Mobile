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
    
    var outageStatus: OutageStatus?
    var selectedSegmentIndex = Variable(0)
    var phoneNumber = Variable("")
    var phoneExtension = Variable("")
    var reportFormHidden = Variable(false)
    let submitEnabled = Variable(false)
    
    required init(outageService: OutageService) {
        self.outageService = outageService
        if Environment.sharedInstance.opco == .comEd {
            reportFormHidden.value = true
        }
        
        Observable.combineLatest(self.reportFormHidden.asObservable(), self.phoneNumber.asObservable()) {
            let digitsOnlyString = self.extractDigitsFrom($1)
            return !$0 && digitsOnlyString.characters.count == 10
            }
            .bind(to: submitEnabled)
            .addDisposableTo(disposeBag)
    }
    
    func getFooterTextViewText() -> String {
        switch Environment.sharedInstance.opco {
        case .bge:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-685-0123", comment: "")
        case .comEd:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-EDISON-1", comment: "")
        case .peco:
            return NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141", comment: "")
        }
    }
    
    func reportOutage(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var outageIssue = OutageIssue.AllOut
        if selectedSegmentIndex.value == 1 {
            outageIssue = OutageIssue.PartOut
        } else if selectedSegmentIndex.value == 2 {
            outageIssue = OutageIssue.Flickering
        }

        var outageInfo = OutageInfo(account: AccountsStore.sharedInstance.currentAccount, issue: outageIssue, phoneNumber: extractDigitsFrom(phoneNumber.value))
        if phoneExtension.value.characters.count > 0 {
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
            .addDisposableTo(disposeBag)
    }
    
    func meterPingGetPowerStatus(onPowerVerified: @escaping (_ canPerformVoltageCheck: Bool) -> Void, onError: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(2500)) {
            if self.outageStatus!.meterPingInfo!.pingResult {
                if self.outageStatus!.meterPingInfo!.voltageResult {
                    onPowerVerified(true)
                } else {
                    onPowerVerified(false)
                }
            } else {
                onError()
            }
        }
    }
    
    func meterPingGetVoltageStatus(onVoltageVerified: @escaping () -> Void, onError: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(2500)) {
            if let voltageReads = self.outageStatus!.meterPingInfo!.voltageReads {
                if voltageReads.lowercased().contains("improper") {
                    onError()
                } else if voltageReads.lowercased().contains("proper") {
                    onVoltageVerified()
                }
            } else {
                onError()
            }
        }
    }
    
    func phoneNumberHasTenDigits() -> Observable<Bool> {
        return phoneNumber.asObservable().map({ text -> Bool in
            let digitsOnlyString = self.extractDigitsFrom(text)
            return digitsOnlyString.characters.count == 10
        })
    }
    
    private func extractDigitsFrom(_ string: String) -> String {
        return string.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}
