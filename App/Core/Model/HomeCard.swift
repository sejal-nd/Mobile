//
//  HomeCard.swift
//  Mobile
//
//  Created by Samuel Francis on 6/19/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

enum HomeCard: Int {
    case bill, usage, template, projectedBill, outageStatus, prepaidActive, prepaidPending, nothing
    
    static let editableCards: [HomeCard] = {
        return [.bill, .usage, .template, .outageStatus, .projectedBill]
    }()
    
    init?(id: String) {
        guard let homeCard = HomeCard.editableCards.first(where: { $0.id == id }) else {
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
        case .prepaidActive, .prepaidPending, .nothing:
            return ""
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
        case .prepaidActive:
            return "prepaidActive"
        case .prepaidPending:
            return "prepaidPending"
        case .nothing:
            return "nothing"
        }
    }
    
    var isOptional: Bool {
        switch self {
        case .bill, .template:
            return false
        default:
            return true
        }
    }
    
    var isAlwaysAvailable: Bool {
        switch self {
        case .usage, .projectedBill:
            return false
        default:
            return true
        }
    }
    
    static let latestNewCardVersion: Version = {
        // Update these in versions with new cards
        switch Environment.shared.opco {
        case .bge:
            return Version(major: 1, minor: 2, patch: 5)
        case .peco:
            return Version(major: 1, minor: 2, patch: 5)
        case .comEd:
            return Version(major: 9, minor: 0, patch: 5)
        case .pepco:
            return Version(major: 1, minor: 2, patch: 5)
        case .ace:
            return Version(major: 1, minor: 2, patch: 5)
        case .delmarva:
            return Version(major: 1, minor: 2, patch: 5)
        }
    }()
}

final class HomeCardPrefsStore {
    static let shared = HomeCardPrefsStore()
    
    private let listCache: BehaviorRelay<[HomeCard]>
    
    let listObservable: Observable<[HomeCard]>
    
    var list: [HomeCard] {
        get {
            return listCache.value
        }
        set(newValue) {
            listCache.accept(newValue)
            let stringValues = newValue.map { $0.id }
            UserDefaults.standard.set(stringValues, forKey: UserDefaultKeys.homeCardPrefsList)
        }
    }
    
    static let defaultList: [HomeCard] = [.bill, .usage, .template]
    
    // Private init protects against another instance being accidentally instantiated
    private init() {
        let storedStringList = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.homeCardPrefsList)
        var storedList = storedStringList?
            .map { HomeCard(id: $0) }
            .compactMap { $0 } ?? HomeCardPrefsStore.defaultList
        
        HomeCard.editableCards.filter { !$0.isOptional }.forEach {
            if !storedList.contains($0) {
                storedList.append($0)
            }
        }
        
        listCache = BehaviorRelay(value: storedList)
        
        listObservable = listCache.asObservable()
        
        if storedStringList != nil {
            let stringValues = storedList.map { $0.id }
            UserDefaults.standard.set(stringValues, forKey: UserDefaultKeys.homeCardPrefsList)
        }
    }
}