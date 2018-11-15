//
//  TemplateCardViewModel.swift
//  Mobile
//
//  Created by Dan Jorquera on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//


import RxSwift
import RxCocoa
import RxSwiftExt

class TemplateCardViewModel {
    
    let accountDetailEvents: Observable<Event<AccountDetail>>
    let showLoadingState: Driver<Void>
    
    required init(accountDetailEvents: Observable<Event<AccountDetail>>, showLoadingState: Driver<Void>) {
        self.accountDetailEvents = accountDetailEvents
        self.showLoadingState = showLoadingState
    }
    
    // MARK: - View States
    
    private(set) lazy var showContentState: Driver<Void> = accountDetailEvents
        .filter { $0.element != nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var showErrorState: Driver<Void> = accountDetailEvents
        .filter { $0.error != nil }
        .mapTo(())
        .asDriver(onErrorDriveWith: .empty())
    
    
    // MARK: - View Content
    
    //Set main image for the template
    private(set) lazy var templateImage: Driver<UIImage?> = self.accountDetailEvents.elements()
        .map { accountDetail -> UIImage? in
            switch Environment.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return #imageLiteral(resourceName: "Residential")
                } else {
                    return #imageLiteral(resourceName: "Commercial")
                }
            case .bge:
                if accountDetail.isResidential {
                    switch accountDetail.peakRewards {
                    case "ACTIVE"?: // "Legacy" account
                        return #imageLiteral(resourceName: "PeakRewards-Legacy")
                    case "ECOBEE WIFI"?:
                        return #imageLiteral(resourceName: "PeakRewards-WiFi-TStat")
                    default: // User is not enrolled in PeakRewards
                        return #imageLiteral(resourceName: "Residential-Unenrolled")
                    }
                } else { // Commercial account
                    return #imageLiteral(resourceName: "SmallBusiness")
                }
            case .comEd:
                if accountDetail.isResidential {
                    return accountDetail.isHourlyPricing ? #imageLiteral(resourceName: "EnrolledImage") : #imageLiteral(resourceName: "UnenrolledImage")
                } else {
                    return #imageLiteral(resourceName: "Commercial")
                }
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set title string
    private(set) lazy var titleString: Driver<String?> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Environment.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return NSLocalizedString("PECO Has Ways to Save", comment: "")
                } else {
                    return NSLocalizedString("Reduce Your Business’s Energy Costs", comment: "")
                }
            case .bge:
                if accountDetail.isResidential {
                    switch accountDetail.peakRewards {
                    case "ACTIVE"?:
                        return NSLocalizedString("PeakRewards Program", comment: "")
                    case "ECOBEE WIFI"?:
                        return NSLocalizedString("Ecobee Thermostat", comment: "")
                    default:
                        return NSLocalizedString("BGE Bill Credits with PeakRewards", comment: "")
                    }
                } else {
                    return NSLocalizedString("Lower your Business’s energy costs", comment: "")
                }
            case .comEd:
                if accountDetail.isResidential {
                    return accountDetail.isHourlyPricing ?
                        NSLocalizedString("Check Up On Your Hourly Pricing Savings", comment: "") :
                        NSLocalizedString("Get Instant Rebates on Energy-Related Products", comment: "")
                } else {
                    return NSLocalizedString("Reduce Your Business’s Energy Costs", comment: "")
                }
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set body content string
    private(set) lazy var bodyString: Driver<String?> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Environment.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return NSLocalizedString("Get cash back with PECO rebates on high-efficiency appliances & HVAC equipment.", comment: "")
                } else {
                    return NSLocalizedString("PECO can help you get on the fast track to substantial energy & cost savings.", comment: "")
                }
            case .bge:
                if accountDetail.isResidential {
                    switch accountDetail.peakRewards {
                    case "ACTIVE"?:
                        return NSLocalizedString("Manage your PeakRewards device from the palm of your hand.", comment: "")
                    case "ECOBEE WIFI"?:
                        return NSLocalizedString("Save energy all year round. Adjust your thermostat from the palm of your hand.", comment: "")
                    default:
                        return NSLocalizedString("Join PeakRewards and get a smart thermostat or outdoor switch and $100 to $200 in bill credits from Jun—Sept.", comment: "")
                    }
                } else {
                    return NSLocalizedString("Save with financial incentives and energy efficiency upgrades.", comment: "")
                }
            case .comEd:
                if accountDetail.isResidential {
                    return accountDetail.isHourlyPricing ?
                        NSLocalizedString("Check Up On Your Hourly Pricing Savings", comment: "") :
                        NSLocalizedString("Shop the ComEd Marketplace and receive instant savings on smart " +
                            "thermostats, energy-efficient LEDs and more.", comment: "")
                } else {
                    return NSLocalizedString("A FREE facility assessment can help you save money and energy", comment: "")
                }
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var bodyStringA11yLabel: Driver<String?> = self.bodyString.map {
        if let bodyString = $0, bodyString.contains("Jun—Sept") {
            return bodyString.replacingOccurrences(of: "Jun—Sept", with: "June to September")
        }
        return $0
    }
    
    //Set call to action string
    private(set) lazy var ctaString: Driver<String?> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Environment.shared.opco {
            case .peco:
                return NSLocalizedString("Get started today", comment: "")
            case .bge:
                if accountDetail.isResidential {
                    switch accountDetail.peakRewards {
                    case "ACTIVE"?:
                        return NSLocalizedString("Manage Your Devices", comment: "")
                    case "ECOBEE WIFI"?:
                        return NSLocalizedString("Manage Your Devices", comment: "")
                    default:
                        return NSLocalizedString("Enroll Now", comment: "")
                    }
                } else {
                    return NSLocalizedString("Learn More", comment: "")
                }
            case .comEd:
                if accountDetail.isResidential {
                    return accountDetail.isHourlyPricing ?
                        NSLocalizedString("View My Savings!", comment: "") :
                        NSLocalizedString("Shop Now", comment: "")
                } else {
                    return NSLocalizedString("Get started today", comment: "")
                }
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set call to action URL to navigate to
    private(set) lazy var ctaUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Environment.shared.opco {
            case .peco:
                return NSLocalizedString("http://www.peco.com/smartideas", comment: "")
            case .bge:
                if accountDetail.isResidential, let peakRewards = accountDetail.peakRewards {
                    switch peakRewards {
                    case "ACTIVE":
                        return nil
                    case "ECOBEE WIFI":
                        return nil
                    default:
                        return NSLocalizedString("https://bgesavings.com/enroll", comment: "")
                    }
                } else {
                    return NSLocalizedString("http://bgesmartenergy.com/business", comment: "")
                }
            case .comEd:
                if accountDetail.isResidential {
                    return accountDetail.isHourlyPricing ?
                        String(format: NSLocalizedString("http://rrtp.comed.com/rrtpmobile/servlet?type=home&account=%@", comment: ""),
                               accountDetail.accountNumber) :
                        NSLocalizedString("https://www.comedmarketplace.com/?utm_source=ComEd+mobile&utm_medium=referral&utm_campaign=mobile+app", comment: "")
                } else {
                    return NSLocalizedString("http://comed.com/BusinessSavings", comment: "")
                }
            }
        }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var linkToEcobee: Driver<Bool> = self.accountDetailEvents.elements().map {
        Environment.shared.opco == .bge
            && $0.isResidential
            && $0.peakRewards == "ECOBEE WIFI"
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var linkToPeakRewards: Driver<Bool> = self.accountDetailEvents.elements()
        .map {
            Environment.shared.opco == .bge
                && $0.isResidential
                && $0.peakRewards == "ACTIVE"
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var errorLabelText: Driver<String?> = self.accountDetailEvents.errors()
        .asDriver(onErrorJustReturn: ServiceError(serviceCode: ""))
        .map {
            if let serviceError = $0 as? ServiceError, serviceError.serviceCode == ServiceErrorCode.fnAccountDisallow.rawValue {
                return NSLocalizedString("This profile type does not have access to the mobile app. Access your account on our responsive website.", comment: "")
            }
            return NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }
    
    private(set) lazy var isHourlyPricing: Driver<Bool> = self.accountDetailEvents.elements()
        .map { $0.isResidential && $0.isHourlyPricing }
        .asDriver(onErrorDriveWith: .empty())
    
}
