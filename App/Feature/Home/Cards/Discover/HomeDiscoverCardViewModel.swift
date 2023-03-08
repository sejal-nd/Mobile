//
//  HomeDiscoverCardViewModel.swift
//  EUMobile
//
//  Created by Cody Dillon on 1/3/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftExt
import SwiftUI

class HomeDiscoverCardViewModel {

    let disposeBag = DisposeBag()

    let accountDetailEvents: Observable<Event<AccountDetail>>

    required init(accountDetailEvents: Observable<Event<AccountDetail>>) {
        self.accountDetailEvents = accountDetailEvents
    }

    private(set) lazy var isCustomerHelp: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            return Configuration.shared.opco == .peco && accountDetail.isResidential
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var helpUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            if Configuration.shared.opco == .peco && accountDetail.isResidential {
                return "https://www.peco.com/Help"
            }

            return nil
        }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isAssistance: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            return Configuration.shared.opco == .bge && accountDetail.isResidential
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var assistanceUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            if Configuration.shared.opco == .bge && accountDetail.isResidential {
                return "https://\(Configuration.shared.associatedDomain)/assistance/landing"
            }

            return nil
        }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isHourlyPricing: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            if Configuration.shared.opco == .comEd && accountDetail.isResidential {
                return accountDetail.isHourlyPricing
            }

            return false
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var hourlyPricingUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            if Configuration.shared.opco == .comEd && accountDetail.isResidential && accountDetail.isHourlyPricing {
                return String(format: "https://hourlypricing.comed.com/rrtpmobile/servlet?type=home&account=%@", accountDetail.accountNumber)
            }

            return nil
        }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isEnergySavings: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            return Configuration.shared.opco == .comEd && accountDetail.isResidential
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var energySavingsUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            if Configuration.shared.opco == .comEd && accountDetail.isResidential {
                return "https://secure.comed.com/marketplace/?utm_source=ComEd+mobile&utm_medium=referral&utm_campaign=mobile+app"
            }

            return nil
        }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isPeakRewards: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            if Configuration.shared.opco == .bge && accountDetail.isResidential {
                return accountDetail.peakRewards == "ACTIVE" || accountDetail.peakRewards == "ECOBEE WIFI"
            }

            return false
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isEnergyWiseRewardsEnrolled: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            if Configuration.shared.opco.isPHI && accountDetail.isResidential {
                return accountDetail.isEnergyWiseRewardsEnrolled
            }

            return false
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isEnergyWiseRewardsOffer: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            if Configuration.shared.opco.isPHI && accountDetail.isResidential {
                return !accountDetail.isEnergyWiseRewardsEnrolled
            }

            return false
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isCommercial: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            return !accountDetail.isResidential
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var commercialUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Configuration.shared.opco {
            case .peco:
                return "https://www.peco.com/smartideas"
            case .bge:
                return "https://\(Configuration.shared.associatedDomain)/assistance/landing"
            case .comEd:
                return "http://comed.com/BusinessSavings"
            case .ace, .delmarva, .pepco:
                /// The logic behind checking from utility code is one account can be tagged to ACE, DPL & PEPCO, so in order to keep it dynamic we had to look for the utility code rather that the selected opco

                if accountDetail.opcoType == .ace {
                    return "https://www.atlanticcityelectric.com/WaysToSave/ForYourBusiness/Pages/default.aspx"
                } else if accountDetail.opcoType == .delmarva {
                    if accountDetail.subOpco == .delmarvaMaryland {
                        return "https://www.delmarva.com/WaysToSave/ForYourBusiness/Pages/Maryland.aspx"
                    } else if accountDetail.subOpco == .delmarvaDelaware {
                        return "https://www.delmarva.com/WaysToSave/ForYourBusiness/Pages/Delaware.aspx"
                    } else {
                        return ""
                    }
                } else if accountDetail.opcoType == .pepco {
                    if accountDetail.subOpco == .pepcoDC {
                        return "https://www.pepco.com/WaysToSave/ForYourBusiness/Pages/DC/DistrictOfColumbia.aspx"
                    } else if accountDetail.subOpco == .pepcoMaryland {
                        return "https://www.pepco.com/WaysToSave/ForYourBusiness/Pages/Maryland.aspx"
                    } else {
                        return ""
                    }
                } else {
                    return ""
                }
            }
    }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isSignUpForAlerts: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            if accountDetail.isResidential {
                return true
            }

            return false
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var isHomeEnergyCheckup: Driver<Bool> = self.accountDetailEvents.elements()
        .map { accountDetail -> Bool in
            if accountDetail.isResidential {
                return true
            }

            return false
        }
        .asDriver(onErrorDriveWith: .empty())

    private(set) lazy var homeEnergyCheckupUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            let opco = accountDetail.opcoType ?? Configuration.shared.opco
            switch opco {
            case .bge:
                return "https://bgesmartenergy.com/residential/help-me-save/home-performance"
            case .comEd:
                return "https://www.comed.com/WaysToSave/ForYourHome/Pages/SingleFamily.aspx"
            case .peco:
                return "https://www.peco.com/WaysToSave/ForYourHome/Pages/EnergyAssessment.aspx"
            case .pepco:
                return "https://homeenergysavings.pepco.com/md/residential/quick-home-energy-check-up-program"
            case .ace:
                return "https://homeenergysavings.atlanticcityelectric.com/residential/energy-assessments/quick-home-energy-check-up-program"
            case .delmarva:
                return "https://homeenergysavings.delmarva.com/md/residential/quick-home-energy-check-up-program"
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

    private(set) lazy var energyWiseRewardsOfferUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            if Configuration.shared.opco.isPHI {
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
            } else {
                return ""
            }
        }
        .unwrap()
        .map { URL(string: $0) }.unwrap()
        .asDriver(onErrorDriveWith: .empty())

    //Set call to action URL to navigate to
    private(set) lazy var ctaUrl: Driver<URL> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Configuration.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return "https://www.peco.com/Help"
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
                        return "https://\(Configuration.shared.associatedDomain)/assistance/landing"
                    }
                } else {
                    return "https://\(Configuration.shared.associatedDomain)/assistance/landing"
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


    //Set title string
    private(set) lazy var titleString: Driver<String?> = self.accountDetailEvents.elements()
        .map { accountDetail -> String? in
            switch Configuration.shared.opco {
            case .peco:
                if accountDetail.isResidential {
                    return NSLocalizedString("PECO is Helping Customers Pay Their Bills  ", comment: "")
                } else {
                    return NSLocalizedString("Reduce Your Business’s Energy Costs", comment: "")
                }
            case .bge:
                if accountDetail.isResidential {
                    switch accountDetail.peakRewards {
                    case "ACTIVE"?, "ECOBEE WIFI"?:
                        return NSLocalizedString("PeakRewards Program", comment: "")
                    default:
                        return NSLocalizedString("Looking for Assistance?", comment: "")
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
}
