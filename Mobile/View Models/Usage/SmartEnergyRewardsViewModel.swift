//
//  SmartEnergyRewardsViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 10/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class SmartEnergyRewardsViewModel {
    
    private let eventResults: Observable<[SERResult]> // Passed from HomeUsageCardView

    let barGraphSelectionStates = Variable([Variable(false), Variable(false), Variable(true)])
    
    required init(eventResults: Observable<[SERResult]>) {
        self.eventResults = eventResults
    }
    
    private(set) lazy var latest3EventsThisSeason: Driver<[SERResult]> = eventResults
        .map { eventResults in
            guard let latestEvent = eventResults.last else { return [] }
            
            let latestEventYear = Calendar.opCo.component(.year, from: latestEvent.eventStart)
            
            return eventResults
                .suffix(3)
                .filter { Calendar.opCo.component(.year, from: $0.eventStart) == latestEventYear }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var numBarsToShow: Driver<Int> = self.latest3EventsThisSeason.map { $0.count }
    private(set) lazy var shouldShowBar1: Driver<Bool> = self.numBarsToShow.map { $0 == 3 }
    private(set) lazy var shouldShowBar2: Driver<Bool> = self.numBarsToShow.map { $0 >= 2 }
    private(set) lazy var shouldShowBar3: Driver<Bool> = self.numBarsToShow.map { $0 >= 1 }
    
    // MARK: Bar 1
    
    private(set) lazy var bar1DollarLabelText: Driver<String?> = self.latest3EventsThisSeason.map {
        if $0.count < 3 { return nil }
        return $0[0].savingDollar.currencyString
    }
    
    private(set) lazy var bar1DateLabelText: Driver<String?> = self.latest3EventsThisSeason.map {
        if $0.count < 3 { return nil }
        return $0[0].eventStart.shortMonthAndDayString.uppercased()
    }
    
    private(set) lazy var bar1HeightConstraintValue: Driver<CGFloat> = self.latest3EventsThisSeason.map {
        if $0.count < 3 { return 0 }
        let bar1Val = $0[0].savingDollar
        let bar2Val = $0[1].savingDollar
        let bar3Val = $0[2].savingDollar
        if max(bar1Val, bar2Val, bar3Val) == bar1Val && bar1Val != 0 {
            return 121
        } else if max(bar2Val, bar3Val) == bar2Val {
            let fraction = CGFloat(121.0 * (bar1Val / bar2Val))
            return fraction > 3 ? fraction : 3
        } else {
            let fraction = CGFloat(121.0 * (bar1Val / bar3Val))
            return fraction > 3 ? fraction : 3
        }
    }
    
    private(set) lazy var bar1A11yLabel: Driver<String?> = self.latest3EventsThisSeason.map {
        if $0.count < 3 { return nil }
        let event = $0[0]
        let dateString = event.eventStart.fullMonthDayAndYearString
        let timeString = String(format: NSLocalizedString("Peak Hours: %@", comment: ""), "\(event.eventStart.hourAmPmString) - \(event.eventEnd.hourAmPmString)")
        let typicalUseString = String(format: NSLocalizedString("Typical use: %.1f kWh", comment: ""), event.baselineKWH)
        let actualUseString = String(format: NSLocalizedString("Actual use: %.1f kWh", comment: ""), event.actualKWH)
        let energySavingsString = String(format: NSLocalizedString("Energy savings: %.1f kWh", comment: ""), event.savingKWH)
        let billCreditString = String(format: NSLocalizedString("Bill credit: %@", comment: ""), event.savingDollar.currencyString)
        return String(format: "%@. %@. %@. %@. %@. %@", dateString, timeString, typicalUseString, actualUseString, energySavingsString, billCreditString)
    }
    
    // MARK: Bar 2
    
    private(set) lazy var bar2DollarLabelText: Driver<String?> = self.latest3EventsThisSeason.map {
        if $0.count == 3 {
            return $0[1].savingDollar.currencyString
        } else if $0.count == 2 {
            return $0[0].savingDollar.currencyString
        }
        return nil
    }
    
    private(set) lazy var bar2DateLabelText: Driver<String?> = self.latest3EventsThisSeason.map {
        if $0.count == 3 {
            return $0[1].eventStart.shortMonthAndDayString.uppercased()
        } else if $0.count == 2 {
            return $0[0].eventStart.shortMonthAndDayString.uppercased()
        }
        return nil
    }
    
    private(set) lazy var bar2HeightConstraintValue: Driver<CGFloat> = self.latest3EventsThisSeason.map {
        if $0.count == 3 {
            let bar1Val = $0[0].savingDollar
            let bar2Val = $0[1].savingDollar
            let bar3Val = $0[2].savingDollar
            
            if max(bar1Val, bar2Val, bar3Val) == bar2Val && bar2Val != 0 {
                return 121
            } else if max(bar1Val, bar3Val) == bar1Val {
                let fraction = CGFloat(121.0 * (bar2Val / bar1Val))
                return fraction > 3 ? fraction : 3
            } else {
                let fraction = CGFloat(121.0 * (bar2Val / bar3Val))
                return fraction > 3 ? fraction : 3
            }
        } else if $0.count == 2 {
            let bar2Val = $0[0].savingDollar
            let bar3Val = $0[1].savingDollar
            if bar2Val > bar3Val && bar2Val != 0 {
                return 121
            } else {
                let fraction = CGFloat(121.0 * (bar2Val / bar3Val))
                return fraction > 3 ? fraction : 3
            }
        }
        return 0
    }
    
    private(set) lazy var bar2A11yLabel: Driver<String?> = self.latest3EventsThisSeason.map {
        var event: SERResult
        if $0.count == 3 {
            event = $0[1]
        } else if $0.count == 2 {
            event = $0[0]
        } else {
            return nil
        }
        let dateString = event.eventStart.fullMonthDayAndYearString
        let timeString = String(format: NSLocalizedString("Peak Hours: %@", comment: ""), "\(event.eventStart.hourAmPmString) - \(event.eventEnd.hourAmPmString)")
        let typicalUseString = String(format: NSLocalizedString("Typical use: %.1f kWh", comment: ""), event.baselineKWH)
        let actualUseString = String(format: NSLocalizedString("Actual use: %.1f kWh", comment: ""), event.actualKWH)
        let energySavingsString = String(format: NSLocalizedString("Energy savings: %.1f kWh", comment: ""), event.savingKWH)
        let billCreditString = String(format: NSLocalizedString("Bill credit: %@", comment: ""), event.savingDollar.currencyString)
        return String(format: "%@. %@. %@. %@. %@. %@", dateString, timeString, typicalUseString, actualUseString, energySavingsString, billCreditString)
    }
    
    // MARK: Bar 3
    
    private(set) lazy var bar3DollarLabelText: Driver<String?> = self.latest3EventsThisSeason.map {
        if $0.count == 3 {
            return $0[2].savingDollar.currencyString
        } else if $0.count == 2 {
            return $0[1].savingDollar.currencyString
        } else if $0.count == 1 {
            return $0[0].savingDollar.currencyString
        }
        return nil
    }
    
    private(set) lazy var bar3DateLabelText: Driver<String?> = self.latest3EventsThisSeason.map {
        if $0.count == 3 {
            return $0[2].eventStart.shortMonthAndDayString.uppercased()
        } else if $0.count == 2 {
            return $0[1].eventStart.shortMonthAndDayString.uppercased()
        } else if $0.count == 1 {
            return $0[0].eventStart.shortMonthAndDayString.uppercased()
        }
        return nil
    }
    
    private(set) lazy var bar3HeightConstraintValue: Driver<CGFloat> = self.latest3EventsThisSeason.map {
        if $0.count == 3 {
            let bar1Val = $0[0].savingDollar
            let bar2Val = $0[1].savingDollar
            let bar3Val = $0[2].savingDollar
            
            if max(bar1Val, bar2Val, bar3Val) == bar3Val && bar3Val != 0 {
                return 121
            } else if max(bar1Val, bar2Val) == bar1Val {
                let fraction = CGFloat(121.0 * (bar3Val / bar1Val))
                return fraction > 3 ? fraction : 3
            } else {
                let fraction = CGFloat(121.0 * (bar3Val / bar2Val))
                return fraction > 3 ? fraction : 3
            }
        } else if $0.count == 2 {
            let bar2Val = $0[0].savingDollar
            let bar3Val = $0[1].savingDollar
            if bar3Val > bar2Val && bar3Val != 0 {
                return 121
            } else {
                let fraction = CGFloat(121.0 * (bar3Val / bar2Val))
                return fraction > 3 ? fraction : 3
            }
        } else if $0.count == 1 && $0[0].savingDollar > 0 {
            return 121
        }
        return 3
    }
    
    private(set) lazy var bar3A11yLabel: Driver<String?> = self.latest3EventsThisSeason.map {
        var event: SERResult
        if $0.count == 3 {
            event = $0[2]
        } else if $0.count == 2 {
            event = $0[1]
        } else if $0.count == 1 {
            event = $0[0]
        } else {
            return nil
        }
        let dateString = event.eventStart.fullMonthDayAndYearString
        let timeString = String(format: NSLocalizedString("Peak Hours: %@", comment: ""), "\(event.eventStart.hourAmPmString) - \(event.eventEnd.hourAmPmString)")
        let typicalUseString = String(format: NSLocalizedString("Typical use: %.1f kWh", comment: ""), event.baselineKWH)
        let actualUseString = String(format: NSLocalizedString("Actual use: %.1f kWh", comment: ""), event.actualKWH)
        let energySavingsString = String(format: NSLocalizedString("Energy savings: %.1f kWh", comment: ""), event.savingKWH)
        let billCreditString = String(format: NSLocalizedString("Bill credit: %@", comment: ""), event.savingDollar.currencyString)
        return String(format: "%@. %@. %@. %@. %@. %@", dateString, timeString, typicalUseString, actualUseString, energySavingsString, billCreditString)
    }
    
    // MARK: Description Box Drivers
    
    private(set) lazy var barDescriptionDateLabelText: Driver<String?> =
        Driver.combineLatest(self.barGraphSelectionStates.asDriver(), self.latest3EventsThisSeason) { [weak self] selectionStates, latest3Events in
            guard let self = self else { return nil }
            guard !latest3Events.isEmpty else { return nil }
            let event = self.eventFor(selectionStates: selectionStates, latest3Events: latest3Events)
            return event.eventStart.fullMonthDayAndYearString
        }
    
    private(set) lazy var barDescriptionPeakHoursLabelText: Driver<String?> =
        Driver.combineLatest(self.barGraphSelectionStates.asDriver(), self.latest3EventsThisSeason) { [weak self] selectionStates, latest3Events in
            guard let self = self else { return nil }
            guard !latest3Events.isEmpty else { return nil }
            let event = self.eventFor(selectionStates: selectionStates, latest3Events: latest3Events)
            return String(format: NSLocalizedString("Peak Hours: %@", comment: ""), "\(event.eventStart.hourAmPmString) - \(event.eventEnd.hourAmPmString)")
        }
    
    private(set) lazy var barDescriptionTypicalUseValueLabelText: Driver<String?> =
        Driver.combineLatest(self.barGraphSelectionStates.asDriver(), self.latest3EventsThisSeason) { [weak self] selectionStates, latest3Events in
            guard let self = self else { return nil }
            guard !latest3Events.isEmpty else { return nil }
            let event = self.eventFor(selectionStates: selectionStates, latest3Events: latest3Events)
            return String(format: "%.1f kWh", event.baselineKWH)
        }
    
    private(set) lazy var barDescriptionActualUseValueLabelText: Driver<String?> =
        Driver.combineLatest(self.barGraphSelectionStates.asDriver(), self.latest3EventsThisSeason) { [weak self] selectionStates, latest3Events in
            guard let self = self else { return nil }
            guard !latest3Events.isEmpty else { return nil }
            let event = self.eventFor(selectionStates: selectionStates, latest3Events: latest3Events)
            return String(format: "%.1f kWh", event.actualKWH)
        }

    private(set) lazy var barDescriptionEnergySavingsValueLabelText: Driver<String?> =
        Driver.combineLatest(self.barGraphSelectionStates.asDriver(), self.latest3EventsThisSeason) { [weak self] selectionStates, latest3Events in
            guard let self = self else { return nil }
            guard !latest3Events.isEmpty else { return nil }
            let event = self.eventFor(selectionStates: selectionStates, latest3Events: latest3Events)
            return String(format: "%.1f kWh", event.savingKWH)
        }
    
    private(set) lazy var barDescriptionBillCreditValueLabelText: Driver<String?> =
        Driver.combineLatest(self.barGraphSelectionStates.asDriver(), self.latest3EventsThisSeason) { [weak self] selectionStates, latest3Events in
            guard let self = self else { return nil }
            guard !latest3Events.isEmpty else { return nil }
            let event = self.eventFor(selectionStates: selectionStates, latest3Events: latest3Events)
            return event.savingDollar.currencyString
        }
    
    
    // MARK: Selection States
    
    func setBarSelected(tag: Int) {
        for i in stride(from: 0, to: barGraphSelectionStates.value.count, by: 1) {
            let boolVar = barGraphSelectionStates.value[i]
            boolVar.value = i == tag
        }
        barGraphSelectionStates.value = barGraphSelectionStates.value // Trigger Variable onNext
    }
    
    // MARK: Helpers
    
    private func eventFor(selectionStates: [Variable<Bool>], latest3Events: [SERResult]) -> SERResult {
        var event: SERResult
        if selectionStates[0].value { // Bar 1
            event = latest3Events[0]
        } else if selectionStates[1].value { // Bar 2
            if latest3Events.count == 3 {
                event = latest3Events[1]
            } else {
                event = latest3Events[0]
            }
        } else { // Bar 3
            if latest3Events.count == 3 {
                event = latest3Events[2]
            } else if latest3Events.count == 2 {
                event = latest3Events[1]
            } else {
                event = latest3Events[0]
            }
        }
        return event
    }

}
