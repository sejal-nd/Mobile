//
//  ETAViewModel.swift
//  EUMobile
//
//  Created by Gina Mullins on 1/27/22.
//  Copyright © 2022 Exelon Corporation. All rights reserved.
//

import UIKit

class ETAViewModel {
    
    var etaDetail: String {
        return NSLocalizedString("The current estimate is based on outage restoration history. ETRs are updated as new information becomes available.", comment: "")
    }
    var etaDetailUnavailable: String {
        return NSLocalizedString("BGE team members are actively working to restore power and will provide an updated ETR as soon as new information becomes available.", comment: "")
    }
    var etaOnSiteDetail: String {
        return NSLocalizedString("The current ETR is up-to-date based on the latest reports from the repair crew. ETRs are updated as new information becomes available.", comment: "")
    }
    var etaDetailFeeder: String {
        return NSLocalizedString("We expect the vast majority of customers in your area impacted by the storm to be restored at this time. We are working to establish an ETR specific to your outage.", comment: "")
    }
    var etaDetailGlobal: String {
        return NSLocalizedString("We expect the vast majority of customers impacted by the storm to be restored by this time. We are working to establish an ETR specific to your outage.", comment: "")
    }
    var etaDetailOverrideOn: String {
        return NSLocalizedString("BGE team members are actively working to restore power outages resulting from stormy weather conditions and will provide an ETR as quickly as possible.", comment: "")
    }
    
    let causeText: Dictionary = [
        "WildFire": "This outage was caused by wildlife.",
        "Contamination": "This outage was caused by equipment damage.",
        "ContaminationNonUtility": "This outage was caused by a non-utility equipment problem.",
        "ContaminationUnderGround": "This outage was caused by underground equipment damage.",
        "Fires": "This outage was caused by a fire.",
        "Flooding": "This outage was caused by flooding.",
        "Ice/Snow": "This outage was caused by severe weather.",
        "Lightining": "This outage was caused by a lightning strike.",
        "SecondaryFailed": "This outage was caused by damaged power lines.",
        "No Outage": "",
        "Plnd/Schd-Customer Not Notified": "This outage was caused by system maintenance.",
        "Tree-Off ROW-Natural Growth": "This outage was caused by a downed tree or tree limb.",
        "Vehicle-Other Damage": "This outage was caused by a vehicle accident.",
        "Tree-On ROW-Whole": "Tree-Public Interference",
        "Vehicle-Pole Damage": "A vehicle accident interfered with equipment likely causing an outage"
    ]
    
    let causes: Dictionary = [
        "Animal": "WildFire",
        "Osprey": "WildFire",
        "Customer Subst. Activity/Equip.": "ContaminationNonUtility",
        "Dig In - Company/Co. Contractor": "ContaminationUnderGround",
        "Dig In - Non-Company": "ContaminationUnderGround",
        "Dig In - Unknown": "ContaminationUnderGround",
        "Deterioration/Corrosion": "Contamination",
        "Contamination": "Contamination",
        "Equipment Failure": "Contamination",
        "Erosion": "Contamination",
        "Improper Construct/Install": "Contamination",
        "Loose Connection": "Contamination",
        "Public Interference non-Tree/Dig": "Contamination",
        "Slack Conductors": "Contamination",
        "Fires": "Fires",
        "Flooding": "Flooding",
        "Lightning": "Lightining",
        "Foreign Objects-Blown by Wind": "Ice/Snow",
        "Ice/Snow": "Ice/Snow",
        "Wind/Rain": "Ice/Snow",
        "Secondary Failed Into Primary": "SecondaryFailed",
        "No Outage": "No Outage",
        "None": "No Outage",
        "Operating Errors": "No Outage",
        "Other": "No Outage",
        "Overload": "No Outage",
        "Tree-Not Confirmed": "No Outage",
        "Unknown": "No Outage",
        "Vandalism": "No Outage",
        "Plnd/Schd-Customer Not Notified": "Plnd/Schd-Customer Not Notified",
        "Plnd/Schd-Customer Notified": "Plnd/Schd-Customer Not Notified",
        "Tree-Off ROW-Natural Growth": "Tree-Off ROW-Natural Growth",
        "Tree-Off ROW-Portion": "Tree-Off ROW-Natural Growth",
        "Tree-Off ROW-Whole": "Tree-Off ROW-Natural Growth",
        "Tree-On ROW-Natural Growth": "Tree-Off ROW-Natural Growth",
        "Tree-On ROW-Portion": "Tree-Off ROW-Natural Growth",
        "Tree-Public Interference": "Tree-Off ROW-Natural Growth",
        "Tree-Vine": "Tree-Off ROW-Natural Growth",
        "Tree-On ROW-Whole": "Tree-Off ROW-Natural Growth",
        "Vehicle-Other Damage": "Vehicle-Other Damage",
        "Vehicle-Pole Damage": "Vehicle-Other Damage"
    ]

}
