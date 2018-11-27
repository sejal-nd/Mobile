//
//  TestIC.swift
//  PECO_WatchOS Extension
//
//  Created by Joseph Erlandson on 11/27/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import WatchKit

class TestIC: WKInterfaceController {
    
    @IBOutlet var label: WKInterfaceLabel!

    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Set Delegate
        NetworkingUtility.shared.addNetworkUtilityUpdateDelegate(self)
        
    }
    
    
}

// MARK: - Networking Delegate

extension TestIC: NetworkingDelegate {
    
    func newAccountDidUpdate(_ account: Account) {
    }
    
    func currentAccountDidUpdate(_ account: Account) {
        
    }
    
    func accountDetailDidUpdate(_ accountDetail: AccountDetail) { }
    
    func accountListAndAccountDetailsDidUpdate(accounts: [Account], accountDetail: AccountDetail?) { }
    
    func accountListDidUpdate(_ accounts: [Account]) {

    }
    
    func outageStatusDidUpdate(_ outageStatus: OutageStatus) {

    }
    
    func maintenanceMode(feature: MainFeature) {

    }
    
    func loading(feature: MainFeature) {

    }
    
    func error(_ serviceError: ServiceError, feature: MainFeature) {

        label.setText(serviceError.localizedDescription)
    }
    
    func usageStatusDidUpdate(_ billForecast: BillForecastResult) { }
    
}

