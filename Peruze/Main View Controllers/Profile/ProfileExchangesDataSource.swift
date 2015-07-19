//
//  ProfileExchangesDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/28/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ProfileExchangesDataSource: NSObject, UITableViewDataSource {
    private struct Constants {
        static let ReuseIdentifier = "ProfileExchange"
        static let NibName = "ProfileExchangesTableViewCell"
    }
    var exchanges = [Exchange]()
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
        
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier,
            forIndexPath: indexPath) as! ProfileExchangesTableViewCell
        //TODO: Format the date label
        cell.profileImageView.image = exchanges[indexPath.row].itemOffered.owner.image
        cell.nameLabel.text = "\(exchanges[indexPath.row].itemOffered.owner.firstName)'s"
        cell.itemLabel.text = "\(exchanges[indexPath.row].itemOffered.title)"
        cell.itemSubtitle.text = "for your \(exchanges[indexPath.row].itemRequested.title)"
        cell.dateLabel.text = "June 24, 2015"
        cell.itemsExchangedImage.itemImages = (exchanges[indexPath.row].itemOffered.image, exchanges[indexPath.row].itemRequested.image)
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exchanges.count
    }
}
