//
//  HomeCardPrefsStore.swift
//  Mobile
//
//  Created by Samuel Francis on 6/19/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift

enum HomeCard: Int {
    case bill, usage, template, projectedBill, outageStatus, peakRewards
    
    static let allCases: [HomeCard] = [.bill, .usage, .template, .projectedBill, .outageStatus, .peakRewards]
    
    init?(id: String) {
        guard let homeCard = HomeCard.allCases.first(where: { $0.id == id }) else {
            return nil
        }
        self = homeCard
    }
    
    var displayString: String {
        switch self {
        case .bill:
            return NSLocalizedString("Bill", comment: "")
        case .usage:
            return NSLocalizedString("Usage", comment: "")
        case .template:
            return NSLocalizedString("Tools and Programs", comment: "")
        case .projectedBill:
            return NSLocalizedString("Projected Bill", comment: "")
        case .outageStatus:
            return NSLocalizedString("Outage Status", comment: "")
        case .peakRewards:
            return NSLocalizedString("PeakRewards", comment: "")
        }
    }
    
    var id: String {
        switch self {
        case .bill:
            return "bill"
        case .usage:
            return "usage"
        case .template:
            return "template"
        case .projectedBill:
            return "projectedBill"
        case .outageStatus:
            return "outageStatus"
        case .peakRewards:
            return "peakRewards"
        }
    }
    
    var isOptional: Bool {
        switch self {
        case .bill, .usage:
            return false
        default:
            return true
        }
    }
    
    var isAlwaysAvailable: Bool {
        switch self {
        case .usage, .projectedBill, .peakRewards:
            return false
        default:
            return true
        }
    }
}

final class HomeCardPrefsStore {
    static let shared = HomeCardPrefsStore()
    
    private let listCache: Variable<[HomeCard]>
    
    let listObservable: Observable<[HomeCard]>
    
    var list: [HomeCard] {
        get {
            return listCache.value
        }
        set(newValue) {
            listCache.value = newValue
            let stringValues = newValue.map { $0.displayString }
            UserDefaults.standard.set(stringValues, forKey: UserDefaultKeys.homeCardPrefsList)
        }
    }
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        let defaultList: [HomeCard] = [.bill, .usage, .template]
        let storedStringList = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.homeCardPrefsList)
        var storedList = storedStringList?.map { HomeCard(id: $0) }.compactMap { $0 } ?? defaultList
        
        HomeCard.allCases.filter { !$0.isOptional }.forEach {
            if !storedList.contains($0) {
                storedList.append($0)
            }
        }
        
        listCache = Variable(storedList)
        
        listObservable = listCache.asObservable()
        
        let stringValues = storedList.map { $0.id }
        UserDefaults.standard.set(stringValues, forKey: UserDefaultKeys.homeCardPrefsList)
    }
}
