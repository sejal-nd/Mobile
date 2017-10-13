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
    
    private let accountDetailElements: Observable<AccountDetail>
    private let accountDetailErrors: Observable<Error>
    
    required init(accountDetailEvents: Observable<Event<AccountDetail>>) {
        self.accountDetailElements = accountDetailEvents.elements()
        self.accountDetailErrors = accountDetailEvents.errors()
    }
    
    //Set main image for the template
    private(set) lazy var templateImage: Driver<UIImage?> = self.accountDetailElements.map { accountDetail -> UIImage? in
        switch Environment.sharedInstance.opco {
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
                return accountDetail.isHourlyPricing ?
                        #imageLiteral(resourceName: "EnrolledImage") :
                        #imageLiteral(resourceName: "UnenrolledImage")
            } else {
                return #imageLiteral(resourceName: "Commercial")
            }
        }
    }.asDriver(onErrorDriveWith: .empty())
    
    //Set title string
    private(set) lazy var titleString: Driver<String?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
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
                    return NSLocalizedString("Stay Connected", comment: "")
                case "ECOBEE WIFI"?:
                    return NSLocalizedString("Enjoy year-round savings and stay connected", comment: "")
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
    }.asDriver(onErrorDriveWith: .empty())
    
    //Set body content string
    private(set) lazy var bodyString: Driver<String?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
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
                    return NSLocalizedString("Update your contact info to receive email and text alerts related to cycling and Energy Savings Days.", comment: "")
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
    }.asDriver(onErrorDriveWith: .empty())
    
    //Set call to action string
    private(set) lazy var ctaString: Driver<String?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
        case .peco:
            return NSLocalizedString("Get started today", comment: "")
        case .bge:
            if accountDetail.isResidential {
                switch accountDetail.peakRewards {
                case "ACTIVE"?:
                    return NSLocalizedString("Update Your Info", comment: "")
                case "ECOBEE WIFI"?:
                    return NSLocalizedString("Adjust Your Settings", comment: "")
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
    }.asDriver(onErrorDriveWith: .empty())
    
    //Set call to action URL to navigate to
    private(set) lazy var ctaUrl: Driver<URL> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
        case .peco:
            return NSLocalizedString("http://www.peco.com/smartideas", comment: "")
        case .bge:
            if accountDetail.isResidential, let peakRewards = accountDetail.peakRewards {
                switch peakRewards {
                case "ACTIVE":
                    return NSLocalizedString("https://secure.bge.com/Peakrewards/Pages/default.aspx", comment: "")
                case "ECOBEE WIFI":
                    return NSLocalizedString("https://www.ecobee.com/home/ecobeeLogin.jsp", comment: "")
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
                        NSLocalizedString("https://www.comedmarketplace.com/", comment: "")
            } else {
                return NSLocalizedString("http://comed.com/BusinessSavings", comment: "")
            }
        }
    }.unwrap().map { URL(string: $0) }.unwrap().asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowErrorState: Driver<Bool> = Observable.merge(self.accountDetailElements.map { _ in false },
                                                                                self.accountDetailErrors.map { _ -> Bool in true })
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var errorLabelText: Driver<String?> = self.accountDetailErrors.asDriver(onErrorJustReturn: ServiceError(serviceCode: "")).map {
        if let serviceError = $0 as? ServiceError, serviceError.serviceCode == ServiceErrorCode.FnAccountDisallow.rawValue {
            return NSLocalizedString("This profile type does not have access to the mobile app. Access your account on our responsive website.", comment: "")
        }
        return NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    }
    
}
