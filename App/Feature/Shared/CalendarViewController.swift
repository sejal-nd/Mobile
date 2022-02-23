//
//  CalendarViewController.swift
//  EUMobile
//
//  Created by Cody Dillon on 2/22/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import Foundation
import HorizonCalendar

protocol CalendarViewDelegate {
    func calendarViewController(_ controller: CalendarViewController, isDateEnabled date: Date) -> Bool
    func calendarViewController(_ controller: CalendarViewController, didSelectDate date: Date)
}

class CalendarViewController: UIViewController {
    
    var calendar = Calendar.current
    var calendarView: CalendarView!
    var selectedDate: Date?
    var firstDate: Date?
    var lastDate: Date?
    var delegate: CalendarViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarView = CalendarView(initialContent: makeContent())
        
        calendarView.daySelectionHandler = { [weak self] day in
            guard let self = self,
                  let date = self.calendar.date(from: day.components) else { return }
            
            if self.delegate?.calendarViewController(self, isDateEnabled: date) ?? true {
                self.selectedDate = date
                self.calendarView.setContent(self.makeContent())
                self.delegate?.calendarViewController(self, didSelectDate: date)
            }
        }
        
        view.addSubview(calendarView)
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          calendarView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
          calendarView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
          calendarView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
          calendarView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])
        
        if let selectedDate = self.selectedDate {
            calendarView.scroll(toDayContaining: selectedDate, scrollPosition: .centered, animated: false)
        }
    }
    
//    public func scroll(toSelectedDate: Bool) {
//
//    }
    
    private func makeContent() -> CalendarViewContent {
        let startDateComponents = calendar.dateComponents([.month, .year], from: .now)
        let startDate = firstDate ?? calendar.date(from: startDateComponents)!
        let endDate = lastDate ?? calendar.date(byAdding: .month, value: 11, to: startDate)!
        
        return CalendarViewContent(
            calendar: calendar,
            visibleDateRange: startDate...endDate,
            monthsLayout: .vertical(options: VerticalMonthsLayoutOptions(pinDaysOfWeekToTop: true, alwaysShowCompleteBoundaryMonths: true)))
            .dayItemProvider { day in
                var invariantViewProperties = DayView.InvariantViewProperties.baseInteractive
                
                if let date = self.calendar.date(from: day.components) {
                    if self.delegate?.calendarViewController(self, isDateEnabled: date) == false {
                        invariantViewProperties.textColor = UIColor.blackText.withAlphaComponent(0.3)
                    }
                    
                    if let selectedDate = self.selectedDate {
                        if self.calendar.isDate(date, inSameDayAs: selectedDate) {
                            invariantViewProperties.backgroundShapeDrawingConfig.borderColor = .actionBlue
                            invariantViewProperties.backgroundShapeDrawingConfig.fillColor = .actionBlue
                            invariantViewProperties.textColor = .white
                        }
                    }
                }
                
                return CalendarItemModel<DayView>(
                    invariantViewProperties: invariantViewProperties,
                    viewModel: .init(dayText: "\(day.day)",
                                     accessibilityLabel: "\(day.day)",
                                     accessibilityHint: nil))
            }
            .monthHeaderItemProvider { month in
                let monthText = "\(month.year) \(DateFormatter().monthSymbols[month.month - 1])"
                return CalendarItemModel<MonthHeaderView>(invariantViewProperties: MonthHeaderView.InvariantViewProperties.base, viewModel: .init(monthText: monthText, accessibilityLabel: monthText))
            }
    }
}
