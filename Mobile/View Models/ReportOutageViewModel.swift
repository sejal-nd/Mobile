//
//  ReportOutageViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 3/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ReportOutageViewModel {
    
    private var outageService: OutageService
    
    var account: Account?
    var selectedSegmentIndex = Variable(0)
    var phoneNumber = Variable("")
    var phoneExtension = Variable("")
    var reportFormHidden = Variable(false)
    
    required init(outageService: OutageService) {
        self.outageService = outageService
        if Environment.sharedInstance.opco == "ComEd" {
            reportFormHidden.value = true
        }
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return Observable.combineLatest(reportFormHidden.asObservable(), phoneNumber.asObservable()) {
            return !$0 && $1.characters.count > 0
        }
    }
    
    func getFooterTextViewText() -> String {
        var string = ""
        switch Environment.sharedInstance.opco {
        case "BGE":
            string = "To report a gas emergency, please call 1-800-685-0123\n\nFor downed or sparking power lines or dim / flickering lights, please call 1-877-778-2222"
            break
        case "ComEd":
            string = "To report a gas emergency or a downed or sparking power line, please call 1-800-EDISON-1"
            break
        case "PECO":
            string = "To report a gas emergency or a downed or sparking power line, please call 1-800-841-4141"
            break
        default:
            break
        }
        return string
    }
    
    func reportOutage(onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        var outageIssue = OutageIssue.AllOut
        if selectedSegmentIndex.value == 1 {
            outageIssue = OutageIssue.PartOut
        } else if selectedSegmentIndex.value == 2 {
            outageIssue = OutageIssue.Flickering
        }

        var outageInfo = OutageInfo(account: account!, issue: outageIssue, phoneNumber: phoneNumber.value)
        if phoneExtension.value.characters.count > 0 {
            outageInfo.phoneExtension = phoneExtension.value
        }

        outageService.reportOutage(outageInfo: outageInfo) { (result: ServiceResult<Void>) in
            switch(result) {
            case .Success:
                onSuccess()
                break
            case .Failure(let error):
                onError(error.localizedDescription)
                break
            }
        }
    }
    
    func meterPingGetPowerStatus(onPowerVerified: @escaping (_ canPerformVoltageCheck: Bool) -> Void, onError: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            onPowerVerified(true)
            //onPowerVerified(false)
            //onError()
        }
    }
    
    func meterPingGetVoltageStatus(onVoltageVerified: @escaping () -> Void, onError: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            onVoltageVerified()
            //onError()
        }
    }
}
