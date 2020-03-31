//
//  NewAlertBanner.swift
//  Mobile
//
//  Created by Joseph Erlandson on 3/31/20.
//  Copyright © 2020 Exelon Corporation. All rights reserved.
//

import Foundation

public struct NewAlertBanner: Decodable {
    public var alerts: [NewAlert]
    
    enum CodingKeys: String, CodingKey {
        case data = "d"
        case alerts = "results"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                 forKey: .data)
        self.alerts = try data.decode([NewAlert].self,
                                      forKey: .alerts)
        
//        let rawResponse = try NewAlert(from: data)
//
//
//
//        self.isEbillEligible = try data.decode([NewAlert].self,
//                                               forKey: .isEbillEligible)
//        self.billingInfo = try data.decode(NewBillingInfo.self,
//                                           forKey: .billingInfo)
    }
}

public struct NewAlert: Decodable {
    public var title: String
    public var message: String
    public var isEnabled: Bool
    public var customerType: String
    public var modified: Date
    public var created: Date
    
    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case message = "Message"
        case isEnabled = "Enable"
        case customerType = "CustomerType"
        case modified = "Modified"
        case created = "Created"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try container.decode(String.self,
                                          forKey: .title)
        self.message = try container.decode(String.self,
                                            forKey: .message)
        self.isEnabled = try container.decode(Bool.self,
                                              forKey: .isEnabled)
        self.customerType = try container.decode(String.self,
                                                 forKey: .customerType)
        self.modified = try container.decode(Date.self,
                                             forKey: .modified)
        self.created = try container.decode(Date.self,
                                            forKey: .created)
    }
}


//"d": {
//    "results": [
//    {
//    "__metadata": {
//    "id": "Web/Lists(guid'998437c9-d747-4e19-ab28-219275cdd636')/Items(20)",
//    "uri": "https://azstg.bge.com/_api/Web/Lists(guid'998437c9-d747-4e19-ab28-219275cdd636')/Items(20)",
//    "etag": "\"17\"",
//    "type": "SP.Data.GlobalAlertListItem"
//    },
//    "Title": "URGENT MESSAGE LOOK OUT MAKING THE TITLE VERY LONG SO IT HOPEFULLY STRETCHES TO 3 LINES",
//    "Message": "There will be a planned outage or something soon. Please prepare to not have power. It will totally be gone. Soon. Please make preparations. ",
//    "Enable": true,
//    "CustomerType": "Banner",
//    "Modified": "2018-10-05T18:09:08Z",
//    "Created": "2018-08-22T19:12:52Z"
//    }
//    ]
//}
