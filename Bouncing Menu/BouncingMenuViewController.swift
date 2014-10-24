//
//  BouncingMenuViewController.swift
//  Bouncing Menu
//
//  Created by E. Mozharovsky on 10/18/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

struct EnabledOffstage : RawOptionSetType {
    private var value: UInt = 0
    
    init(_ value: UInt) {
        self.value = value
    }
    
    static func fromMask(raw: UInt) -> EnabledOffstage {
        return self(raw)
    }
    
    static func fromRaw(raw: UInt) -> EnabledOffstage? {
        return self(raw)
    }
    
    func toRaw() -> UInt {
        return value
    }
    
    static var allZeros: EnabledOffstage {
        return self(0)
    }
    
    static func convertFromNilLiteral() -> EnabledOffstage {
        return self(0)
    }
    
    static var ViewOffstage: EnabledOffstage { return self(0b0001) }
    static var TabBarOffstage: EnabledOffstage { return self(0b0010) }
    static var NavigationBarOffstage: EnabledOffstage { return self(0b0100) }
    static var DefaultOffstage: EnabledOffstage { return self(0b0011) }
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

class BouncingMenuViewController: UIViewController, UITableViewDataSource,UITableViewDelegate {
    // Public identifier.
    internal let identifier = "BouncingMenuCell"
    
    private var delegate:BouncingMenuDelegate?
    private var controller:UIViewController?
    private let window = UIApplication.sharedApplication().keyWindow
    
    private var tableView: UITableView?
    
    private var viewOffstage: UIControl?
    private var tabBarOffstage: UIControl?
    private var navigationBarOffstage: UIControl?
    
    private let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
    private var viewFrame: CGRect?
    private let navigationBarFrame: CGRect?
    private let tabBarFrame: CGRect?
    
    private let offstageDefaultAlpha = 0.0 as CGFloat
    private let offstageDefaultBackground: UIColor?
    
    var isOffstagePresenting: Bool = false
    private var enabledOffstage = EnabledOffstage.convertFromNilLiteral()
    
    private var isViewChecked: Bool = false
    private var isTabBarChecked: Bool = false
    private var isNavigationBarChecked: Bool = false
    
    init<T: UIViewController where T: BouncingMenuDelegate>(delegate: T?, enabledOffstage: EnabledOffstage) {
        super.init()
        
        self.delegate = delegate
        self.controller = delegate
        self.enabledOffstage = enabledOffstage
        self.offstageDefaultBackground = self.controller?.view.backgroundColor
        
        if self.doesContainOption(EnabledOffstage.ViewOffstage) {
            if let _controller = self.controller {
                self.viewFrame = self.controller!.view.frame
                
                self.viewOffstage = UIControl(frame: self.viewFrame!)
                self.viewOffstage?.backgroundColor = self.offstageDefaultBackground
                self.viewOffstage?.alpha = self.offstageDefaultAlpha
                self.viewOffstage?.addTarget(self, action: Selector("offstageTouched"), forControlEvents: UIControlEvents.TouchDown)
            }
        }
        
        if self.doesContainOption(EnabledOffstage.TabBarOffstage) {
            if let _tabBar = self.controller!.tabBarController?.tabBar {
                self.tabBarFrame = _tabBar.frame
                self.tabBarOffstage = UIControl(frame: self.tabBarFrame!)
                self.tabBarOffstage?.backgroundColor = self.offstageDefaultBackground
                self.tabBarOffstage?.alpha = self.offstageDefaultAlpha
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
        
        if self.doesContainOption(EnabledOffstage.NavigationBarOffstage) {
            if let _navBar = self.controller!.navigationController?.navigationBar {
                self.navigationBarFrame = _navBar.frame
                self.navigationBarFrame?.origin.y -= self.statusBarFrame.size.height
                self.navigationBarFrame?.size.height += self.statusBarFrame.size.height
                
                self.navigationBarOffstage = UIControl(frame: self.navigationBarFrame!)
                self.navigationBarOffstage?.backgroundColor = self.offstageDefaultBackground
                self.navigationBarOffstage?.alpha = self.offstageDefaultAlpha
                
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
            self.controller?.view.addSubview(self.tableView!)
        }
        
        if self.tabBarOffstage? != nil {
            self.window.addSubview(self.tabBarOffstage!)
        }
        
        if self.navigationBarOffstage? != nil {
            self.window.addSubview(self.navigationBarOffstage!)
        }
        
        if self.isOffstagePresenting == false {
            var tableViewRect = CGRectMake(0, 0, self.tableView!.frame.width, self.tableView!.frame.height)
            
            tableViewRect.origin = CGPointMake(0, self.statusBarFrame.height)
            if let navBarRect = self.controller?.navigationController?.navigationBar.frame {
                tableViewRect.origin = CGPointMake(0, tableViewRect.origin.y + navBarRect.height)
            }
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(duratation)
            self.tableView?.frame = tableViewRect
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
    
    private func doesContainOption(option: EnabledOffstage) -> Bool {
        if option.toRaw() & self.enabledOffstage.toRaw() != 0 && self.isViewChecked == false {
            self.isViewChecked = true
            return true
        }
        
        if option.toRaw() & self.enabledOffstage.toRaw() != 0 && self.isTabBarChecked == false {
            self.isTabBarChecked = true
            return true
        }
        
        if option.toRaw() & self.enabledOffstage.toRaw() != 0 && self.isNavigationBarChecked == false {
            self.isNavigationBarChecked = true
            return true
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