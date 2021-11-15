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
            switch Configuration.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return #imageLiteral(resourceName: "marketplace")
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
                    return accountDetail.isHourlyPricing ? #imageLiteral(resourceName: "EnrolledImage") :#imageLiteral(resourceName: "marketplace")
                } else {
                    return #imageLiteral(resourceName: "Commercial")
                }
            case .ace, .delmarva, .pepco:
                if accountDetail.opcoType == .ace {
                    return accountDetail.isResidential ? (accountDetail.isEnergyWiseRewardsEnrolled ? #imageLiteral(resourceName: "EnergyWiseRewards-Enrolled") : #imageLiteral(resourceName: "EnergyWiseRewards-Unenrolled")) : #imageLiteral(resourceName:"SmallBusiness")
                } else if accountDetail.opcoType == .delmarva {
                    return accountDetail.isResidential ? (accountDetail.isEnergyWiseRewardsEnrolled ? #imageLiteral(resourceName: "EnergyWiseRewards-Enrolled") : #imageLiteral(resourceName: "Residential-Unenrolled")) : #imageLiteral(resourceName:"SmallBusiness")
                } else {
                    return accountDetail.isResidential ? (accountDetail.isEnergyWiseRewardsEnrolled ? #imageLiteral(resourceName: "EnergyWiseRewards-Enrolled") : #imageLiteral(resourceName: "Residential-Unenrolled")) : #imageLiteral(resourceName:"SmallBusiness")
                }
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set title string
    private(set) lazy var titleString: Driver<String?> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Configuration.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return NSLocalizedString("Explore Energy-Saving Solutions for Your Home", comment: "")
                } else {
                    return NSLocalizedString("Reduce Your Business’s Energy Costs", comment: "")
                }
            case .bge:
                if accountDetail.isResidential {
                    switch accountDetail.peakRewards {
                    case "ACTIVE"?, "ECOBEE WIFI"?:
                        return NSLocalizedString("PeakRewards Program", comment: "")
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
                        NSLocalizedString("Explore Energy-Saving Solutions for Your Home", comment: "")
                } else {
                    return NSLocalizedString("Reduce Your Business’s Energy Costs", comment: "")
                }
            case .ace, .delmarva, .pepco:
                /// The logic behind checking from utility code is one account can be tagged to ACE, DPL & PEPCO, so in order to keep it dynamic we had to look for the utility code rather that the selected opco
                if accountDetail.opcoType == .ace {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return NSLocalizedString("Energy Wise Rewards Program", comment: "")
                        } else {
                            return NSLocalizedString("Atlantic City Electric Has Ways to Save", comment: "")
                        }
                    } else {
                         return NSLocalizedString("Lower your Business’s energy costs", comment: "")
                    }
                    
                } else if accountDetail.opcoType == .delmarva {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return NSLocalizedString("Energy Wise Rewards Program", comment: "")
                        } else {
                            return NSLocalizedString("Delmarva Bill Credits with Energy Wise Rewards", comment: "")
                        }
                    } else {
                        return NSLocalizedString("Lower your Business’s energy costs", comment: "")
                    }
                    
                } else if accountDetail.opcoType == .pepco {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return NSLocalizedString("Energy Wise Rewards Program", comment: "")
                        } else {
                            return NSLocalizedString("Pepco Bill Credits with Energy Wise Rewards", comment: "")
                        }
                    } else {
                        return NSLocalizedString("Lower your Business’s energy costs", comment: "")
                    }
                } else {
                    return ""
                }
            }
    }
        .asDriver(onErrorDriveWith: .empty())
     
    //Set body content string
    private(set) lazy var bodyString: Driver<String?> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Configuration.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return NSLocalizedString("Find valuable information and solutions to help you manage and control your energy usage.", comment: "")
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
                        NSLocalizedString("Find valuable information and solutions to help you manage and control your energy usage.", comment: "")
                } else {
                    return NSLocalizedString("A FREE facility assessment can help you save money and energy", comment: "")
                }
            case .ace, .delmarva, .pepco:
                /// The logic behind checking from utility code is one account can be tagged to ACE, DPL & PEPCO, so in order to keep it dynamic we had to look for the utility code rather that the selected opco
                if accountDetail.opcoType == .ace {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return NSLocalizedString("Manage your Energy Wise Rewards device from the palm of your hand.", comment: "")
                        } else {
                            return NSLocalizedString("Get cash back with Atlantic City Electric rebates on high-efficiency appliances & HVAC equipment.", comment: "")
                        }
                    } else {
                        return NSLocalizedString("Save with financial incentives and energy efficiency upgrades.", comment: "")
                    }
                } else if accountDetail.opcoType == .delmarva {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return NSLocalizedString("Manage your Energy Wise Rewards device from the palm of your hand.", comment: "")
                        } else {
                            return NSLocalizedString("Join Energy Wise Rewards and get a smart thermostat or outdoor switch and $100 to $200 in bill credits from Jun—Sept.", comment: "")
                        }
                    } else {
                        return NSLocalizedString("Save with financial incentives and energy efficiency upgrades.", comment: "")
                    }
                } else if accountDetail.opcoType == .pepco {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return NSLocalizedString("Manage your Energy Wise Rewards device from the palm of your hand.", comment: "")
                        } else {
                            return NSLocalizedString("Join Energy Wise Rewards and get a smart thermostat or outdoor switch and $100 to $200 in bill credits from Jun—Sept.", comment: "")
                        }
                    } else {
                        return NSLocalizedString("Save with financial incentives and energy efficiency upgrades.", comment: "")
                    }
                } else {
                    return ""
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
            switch Configuration.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return NSLocalizedString("Save Now", comment: "")
                } else {
                    return NSLocalizedString("Get started today", comment: "")
                }
                
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
                        NSLocalizedString("Save Now", comment: "")
                } else {
                    return NSLocalizedString("Get started today", comment: "")
                }
            case .ace, .delmarva, .pepco:
                if accountDetail.isEnergyWiseRewardsEnrolled {
                    return NSLocalizedString("Adjust Your Thermostat", comment: "")
                } else {
                    return NSLocalizedString("Learn More", comment: "")
                }
            }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set call to action URL to navigate to
    private(set) lazy var ctaUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Configuration.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return "https://www.peco.com/WaysToSave/ForYourHome/Pages/PECOMarketplace.aspx
