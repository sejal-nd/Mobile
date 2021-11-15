//
//  USState.swift
//  Mobile
//
//  Created by RAMAITHANI on 23/09/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import Foundation

enum USState: String, CaseIterable {

    case NONE = "None", AL = "Alabama", AK = "Alaska", AZ = "Arizona", AR = "Arkansas", CA = "California", CO = "Colorado", CT = "Connecticut", DE = "Delaware", DC = "District of Columbia", FL = "Florida", GA = "Georgia", HI = "Hawaii", ID = "Idaho", IL = "Illinois", IN = "Indiana", IA = "Iowa", KS = "Kansas", KY = "Kentucky", LA = "Louisiana", ME = "Maine", MD = "Maryland", MA = "Massachusetts", MI = "Michigan", MN = "Minnesota", MS = "Mississippi", MO = "Missouri", MT = "Montana", NE = "Nebraska", NV = "Nevada", NH = "New Hampshire", NJ = "New Jersey", NM = "New Mexico", NY = "New York", NC = "North Carolina", ND = "North Dakota", OH = "Ohio", OK = "Oklahoma", OR = "Oregon", PA = "Pennsylvania", RI = "Rhode Island", SC = "South Carolina", SD = "South Dakota", TN = "Tennessee", TX = "Texas", UT = "Utah", VT = "Vermont", VA = "Virginia", WA = "Washington", WV = "West Virginia", WI = "Wisconsin", WY = "Wyoming"

    static var allCases: [USState] {
        return [.NONE, .AL, .AK, .AZ, .AR, .CA, .CO, .CT, .DE, .DC, .FL, .GA, .HI, .ID, .IL, .IN, .IA, .KS, .KY, .LA, .ME, .MD, .MA, .MI, .MN, .MS, .MO, .MT, .NE, .NV, .NH, .NJ, .NM, .NY, .NC, .ND, .OH, .OK, .OR, .PA, .RI, .SC, .SD, .TN, .TX, .UT, .VT, .VA, .WA, .WV, .WI, .WY]
    }
    
    static func getState(state: String)-> String? {
        
        if let _state = USState(rawValue: state) {
            return "\(_state)"
        }
        return nil
    }
    
    static func isUSState(_ string: String)-> Bool {
    
        for state in allCases {
            if "\(state)".lowercased() == string.lowercased() {
                return true
            }
        }
        return false
    }
}
