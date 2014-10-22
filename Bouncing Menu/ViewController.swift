//
//  ViewController.swift
//  Bouncing Menu
//
//  Created by E. Mozharovsky on 10/18/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BouncingMenuDelegate {
    var bouncingMenuController: BouncingMenuViewController?
    var offstageAlpha = 0.6 as CGFloat
    var offstageBackground = UIColor.blackColor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        self.bouncingMenuController = BouncingMenuViewController(delegate: self, enabledOffstage: EnabledOffstage.kDefaultOffstage.toRaw())
    }
    
    @IBAction func tapped() {
        if self.bouncingMenuController?.isOffstagePresenting == false {
            self.bouncingMenuController?.invokeBouncingMenu(0.5)
        } else {
            self.bouncingMenuController?.withdrawBouncingMenu(0.5)
        }
    }
    
    // MARK:- Bouncing menu delegate
    
    func offstageTouched() {
        self.bouncingMenuController?.withdrawBouncingMenu(0.5)
    }
    
    func numberOfSections(tableView: UITableView) -> Int {
        return 1
    }
    
    func totalCountOfRows() -> Int {
        return 3
    }
    
    func numberOfRows(tableView: UITableView, section: Int) -> Int {
        return 3
    }
    
    func tableViewHeight() -> CGFloat {
        return 150
    }
    
    func bouncingMenu(tableView: UITableView, cellForRowAtIndexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.bouncingMenuController!.identifier) as UITableViewCell
        
        cell.textLabel?.text = "Menu Item #\(cellForRowAtIndexPath.row)"
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    
    func rowSelected(tableView: UITableView, indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.bouncingMenuController?.withdrawBouncingMenu(0.5)
    }
}