//
//  HomeAppointmentCardViewModel.swift
//  Mobile
//
//  Created by Sam Francis on 10/10/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

class HomeAppointmentCardViewModel {
    
    let appointments: Observable<[Appointment]>
    
    required init(appointments: Observable<[Appointment]>) {
        self.appointments = appointments
    }
    
    let contactNumber = "1-800-685-0123"
    
    //MARK: - Show/Hide Logic
    
    private(set) lazy var showApologyText: Driver<Bool> = appointments
        .map { appointments -> Bool in
            guard appointments.count == 1 else {
                return false
            }
            
            return appointments[0].status == .canceled
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //MARK: - View Content
    
    private(set) lazy var icon: Driver<UIImage> = appointments
        .map { appointments -> UIImage in
            guard appointments.count == 1 else {
                return #imageLiteral(resourceName: "ic_appt_confirmed")
            }
            
            switch appointments[0].status {
            case .scheduled:
                return #imageLiteral(resourceName: "ic_appt_confirmed")
            case .enRoute:
                return #imageLiteral(resourceName: "ic_appt_otw")
            case .inProgress:
                return #imageLiteral(resourceName: "ic_appt_inprogress")
            case .complete:
                return #imageLiteral(resourceName: "ic_appt_complete")
            case .canceled:
                return #imageLiteral(resourceName: "ic_appt_canceled")
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var topText: Driver<NSAttributedString> = appointments
        .map { [weak self] appointments -> NSAttributedString in
            guard let self = self else { return .init(string: "") }
            
            let standardAttributes: [NSAttributedString.Key: Any] =
                [.font: OpenSans.regular.of(textStyle: .headline),
                 .foregroundColor: UIColor.blackText]
            
            guard appointments.count == 1 else {
                return NSLocalizedString("You have multiple appointments for this account.", comment: "")
                    .attributedString(textAlignment: .center,
                                      otherAttributes: standardAttributes)
            }
            
            let appointment = appointments[0]
            
            switch appointment.status {
            case .scheduled:
                let regularText = NSLocalizedString("Your appointment is scheduled for ", comment: "")
                let boldText = String.localizedStringWithFormat("%@ between %@ - %@.",
                                                                appointment.startTime.dayMonthDayString,
                                                                appointment.startTime.hour_AmPmString,
                                                                appointment.endTime.hour_AmPmString)
                
                let attributedText = NSMutableAttributedString(string: regularText + boldText)
                attributedText.addAttribute(.font, value: OpenSans.regular.of(textStyle: .headline),
                                            range: NSMakeRange(0, regularText.count))
                attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                            range: NSMakeRange(regularText.count, boldText.count))
                attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                            range: NSMakeRange(regularText.count, boldText.count))
                attributedText.addAttribute(.foregroundColor, value: UIColor.blackText,
                                            range: NSMakeRange(0, attributedText.string.count))
                
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                attributedText.addAttribute(.paragraphStyle, value: style,
                                            range: NSMakeRange(0, attributedText.string.count))
                
                return attributedText
            case .enRoute:
                return NSLocalizedString("Your technician is on their way for your appointment today.", comment: "")
                    .attributedString(textAlignment: .center,
                                      otherAttributes: standardAttributes)
            case .inProgress:
                let regularText = NSLocalizedString("Your appointment is in progress. ", comment: "")
                let boldText = String.localizedStringWithFormat("Estimated time of completion is %@.",
                                                                appointment.endTime.hour_AmPmString)
                
                let attributedText = NSMutableAttributedString(string: regularText + boldText)
                attributedText.addAttribute(.font, value: OpenSans.regular.of(textStyle: .headline),
                                            range: NSMakeRange(0, regularText.count))
                attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                            range: NSMakeRange(regularText.count, boldText.count))
                attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .headline),
                                            range: NSMakeRange(regularText.count, boldText.count))
                attributedText.addAttribute(.foregroundColor, value: UIColor.blackText,
                                            range: NSMakeRange(0, attributedText.string.count))
                
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                attributedText.addAttribute(.paragraphStyle, value: style,
                                            range: NSMakeRange(0, attributedText.string.count))
                
                return attributedText
            case .complete:
                let localizedText = String.localizedStringWithFormat("Your appointment is complete. For further assistance, please call %@.", self.contactNumber)
                
                let attributedText = NSMutableAttributedString(string: localizedText)
                attributedText.addAttribute(.foregroundColor, value: UIColor.blackText,
                                            range: NSMakeRange(0, attributedText.string.count))
                attributedText.addAttribute(.font, value: OpenSans.regular.of(textStyle: .headline),
                                            range: NSMakeRange(0, localizedText.count))
                attributedText.addAttribute(.font, value: OpenSans.semibold.of(textStyle: .headline),
                                            range: NSMakeRange(localizedText.count - self.contactNumber.count - 1, self.contactNumber.count))
                
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                attributedText.addAttribute(.paragraphStyle, value: style,
                                            range: NSMakeRange(0, attributedText.string.count))
                
                return attributedText
            case .canceled:
                return NSLocalizedString("Your appointment has been canceled due to inclement weather.", comment: "")
                    .attributedString(textAlignment: .center,
                                      otherAttributes: standardAttributes)
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var bottomButtonText: Driver<String> = appointments
        .map { appointments -> String in
            guard appointments.count == 1 else {
                return NSLocalizedString("View Details", comment: "")
            }
            
            switch appointments[0].status {
            case .scheduled, .inProgress, .enRoute:
                return NSLocalizedString("View Details", comment: "")
            case .complete:
                return NSLocalizedString("Send Feedback", comment: "")
            case .canceled:
                return NSLocalizedString("Contact Us", comment: "")
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    
    
}
