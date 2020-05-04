//
//  GeneralCommand.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/4/6.
//  Copyright © 2020 Corgi. All rights reserved.
//

import Foundation
import UIKit
class GeneralBase: NSObject {
    static let shareInstance = GeneralBase()

    func showActivityIndicatory(uiView: UIView) {
        //背景
        let container: UIView = UIView()
        container.tag = 100
        container.frame = UIScreen.main.bounds
        container.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        container.backgroundColor = UIColorFromHex(rgbValue: 0xffffff, alpha: 0.3)
        // loading的背景
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        loadingView.backgroundColor = UIColorFromHex(rgbValue: 0x444444, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        // loading 圖案
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        actInd.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        actInd.style = UIActivityIndicatorView.Style.whiteLarge
        actInd.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        actInd.startAnimating()
    }
    func removeActivityIndicatory(uiView: UIView){
        if let viewWithTag = uiView.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
    }
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
         let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
         let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
         let blue = CGFloat(rgbValue & 0xFF)/256.0
         return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
     }
}
