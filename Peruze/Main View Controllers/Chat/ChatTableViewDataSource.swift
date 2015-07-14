//
//  ChatTableViewDataSource.swift
//  Peruse
//
//  Created by Phillip Trent on 6/19/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit

class ChatTableViewDataSource: NSObject, UITableViewDataSource {
    private struct Constants {
        static let ReuseIdentifier = "chat"
        static let NibName = "ChatTableViewCell"
        
    }
    var chats = [Chat]()
    
    
    //MARK: - Lifecycle Methods
    override init() {
        super.init()
        chats = [Chat]()
    }
    
    //MARK: - UITableViewDataSource Methods
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let nib = UINib(nibName: Constants.NibName, bundle: NSBundle.mainBundle())
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.ReuseIdentifier)
        
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifier, forIndexPath: indexPath) as? ChatTableViewCell
        cell!.data = chats[indexPath.item]
        
        return cell!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
