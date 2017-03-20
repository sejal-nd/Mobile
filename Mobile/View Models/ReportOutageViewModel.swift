//
//  ReportOutageViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 3/16/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

class ReportOutageViewModel {
    
    private var outageService: OutageService?
    
    var account: Account?
    var selectedSegmentIndex = Variable(0)
    var phoneNumber = Variable("")
    var phoneExtension = Variable("")
    
    required init(outageService: OutageService) {
        self.outageService = outageService
    }
    
    func submitButtonEnabled() -> Observable<Bool> {
        return phoneNumber.asObservable().map{ text -> Bool in
            return text.characters.count > 0
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
        if phoneNumber.value.characters.count > 0 {
            outageInfo.phoneExtension = phoneNumber.value
        }
        
        outageService!.reportOutage(outageInfo: outageInfo) { (result: ServiceResult<Void>) in
            onSuccess()
        }
    }
}
