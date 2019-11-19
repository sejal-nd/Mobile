//
//  GameCoreDataManager.swift
//  Mobile
//
//  Created by Marc Shilling on 11/19/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import CoreData

struct GameCoreDataManager {
        
    func addCollectedCoin(accountNumber: String, date: Date, gas: Bool) -> NSManagedObject? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let dayEntity = NSEntityDescription.entity(forEntityName: "CollectedCoin", in: managedContext)!
        let collectedCoin = NSManagedObject(entity: dayEntity, insertInto: managedContext)
        collectedCoin.setValue(accountNumber, forKey: "accountNumber")
        collectedCoin.setValue(date, forKey: "date")
        collectedCoin.setValue(gas, forKey: "gas")
        
        do {
            try managedContext.save()
            return collectedCoin
        } catch let error as NSError {
            print("Could not save collected coin. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func getCollectedCoin(accountNumber: String, date: Date, gas: Bool) -> NSManagedObject? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CollectedCoin")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@ AND date = %@ AND gas = %@", accountNumber, date as NSDate, gas as NSNumber)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if let collectedCoin = result.first as? NSManagedObject {
                return collectedCoin
            } else {
                return nil
            }
        } catch let error as NSError {
            print("Could not get collected coin. \(error), \(error.userInfo)")
            return nil
        }
    }
    
}

