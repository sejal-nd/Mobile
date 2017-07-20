//
//  TemplateCardViewModel.swift
//  Mobile
//
//  Created by Dan Jorquera on 7/19/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//


import RxSwift
import RxCocoa

class TemplateCardViewModel {
    
    private var imageString = String("")
    private var titleString = String("")
    private var bodyString = String("")
    private var ctaString = String("")
    private var ctaUrl = String("")
    
    required init() {
        if(Environment.sharedInstance.opco == .peco) {
            //if(Commercial) {
            imageString = "Commercial"
            titleString = "Reduce Your Business’s Energy Costs"
            bodyString = "PECO can help you get on the fast track to substantial energy & cost savings. Click or call 1-844-4BIZ-SAVE"
            ctaString = "Get started today"
            ctaUrl = "http://www.peco.com/smartideas"
            
            //if(Residential) {
            imageString = "Residential"
            titleString = "PECO Has Ways to Save"
            bodyString = "Get cash back with PECO rebates on high-efficiency appliances & hvac equipment. Click or call 1-888-5-PECO-SAVE"
            ctaString = "Get started today"
            ctaUrl = "http://www.peco.com/smartideas"
            
        } else if(Environment.sharedInstance.opco == .bge) {
            //if(Commercial) {
            imageString = "smallbusiness"
            titleString = "Lower your Business’s energy costs"
            bodyString = "Save with financial incentives and energy efficiency upgrades."
            ctaString = "Learn More"
            ctaUrl = "http://bgesmartenergy.com/business"
            
            //if(Residential) {
            //switch Account Details API peakRewards
            //case HONEYWELL WIFI (legacy)
            imageString = "PeakRewards Legacy Tstat - shutterstock_541239523"
            titleString = "Stay Connected"
            bodyString = "Update your contact info to receive email and text alerts related to cycling and Energy Savings Days."
            ctaString = "Update Your Info"
            ctaUrl = "https://secure.bge.com/Peakrewards/Pages/default.aspx"
            
            //case ECOBEE WIFI
            imageString = "PeakRewards WiFi TStat - Ecobee3lite"
            titleString = "Enjoy year-round savings and stay connected"
            bodyString = "Save energy all year round. Adjust your thermostat from the palm of your hand."
            ctaString = "Adjust Your Settings"
            ctaUrl = "https://www.ecobee.com/home/ecobeeLogin.jsp"
            
            //default (ACTIVE = FALSE (not enrolled in PeakRewards))
            imageString = "General Residential Not enrolled in PeakRewards - shutterstock_461845090"
            titleString = "BGE Bill Credits with PeakRewards"
            bodyString = "Join PeakRewards and get a smart thermostat or outdoor switch and $100 to $200 in bill credits from Jun—Sept."
            ctaString = "Enroll Now"
            ctaUrl = "https://bgesavings.com/enroll"
        }
    }
    
    func getImageString() -> String {
        return imageString!
    }
    
    func getTitleString() -> String {
        return titleString!
    }
    
    func getBodyString() -> String {
        return bodyString!
    }
    
    func getCallToActionString() -> String {
        return ctaString!
    }
    
    func getCallToActionURL() -> String {
        return ctaUrl!
    }
}
