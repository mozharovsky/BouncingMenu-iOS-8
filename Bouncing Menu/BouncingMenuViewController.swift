//
//  BouncingMenuViewController.swift
//  Bouncing Menu
//
//  Created by E. Mozharovsky on 10/18/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

enum EnabledOffstage: Int {
    case kNone = 0
    case kViewOffstage = 1
    case kTabBarOffstage = 2
    case kNavigationBarOffstage = 4
    case kViewAndTabBarOffstage = 8
    case kViewAndNavBarOffstage = 16
    case kNavigationAndTabBarsOffstage = 32
    case kAll = 64
}

enum OptionKey {
    case kViewOffstageKey
    case kTabBarOffstageKey
    case kNavigationBarOffstageKey
}

protocol BouncingMenuDelegate {
    var offstageAlpha: CGFloat { get }
    var offstageBackground: UIColor { get }
    
    
    func offstageTouched()
    
    func numberOfSections(tableView: UITableView) -> Int
    func totalCountOfRows() -> Int
    func numberOfRows(tableView: UITableView, section: Int) -> Int
    func tableViewHeight() -> CGFloat
    func bouncingMenu(tableView: UITableView, cellForRowAtIndexPath: NSIndexPath) -> UITableViewCell
    func rowSelected(tableView: UITableView, indexPath: NSIndexPath)
}

class BouncingMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // Public identifier.
    let identifier = "BouncingMenuCell"
    
    var delegate:BouncingMenuDelegate?
    var controller:UIViewController?
    let window = UIApplication.sharedApplication().keyWindow
    
    var tableView: UITableView?
    
    var viewOffstage: UIControl?
    var tabBarOffstage: UIControl?
    var navigationBarOffstage: UIControl?
    
    let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
    var viewFrame: CGRect?
    let navigationBarFrame: CGRect?
    let tabBarFrame: CGRect?
    
    let offstageDefaultAlpha = 0.0 as CGFloat
    let offstageDefaultBackground: UIColor?
    
    var isOffstagePresenting: Bool = false
    var enabledOffstage: EnabledOffstage = EnabledOffstage.kNone
    
    init<T: UIViewController where T: BouncingMenuDelegate>(delegate: T?, enabledOffstage: EnabledOffstage) {
        super.init()
        
        self.delegate = delegate
        self.controller = delegate
        self.enabledOffstage = enabledOffstage
        self.offstageDefaultBackground = self.controller?.view.backgroundColor
        
        if self.doesContainOption(OptionKey.kViewOffstageKey) {
            if let _controller = self.controller {
                self.viewFrame = self.controller!.view.frame
                
                
                self.viewOffstage = UIControl(frame: self.viewFrame!)
                self.viewOffstage?.addTarget(self, action: Selector("offstageTouched"), forControlEvents: UIControlEvents.TouchDown)
            }
        }

        if self.doesContainOption(OptionKey.kTabBarOffstageKey) {
            if let _tabBar = self.controller!.tabBarController?.tabBar {
                self.tabBarFrame = _tabBar.frame
                self.tabBarOffstage = UIControl(frame: self.tabBarFrame!)
                self.tabBarOffstage?.addTarget(self, action: Selector("offstageTouched"), forControlEvents: UIControlEvents.TouchDown)
                
                if self.viewOffstage? != nil {
                    self.substractView(self.viewOffstage!, deductionView: _tabBar)
                }
            }
        } else {
            if self.viewOffstage? != nil {
                if let _tabBar = self.controller!.tabBarController?.tabBar {
                    self.substractView(self.viewOffstage!, deductionView: _tabBar)
                }
            }
        }

        if self.doesContainOption(OptionKey.kNavigationBarOffstageKey) {
            if let _navBar = self.controller!.navigationController?.navigationBar {
                self.navigationBarFrame = _navBar.frame
                self.navigationBarFrame?.origin.y -= self.statusBarFrame.size.height
                self.navigationBarFrame?.size.height += self.statusBarFrame.size.height
                
                self.navigationBarOffstage = UIControl(frame: self.navigationBarFrame!)
                
                if self.viewOffstage? != nil {
                    self.viewOffstage?.frame = CGRectMake(self.viewOffstage!.frame.origin.x, self.viewOffstage!.frame.origin.y + self.navigationBarFrame!.height, self.viewOffstage!.frame.size.width, self.viewOffstage!.frame.size.height)
                    self.substractView(self.viewOffstage!, deductionView: self.navigationBarOffstage!)
                }
                
                
                self.navigationBarOffstage?.addTarget(self, action: Selector("offstageTouched"), forControlEvents: UIControlEvents.TouchDown)
            }
        } else {
            if self.viewOffstage? != nil {
                if let _navBar = self.controller!.navigationController?.navigationBar {
                    self.substractView(self.viewOffstage!, deductionView: _navBar)
                    let viewOffstageRect = self.viewOffstage?.frame
                    self.viewOffstage!.frame = CGRectMake(viewOffstageRect!.origin.x, viewOffstageRect!.origin.y + _navBar.frame.height, viewOffstageRect!.width, viewOffstageRect!.height)
                    
                    self.viewOffstage?.frame = CGRectMake(self.viewOffstage!.frame.origin.x, self.viewOffstage!.frame.origin.y + self.statusBarFrame.height, self.viewOffstage!.frame.size.width, self.viewOffstage!.frame.size.height)
                    let statusBar = UIView(frame: self.statusBarFrame)
                    self.substractView(self.viewOffstage!, deductionView: statusBar)
                }
            }
        }
        
        self.tableView = self.generatedTableView()
        self.tableView?.frame = CGRectMake(0, -self.tableView!.frame.height, self.tableView!.frame.width, self.tableView!.frame.height)
        self.viewOffstage?.addSubview(self.tableView!)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK:- Offstage appearing and disappearing
    
    func invokeBouncingMenu(duratation: NSTimeInterval) {
        self.setBackgrounds(true)
        
        if self.viewOffstage? != nil {
            self.controller?.view.addSubview(self.viewOffstage!)
        }
        
        if self.tabBarOffstage? != nil {
            self.window.addSubview(self.tabBarOffstage!)
        }
        
        if self.navigationBarOffstage? != nil {
            self.window.addSubview(self.navigationBarOffstage!)
        }
        
        if self.isOffstagePresenting == false {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(duratation)
            self.tableView?.frame = CGRectMake(0, 0, self.tableView!.frame.width, self.tableView!.frame.height)
            self.setAlphas()
            self.setBackgrounds(self.isOffstagePresenting)
            UIView.commitAnimations()
        }
        
        self.isOffstagePresenting = true
    }
    
    // Custom animation.
    func invokeBouncingMenu(duratation: NSTimeInterval, animations:() -> Void, completion: ((Bool) -> Void)?) {
        self.setBackgrounds(true)
        
        if self.isOffstagePresenting == false {
            UIView.beginAnimations(nil, context: nil)
            UIView.animateWithDuration(duratation, animations: animations, completion: completion)
            UIView.commitAnimations()
        }
        
        self.isOffstagePresenting = true
    }
    
    func withdrawBouncingMenu(duratation: NSTimeInterval) {
        self.setBackgrounds(self.isOffstagePresenting)
        
        self.viewOffstage?.backgroundColor = self.delegate!.offstageBackground
        self.tabBarOffstage?.backgroundColor = self.delegate!.offstageBackground
        self.navigationBarOffstage?.backgroundColor = self.delegate!.offstageBackground
        
        if self.isOffstagePresenting {
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(duratation)
            self.tableView?.frame = CGRectMake(0, -self.tableView!.frame.height, self.tableView!.frame.width, self.tableView!.frame.height)
            self.setAlphas()
            self.setBackgrounds(self.isOffstagePresenting)
            UIView.commitAnimations()
        }
        
        self.isOffstagePresenting = false
        //self.removeOffstageViews()
    }
    
    // Custom animation.
    func withdrawBouncingMenu(duratation: NSTimeInterval, animations:() -> Void, completion: ((Bool) -> Void)?) {
        self.setBackgrounds(self.isOffstagePresenting)
        
        if self.isOffstagePresenting {
            UIView.beginAnimations(nil, context: nil)
            UIView.animateWithDuration(duratation, animations: animations, completion: completion)
            UIView.commitAnimations()
        }
        
        self.isOffstagePresenting = false
    }
    
    // MARK:- Util methods
    
    private func substractView(minuendView: UIView, deductionView: UIView) {
        let minuendRect = minuendView.frame
        let deductionRect = deductionView.frame
        minuendView.frame = CGRectMake(minuendRect.origin.x, minuendRect.origin.y, minuendRect.width, minuendRect.height - deductionRect.height)
    }
    
    private func doesContainOption(key: OptionKey) -> Bool {
        switch key {
        case .kViewOffstageKey:
            if self.enabledOffstage == EnabledOffstage.kViewOffstage || self.enabledOffstage == EnabledOffstage.kViewAndNavBarOffstage || self.enabledOffstage == EnabledOffstage.kViewAndTabBarOffstage || enabledOffstage == EnabledOffstage.kAll {
                return true
            }
            
        case .kTabBarOffstageKey:
            if self.enabledOffstage == EnabledOffstage.kTabBarOffstage || self.enabledOffstage == EnabledOffstage.kViewAndTabBarOffstage || self.enabledOffstage == EnabledOffstage.kNavigationAndTabBarsOffstage || enabledOffstage == EnabledOffstage.kAll {
                return true
            }
            
        case .kNavigationBarOffstageKey:
            if self.enabledOffstage == EnabledOffstage.kNavigationBarOffstage || self.enabledOffstage == EnabledOffstage.kViewAndNavBarOffstage || self.enabledOffstage == EnabledOffstage.kNavigationAndTabBarsOffstage || enabledOffstage == EnabledOffstage.kAll {
                return true
            }
            
        default: println("Default value...")
        }
        
        return false
    }
    
    private func setBackgrounds(state: Bool) {
        if state {
            if self.delegate? != nil {
                self.viewOffstage?.backgroundColor = self.offstageDefaultBackground
                self.tabBarOffstage?.backgroundColor = self.offstageDefaultBackground
                self.navigationBarOffstage?.backgroundColor = self.offstageDefaultBackground
            }
            
        } else {
            if self.delegate? != nil {
                self.viewOffstage?.backgroundColor = self.delegate!.offstageBackground
                self.tabBarOffstage?.backgroundColor = self.delegate!.offstageBackground
                self.navigationBarOffstage?.backgroundColor = self.delegate!.offstageBackground
            }
        }
    }
    
    private func setAlphas() {
        if self.isOffstagePresenting {
            if self.delegate? != nil {
                self.viewOffstage?.alpha = self.offstageDefaultAlpha
                self.tabBarOffstage?.alpha = self.offstageDefaultAlpha
                self.navigationBarOffstage?.alpha = self.offstageDefaultAlpha
            }
        } else {
            if self.delegate? != nil {
                self.viewOffstage?.alpha = self.delegate!.offstageAlpha
                self.tabBarOffstage?.alpha = self.delegate!.offstageAlpha
                self.navigationBarOffstage?.alpha = self.delegate!.offstageAlpha
            }
        }
    }
    
    private func removeOffstageViews() {
        self.viewOffstage?.removeFromSuperview()
        self.tabBarOffstage?.removeFromSuperview()
        self.navigationBarOffstage?.removeFromSuperview()
    }
    
    // MARK:- Offstage control events 
    
    func offstageTouched() {
        self.delegate?.offstageTouched()
    }
    
    // MARK:- Bouncing menu setup 
    
    func generatedTableView() -> UITableView {
        let tableView = UITableView(frame: CGRectMake(0, 0, self.controller!.view.frame.width, self.delegate!.tableViewHeight()), style: UITableViewStyle.Grouped)
        
        tableView.tableHeaderView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, 1))
        tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, 1))
        
        tableView.scrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.identifier)
        
        return tableView
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.delegate!.numberOfSections(tableView)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.delegate!.numberOfRows(tableView, section: section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.delegate!.bouncingMenu(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.height / CGFloat(self.delegate!.totalCountOfRows())
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.rowSelected(tableView, indexPath: indexPath)
    }
}