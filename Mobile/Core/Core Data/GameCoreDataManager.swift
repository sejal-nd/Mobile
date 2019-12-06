//
//  GameCoreDataManager.swift
//  Mobile
//
//  Created by Marc Shilling on 11/19/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import CoreData

struct GameCoreDataManager {
        
    // MARK: - Track Collected Coins
    
    func addCollectedCoin(accountNumber: String, date: Date, gas: Bool) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let dayEntity = NSEntityDescription.entity(forEntityName: "CollectedCoin", in: managedContext)!
        let collectedCoin = NSManagedObject(entity: dayEntity, insertInto: managedContext)
        collectedCoin.setValue(accountNumber, forKey: "accountNumber")
        collectedCoin.setValue(date, forKey: "date")
        collectedCoin.setValue(gas, forKey: "gas")
        
        do {
            try managedContext.save()
            dLog("Added collected coin for \(date) to Core Data")
        } catch let error as NSError {
            dLog("Could not save collected coin. \(error), \(error.userInfo)")
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
            dLog("Could not get collected coin. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    // MARK: - Track Viewed Weekly Insights
    
    // Note: the date we store is the end date for the most recent week, so if the insight is
    // comparing the week of 11/24 - 11/30 to the week of 11/17 - 11/12, we store 11/30.
    func addWeeklyInsight(accountNumber: String, endDate: Date) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "ViewedWeeklyInsight", in: managedContext)!
        let viewedWeeklyInsight = NSManagedObject(entity: entity, insertInto: managedContext)
        viewedWeeklyInsight.setValue(accountNumber, forKey: "accountNumber")
        viewedWeeklyInsight.setValue(endDate, forKey: "endDate")
        
        do {
            try managedContext.save()
            dLog("Added weekly insight for \(endDate) to Core Data")
        } catch let error as NSError {
            dLog("Could not save weekly insight. \(error), \(error.userInfo)")
        }
    }
    
    func getWeeklyInsight(accountNumber: String, endDate: Date) -> NSManagedObject? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ViewedWeeklyInsight")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@ AND endDate = %@", accountNumber, endDate as NSDate)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if let viewedWeeklyInsight = result.first as? NSManagedObject {
                return viewedWeeklyInsight
            } else {
                return nil
            }
        } catch let error as NSError {
            dLog("Could not get weekly insight. \(error), \(error.userInfo)")
            return nil
        }
    }
    
}

