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
    
    required init?(accountDetailEvents: Observable<Event<AccountDetail>>) {
        self.accountDetailElements = accountDetailEvents.elements()
        self.accountDetailErrors = accountDetailEvents.errors()
    }
    
    //Set main image for the template
    private(set) lazy var templateImage: Driver<UIImage?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
        case .peco:
            if(accountDetail.isResidential) {
                return "Residential"
            } else {
                return "Commercial"
            }
        case .bge:
            if(accountDetail.isResidential) {
                switch accountDetail.peakRewards {
                case "HONEYWELL WIFI"?: //"legacy" account
                    return "PeakRewards Legacy Tstat - shutterstock_541239523"
                case "ECOBEE WIFI"?:
                    return "PeakRewards WiFi TStat - Ecobee3lite"
                default: //user is not enrolled in PeakRewards
                    return "General Residential Not enrolled in PeakRewards - shutterstock_461845090"
                }
            } else { //Commercial account
                return "smallbusiness"
            }
        case .comEd:
            return nil
        }
        }
        .unwrap()
        .map { UIImage(named: $0) }
        .asDriver(onErrorDriveWith: .empty())

    //Set title string
    private(set) lazy var titleString: Driver<String?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
        case .peco:
            if(accountDetail.isResidential) {
                return NSLocalizedString("PECO Has Ways to Save", comment: "")
            } else {
                return NSLocalizedString("Reduce Your Business’s Energy Costs", comment: "")
            }
        case .bge:
            if(accountDetail.isResidential) {
                switch accountDetail.peakRewards {
                case "HONEYWELL WIFI"?: //"legacy" account
                    return NSLocalizedString("Stay Connected", comment: "")
                case "ECOBEE WIFI"?:
                    return NSLocalizedString("Enjoy year-round savings and stay connected", comment: "")
                default: //user is not enrolled in PeakRewards
                    return NSLocalizedString("BGE Bill Credits with PeakRewards", comment: "")
                }
            } else { //Commercial account
                return NSLocalizedString("Lower your Business’s energy costs", comment: "")
            }
        case .comEd:
            return nil
        }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set body content string
    private(set) lazy var bodyString: Driver<String?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
        case .peco:
            if(accountDetail.isResidential) {
                return NSLocalizedString("Get cash back with PECO rebates on high-efficiency appliances & hvac equipment. Click or call 1-888-5-PECO-SAVE", comment: "")
            } else {
                return NSLocalizedString("PECO can help you get on the fast track to substantial energy & cost savings. Click or call 1-844-4BIZ-SAVE", comment: "")
            }
        case .bge:
            if(accountDetail.isResidential) {
                switch accountDetail.peakRewards {
                case "HONEYWELL WIFI"?: //"legacy" account
                    return NSLocalizedString("Update your contact info to receive email and text alerts related to cycling and Energy Savings Days.", comment: "")
                case "ECOBEE WIFI"?:
                    return NSLocalizedString("Save energy all year round. Adjust your thermostat from the palm of your hand.", comment: "")
                default: //user is not enrolled in PeakRewards
                    return NSLocalizedString("Join PeakRewards and get a smart thermostat or outdoor switch and $100 to $200 in bill credits from Jun—Sept.", comment: "")
                }
            } else { //Commercial account
                return NSLocalizedString("Save with financial incentives and energy efficiency upgrades.", comment: "")
            }
        case .comEd:
            return nil
        }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set call to action string
    private(set) lazy var ctaString: Driver<String?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
        case .peco:
            if(accountDetail.isResidential) {
                return NSLocalizedString("Get started today", comment: "")
            } else {
                return NSLocalizedString("Get started today", comment: "")
            }
        case .bge:
            if(accountDetail.isResidential) {
                switch accountDetail.peakRewards {
                case "HONEYWELL WIFI"?: //"legacy" account
                    return NSLocalizedString("Update Your Info", comment: "")
                case "ECOBEE WIFI"?:
                    return NSLocalizedString("Adjust Your Settings", comment: "")
                default: //user is not enrolled in PeakRewards
                    return NSLocalizedString("Enroll Now", comment: "")
                }
            } else { //Commercial account
                return NSLocalizedString("Learn More", comment: "")
            }
        case .comEd:
            return nil
        }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    //Set call to action URL to navigate to
    private(set) lazy var ctaUrl: Driver<String?> = self.accountDetailElements.map { accountDetail -> String? in
        switch Environment.sharedInstance.opco {
        case .peco:
            if(accountDetail.isResidential) {
                return NSLocalizedString("http://www.peco.com/smartideas", comment: "")
            } else {
                return NSLocalizedString("http://www.peco.com/smartideas", comment: "")
            }
        case .bge:
            if(accountDetail.isResidential) {
                switch accountDetail.peakRewards {
                case "HONEYWELL WIFI"?: //"legacy" account
                    return NSLocalizedString("https://secure.bge.com/Peakrewards/Pages/default.aspx", comment: "")
                case "ECOBEE WIFI"?:
                    return NSLocalizedString("https://www.ecobee.com/home/ecobeeLogin.jsp", comment: "")
                default: //user is not enrolled in PeakRewards
                    return NSLocalizedString("https://bgesavings.com/enroll", comment: "")
                }
            } else { //Commercial account
                return NSLocalizedString("http://bgesmartenergy.com/business", comment: "")
            }
        case .comEd:
            return nil
        }
        }
        .asDriver(onErrorDriveWith: .empty())
    
    private(set) lazy var shouldShowErrorState: Driver<Bool> = Observable.merge(self.accountDetailElements.map { _ in false },
                                                                                self.accountDetailErrors.map { _ -> Bool in true })
        .asDriver(onErrorDriveWith: .empty())
    
    func openWebView() {
        //TODO: Implement web view
        /*
        let urlModal = WebViewController(title: NSLocalizedString("", comment: ""),
                                         url: URL(string:"https://webpayments.billmatrix.com/HTML/terms_conditions_en-us.html")!)
        navigationController?.present(urlModal, animated: true, completion: nil)
         */
    }
}
