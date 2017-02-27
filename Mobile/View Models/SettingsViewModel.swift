//
//  SettingsViewModel.swift
//  Mobile
//
//  Created by Marc Shilling on 2/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

class SettingsViewModel {
    
    private var fingerprintService: FingerprintService?
    
    init(fingerprintService: FingerprintService) {
        self.fingerprintService = fingerprintService
    }
    
    func isDeviceTouchIDCompatible() -> Bool {
        return fingerprintService!.isDeviceTouchIDCompatible()
    }
    
    func isTouchIDEnabled() -> Bool {
        return fingerprintService!.isTouchIDEnabled()
    }
    
    func disableTouchID() {
        fingerprintService!.disableTouchID()
    }

}
