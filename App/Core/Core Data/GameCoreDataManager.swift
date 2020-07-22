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
    
    func removeCollectedCoin(accountNumber: String, date: Date, gas: Bool) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CollectedCoin")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@ AND date = %@ AND gas = %@", accountNumber, date as NSDate, gas as NSNumber)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if let collectedCoin = result.first as? NSManagedObject {
                managedContext.delete(collectedCoin)
                try managedContext.save()
            } else {
                dLog("Collected coin for \(date) does not exist in Core Data, so it can't be deleted")
            }
        } catch let error as NSError {
            dLog("Could not delete collected coin for \(date). \(error), \(error.userInfo)")
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
    
    // MARK: - Track Viewed Tips
    
    func addViewedTip(accountNumber: String, tipId: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ViewedTip")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@ AND tipId = %@", accountNumber, tipId)
        let result = try! managedContext.fetch(fetchRequest)
        if result.count == 0 {
            let entity = NSEntityDescription.entity(forEntityName: "ViewedTip", in: managedContext)!
            let viewedTip = NSManagedObject(entity: entity, insertInto: managedContext)
            viewedTip.setValue(accountNumber, forKey: "accountNumber")
            viewedTip.setValue(tipId, forKey: "tipId")
            
            do {
                try managedContext.save()
                dLog("Added viewed tip with ID \(tipId) to Core Data")
            } catch let error as NSError {
                dLog("Could not save viewed tip. \(error), \(error.userInfo)")
            }
        } else {
            dLog("Not saving tip because it already exists in Core Data.")
        }
    }
    
    // Returns an array of tuples (tipId, isFavorited)
    func getViewedTips(accountNumber: String) -> [(String, Bool)] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ViewedTip")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@", accountNumber)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            var tupleArray = [(String, Bool)]()
            for obj in result {
                if let managedObj = obj as? NSManagedObject,
                    let tipId = managedObj.value(forKey: "tipId") as? String,
                    let favorite = managedObj.value(forKey: "favorite") as? Bool {
                    tupleArray.append((tipId, favorite))
                }
            }
            return tupleArray
        } catch let error as NSError {
            dLog("Could not get viewed tip. \(error), \(error.userInfo)")
            return []
        }
    }
    
    func isTipFavorited(accountNumber: String, tipId: String) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ViewedTip")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@ AND tipId = %@", accountNumber, tipId)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if let tip = result.first as? NSManagedObject {
                return tip.value(forKey: "favorite") as? Bool ?? false
            }
        } catch let error as NSError {
            dLog("Could not get viewed tip. \(error), \(error.userInfo)")
        }
        return false
    }
    
    func updateViewedTip(accountNumber: String, tipId: String, isFavorite: Bool) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ViewedTip")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@ AND tipId = %@", accountNumber, tipId)
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if let viewedTip = result.first as? NSManagedObject {
                viewedTip.setValue(isFavorite, forKey: "favorite")
                do {
                    try managedContext.save()
                    dLog("Updated tip with ID \(tipId) in Core Data")
                } catch let error as NSError {
                    dLog("Could not update viewed tip. \(error), \(error.userInfo)")
                }
            }
        } catch let error as NSError {
            dLog("Could not get viewed tip. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Track Viewed Weekly Insights
    
    // Note: the date we store is the end date for the most recent week, so if the insight is
    // comparing the week of 11/24 - 11/30 to the week of 11/17 - 11/12, we store 11/30.
    // Returns false if attempting to add an entry that already exists, true otherwise
    func addWeeklyInsight(accountNumber: String, endDate: Date) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ViewedWeeklyInsight")
        fetchRequest.predicate = NSPredicate(format: "accountNumber = %@ AND endDate = %@", accountNumber, endDate as NSDate)
        let result = try! managedContext.fetch(fetchRequest)
        if result.count == 0 {
            let entity = NSEntityDescription.entity(forEntityName: "ViewedWeeklyInsight", in: managedContext)!
            let viewedWeeklyInsight = NSManagedObject(entity: entity, insertInto: managedContext)
            viewedWeeklyInsight.setValue(accountNumber, forKey: "accountNumber")
            viewedWeeklyInsight.setValue(endDate, forKey: "endDate")
            
            do {
                try managedContext.save()
                dLog("Added weekly insight for \(endDate) to Core Data")
                return true
            } catch let error as NSError {
                dLog("Could not save weekly insight. \(error), \(error.userInfo)")
                return false
            }
        } else {
            dLog("Not saving weekly insight because it already exists in Core Data.")
            return false
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

