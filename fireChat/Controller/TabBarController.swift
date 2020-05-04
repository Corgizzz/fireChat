//
//  TabBarController.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/4/6.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit

class TabBarController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let a = ChannelVC()
        a.tabBarItem.title = "asd"
        let b = LoginVC()
        b.tabBarItem.title = "zxc"
        let c = ChatViewController()
        c.tabBarItem.title = "bbb"
        let tabBar = UITabBarController()
        tabBar.viewControllers = [a,b,c]
        tabBar.selectedIndex = 0
    }
    


}
