//
//  StormModeHomeViewModel.swift
//  Mobile
//
//  Created by Samuel Francis on 8/28/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class StormModeHomeViewModel {

    let opco = Configuration.shared.opco
    
    let stormModePollInterval = 30
        
    private let disposeBag = DisposeBag()
    
    var currentOutageStatus: OutageStatus?
    let stormModeUpdate = BehaviorRelay<Alert?>(value: nil)
    var outageTracker = BehaviorRelay<OutageTracker?>(value: nil)
    
    var stormModeEnded = false
    
    // Feature Flag Value
    var outageMapURLString = FeatureFlagUtility.shared.string(forKey: .outageMapURL)

    func startStormModePolling() -> Driver<Void> {
        return Observable<Int>
            .interval(.seconds(stormModePollInterval), scheduler: MainScheduler.instance)
            .mapTo(())
            // Start polling immediately
            .startWith(())
            .toAsyncRequest { [weak self] in
                self?.getMaintenanceMode() ?? .empty()
            }
            // Ignore errors and positive storm mode responses
            .elements()
            .filter { !$0.storm }
            // Stop polling after storm mode ends
            .take(1)
            .mapTo(())
            .asDriver(onErrorDriveWith: .empty())
            .do(onNext: { [weak self] in self?.stormModeEnded = true })
    }
    
    func getMaintenanceMode() -> Observable<MaintenanceMode> {
        return Observable.create { observer -> Disposable in
            AnonymousService.maintenanceMode { result in
                switch result {
                case .success(let maintenanceMode):
                    observer.onNext(maintenanceMode)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchData(onSuccess: @escaping () -> Void,
                   onError: @escaping (NetworkingError) -> Void) {
        
        getOutageStatus(onSuccess: onSuccess, onError: onError)
    }
    
    func getOutageStatus(onSuccess: @escaping () -> Void, onError: @escaping (NetworkingError) -> Void) {
        OutageService.fetchOutageStatus(accountNumber: AccountsStore.shared.currentAccount.accountNumber, premiseNumberString: AccountsStore.shared.currentAccount.currentPremise?.premiseNumber ?? "") { [weak self] result in
            switch result {
            case .success(let outageStatus):
                self?.currentOutageStatus = outageStatus
                self?.fetchOutageTracker()
                onSuccess()
            case .failure(let error):
                self?.currentOutageStatus = nil
                onError(error)
            }
        }
    }
    
    func fetchOutageTracker() {
        AccountService.rx.fetchAccountDetails(payments: false, programs: false).flatMap {
            return OutageService.rx.fetchOutageTracker(
                accountNumber: $0.accountNumber,
                deviceId: $0.premiseInfo.first?.servicePoints.first?.usagePointLocation?.mRID ?? "",
                servicePointId: $0.premiseInfo.first?.servicePoints.first?.serviceLocation?.mRID ?? "")
        }.subscribe(onNext: { tracker in
            self.outageTracker.accept(tracker)
        }, onError: { error in
            self.outageTracker.accept(nil)
            Log.info("error fetching tracker: \(error.localizedDescription)")
        }).disposed(by: disposeBag)
    }
    
    func getStormModeUpdate() {
        AlertService.fetchAlertBanner(bannerOnly: false, stormOnly: true) { [weak self] result in
            switch result {
            case .success(let updates):
                if updates.count > 0 {
                    self?.stormModeUpdate.accept(updates[0])
                }
            case .failure:
                break
            }
        }
    }
    
    // PHI Storm Downed Lines Script Update
    var stormAttrString: NSAttributedString {
        let stormAttrString: NSMutableAttributedString
        switch opco {
            case .ace:
            let opcoTitle = opco.displayString
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, leave the area immediately and call %@ at ", comment: ""), opcoTitle)
            stormAttrString = NSMutableAttributedString(string: localizedString) 
            case .delmarva:
            let opcoTitle = opco.displayString
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, leave the area immediately and call %@ at ", comment: ""), opcoTitle)
            stormAttrString = NSMutableAttributedString(string: localizedString)
            case .pepco:
            let opcoTitle = opco.displayString
            let localizedString = String(format: NSLocalizedString("If you see downed power lines, leave the area immediately and call %@ at ", comment: ""), opcoTitle)
            stormAttrString = NSMutableAttributedString(string: localizedString)
        }
    }

    var reportedOutage: ReportedOutageResult? {
        guard AccountsStore.shared.currentIndex != nil else { return nil }
        return OutageService.getReportedOutageResult(accountNumber: AccountsStore.shared.currentAccount.accountNumber)
    }
    
    var estimatedRestorationDateString: String {
        if let reportedOutage = reportedOutage {
            if let reportedETR = reportedOutage.etr {
                return DateFormatter.outageOpcoDateFormatter.string(from: reportedETR)
            }
        } else {
            if let statusETR = currentOutageStatus?.estimatedRestorationDate {
                return DateFormatter.outageOpcoDateFormatter.string(from: statusETR)
            }
        }
        return Configuration.shared.opco.isPHI ? NSLocalizedString("Pending Assessment", comment: "") : NSLocalizedString("Assessing Damage", comment: "")
    }
    
    var outageReportedDateString: String {
        if let reportedOutage = reportedOutage, let reportedTime = reportedOutage.reportedTime {
            let timeString = DateFormatter.outageOpcoDateFormatter.string(from: reportedTime)
            return String(format: NSLocalizedString("Reported %@", comment: ""), timeString)
        }
        
        return NSLocalizedString("Reported", comment: "")
    }
        
    var gasOnlyMessage: String {
        var firstLine = NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.", comment: "")
        let secondLine: String?
        switch Configuration.shared.opco {
        case .bge:
            secondLine = NSLocalizedString("If you smell natural gas, leave the area immediately and call", comment: "")
        case .delmarva:
            firstLine = NSLocalizedString("Natural gas emergencies cannot be reported online, but we want to hear from you right away.", comment: "")
            secondLine = NSLocalizedString("If you smell natural gas, leave the area immediately and then call", comment: "")
        case .peco:
            secondLine = NSLocalizedString("To issue a Gas Emergency Order, please call", comment: "")
        case .ace, .comEd, .pepco:
            secondLine = nil
        }
        
        if let secondLine = secondLine {
            return firstLine + "\n\n" + secondLine
        } else {
            return firstLine
        }
    }
    
    var accountNonPayFinaledMessage: String {
        if Configuration.shared.opco == .bge {
            return NSLocalizedString("Our records indicate that your services have been disconnected due to non-payment. If you wish to restore services, please make a payment or contact Customer Service at 1-800-685-0123 for further assistance.", comment: "")
        } else {
            if currentOutageStatus!.isFinaled {
                return NSLocalizedString("Outage Status and Outage Reporting are not available for this account.", comment: "")
            } else if currentOutageStatus!.isNoPay {
                return NSLocalizedString("Our records indicate that you have been cut for non-payment. If you wish to restore your power, please make a payment.", comment: "")
            }
        }
        return ""
    }
    
    var reportOutageEnabled: Bool {
        return !(currentOutageStatus?.isFinaled ?? false ||
            currentOutageStatus?.isNoPay ?? false ||
            currentOutageStatus?.isNonService ?? false)
    }
    
    // MARK  OutageTracker
    
    var showOutageTracker: Bool {
        return Configuration.shared.opco == .bge
    }
    var status: OutageTracker.Status {
        guard let trackerStatus = outageTracker.value?.trackerStatus else {
            return .none
        }
        return OutageTracker.Status(rawValue: trackerStatus) ?? .none
    }
    var events: [EventSet] {
        guard let events = outageTracker.value?.eventSet else {
            return []
        }
        return events
    }
    var neighborCount: String {
        guard let count = outageTracker.value?.customersOutOnOutage else {
            return "Unavailable"
        }
        return NSLocalizedString(count, comment: "")
    }
    var outageCount: String {
        guard let count = outageTracker.value?.outageSummary else {
            return "Unavailable"
        }
        return NSLocalizedString(count, comment: "")
    }
    var isActiveOutage: Bool {
        guard let tracker = outageTracker.value else {
            return true
        }
        return tracker.isOutageValid
    }
    var isPaused: Bool {
        guard let tracker = outageTracker.value else {
            return false
        }
        if tracker.isCrewLeftSite == true || tracker.isCrewDiverted == true {
            return true
        }
        return false
    }
    var isDefinitive: Bool {
        guard let tracker = outageTracker.value, let status = tracker.meterStatus else {
            return false
        }
        return status.uppercased() == "ON"
    }
    var lastUpdated: String {
        var time = ""
        if let dateString = outageTracker.value?.lastUpdated {
            if let date = DateFormatter.apiFormatter.date(from: dateString) {
                time = DateFormatter.hmmaFormatter.string(from: date)
            }
        }
        return time
    }
    var hideWhyButton: Bool {
        guard let tracker = outageTracker.value else { return true }
        guard let isCrewLeftSite = tracker.isCrewLeftSite,
              let isCrewDiverted = tracker.isCrewDiverted else {
                  return true
              }
        
        if status == .restored { return false }
        if status == .onSite {
            if isCrewLeftSite || isCrewDiverted {
                return false
            }
        } else if status == .enRoute {
            if isCrewDiverted {
                return false
            }
        }
        
        return true
    }
    var whyButtonText: String {
        if status == .restored {
            return NSLocalizedString("Still Have an Outage?", comment: "")
        } else {
            return NSLocalizedString("Why Did This Happen?", comment: "")
        }
    }
    var surveyURL: String {
        switch status {
            case .reported:
                return "https://www.surveymonkey.com/r/HHCD7YP"
            case .assigned:
                return "https://www.surveymonkey.com/r/HPSN8XX"
            case .enRoute:
                return "https://www.surveymonkey.com/r/HPTDG6T"
            case .onSite:
                return "https://www.surveymonkey.com/r/HPXXPCW"
            case .restored:
                return "https://www.surveymonkey.com/r/HPXZBBD"
            default:
                return ""
        }
    }
    var headerContentText: String {
        var text = "Due to severe weather, the most relevant features are optimized to allow us to better serve you."
        
        if showOutageTracker {
            text = "The app is adjusted temporarily due to severe weather."
        }
        return NSLocalizedString(text, comment: "")
    }
}