"
                } else {
                    return "https://www.peco.com/smartideas"
                }
            case .bge:
                if accountDetail.isResidential, let peakRewards = accountDetail.peakRewards {
                    switch peakRewards {
                    case "ACTIVE":
                        return nil
                    case "ECOBEE WIFI":
                        return nil
                    default:
                        return "https://bgesavings.com/enroll"
                    }
                } else {
                    return "https://bgesmartenergy.com/business"
                }
            case .comEd:
                if accountDetail.isResidential {
                    return accountDetail.isHourlyPricing ?
                        String(format: "https://hourlypricing.comed.com/rrtpmobile/servlet?type=home&account=%@", accountDetail.accountNumber) :
                    "https://secure.comed.com/marketplace/?utm_source=ComEd+mobile&utm_medium=referral&utm_campaign=mobile+app"
                } else {
                    return "http://comed.com/BusinessSavings"
                }
            case .ace, .delmarva, .pepco:
                /// The logic behind checking from utility code is one account can be tagged to ACE, DPL & PEPCO, so in order to keep it dynamic we had to look for the utility code rather that the selected opco
                
                if accountDetail.opcoType == .ace {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return ""
                        } else {
                            return "https://www.atlanticcityelectric.com/WaysToSave/ForYourHome/Pages/default.aspx"
                        }
                    } else {
                        return "https://www.atlanticcityelectric.com/WaysToSave/ForYourBusiness/Pages/default.aspx"
                    }
                } else if accountDetail.opcoType == .delmarva {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return ""
                        } else {
                            return "https://energywiserewards.delmarva.com/"
                        }
                    } else {
                        if accountDetail.subOpco == .delmarvaMaryland {
                            return "https://www.delmarva.com/WaysToSave/ForYourBusiness/Pages/Maryland.aspx"
                        } else if accountDetail.subOpco == .delmarvaDelaware {
                            return "https://www.delmarva.com/WaysToSave/ForYourBusiness/Pages/Delaware.aspx"
                        } else {
                            return ""
                        }
                    }
                } else if accountDetail.opcoType == .pepco {
                    if accountDetail.isResidential {
                        if accountDetail.isEnergyWiseRewardsEnrolled {
                            return "https://www.peco.com/WaysToSave/ForYourHome/Pages/PECOMarketplace.aspx"

                        } else {
                            return "https://energywiserewards.pepco.com/"
                        }
                    } else {
                        if accountDetail.subOpco == .pepcoDC {
                            return "https://www.pepco.com/WaysToSave/ForYourBusiness/Pages/DC/DistrictOfColumbia.aspx"
                        } else if accountDetail.subOpco == .pepcoMaryland {
                            return "https://www.pepco.com/WaysToSave/ForYourBusiness/Pages/Maryland.aspx"
                        } else {
                            return ""
                        }
                    }
                } else {
                    return ""
                }
            }
    }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var linkToEcobee: Driver<Bool> = self.accountDetailEvents.elements().map {
        Configuration.shared.opco == .bge
            && $0.isResidential
            && $0.peakRewards == "ECOBEE WIFI"
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var linkToPeakRewards: Driver<Bool> = self.accountDetailEvents.elements()
        .map {
            Configuration.shared.opco == .bge
                && $0.isResidential
                && $0.peakRewards == "ACTIVE"
        }
        .asDriver(onErrorDriveWith: .empty())
    
    let errorLabelText: String = NSLocalizedString("Unable to retrieve data at this time. Please try again later.", comment: "")
    
    private(set) lazy var isHourlyPricing: Driver<Bool> = self.accountDetailEvents.elements()
        .map { $0.isResidential && $0.isHourlyPricing }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var isEnergyWiseRewardsEnrolled: Driver<Bool> = self.accountDetailEvents.elements()
        .map { $0.isEnergyWiseRewardsEnrolled && Configuration.shared.opco.isPHI }
           .asDriver(onErrorDriveWith: .empty())
}
