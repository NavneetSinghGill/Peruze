/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A convenient extension to UIKit.UIUserNotificationSettings.
*/

#if os(iOS)

import UIKit

extension UIUserNotificationSettings {
    /// Check to see if one Settings object is a superset of another Settings object.
    func contains(settings: UIUserNotificationSettings) -> Bool {
        // our types must contain all of the other types
      //Swift 2.0
//        if !types.contains(settings.types) {
//            return false
//        }
      if types != settings.types {
        return false
      }
      
        let otherCategories = settings.categories ?? []
        let myCategories = categories ?? []
        
        return myCategories.isSupersetOf(otherCategories)
    }
    
    /**
        Merge two Settings objects together. `UIUserNotificationCategories` with 
        the same identifier are considered equal.
    */
    func settingsByMerging(settings: UIUserNotificationSettings) -> UIUserNotificationSettings {
      //Swift 2.0
      //let mergedTypes = types.union(settings.types)
        let mergedTypes = types | settings.types
      
        let myCategories = categories ?? []
        var existingCategoriesByIdentifier = Dictionary(sequence: myCategories as! Set<UIUserNotificationCategory>) { $0.identifier }
        
        let newCategories = settings.categories ?? []
        let newCategoriesByIdentifier = Dictionary(sequence: newCategories as! Set<UIUserNotificationCategory>) { $0.identifier }
        
        for (newIdentifier, newCategory) in newCategoriesByIdentifier {
            existingCategoriesByIdentifier[newIdentifier] = newCategory
        }
        
        let mergedCategories = Set(existingCategoriesByIdentifier.values)
        return UIUserNotificationSettings(forTypes: mergedTypes, categories: mergedCategories)
    }
}

#endif
