//
//  BaseViewController.swift
//  Seknova
//
//  Created by 鈞 on 2019/8/15.
//  Copyright © 2019 鈞. All rights reserved.
//

import UIKit
import Firebase
class BaseViewController: UIViewController {

    public func presentViewController(vc: UIViewController, isFullScreen: Bool = false, completion: (() -> Void)? = nil) {
        //        let nvc = UINavigationController(vc: vc, isFullScreen: isFullScreen)
        let nvc = UINavigationController(rootViewController: vc)
        self.navigationController?.present(nvc, animated: true, completion: completion)
    }
    
    public func pushViewController(vc: UIViewController, animated: Bool = true) {
        vc.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(vc, animated: animated)
    }
    
    public func pushViewController(inStack stack: [UIViewController], vc: UIViewController, animated: Bool = true) {
        var stack = stack
        vc.hidesBottomBarWhenPushed = true
        stack.append(vc)
        self.navigationController?.setViewControllers(stack, animated: animated)
        
        //        self.navigationController?.pushViewController(vc, animated: animated)
    }
    
    public func popViewController(_ animated: Bool = true) {
        self.navigationController?.popViewController(animated: animated)
    }
    
    public func popToRootViewController(_ animated: Bool = true) {
        self.navigationController?.popToRootViewController(animated: animated)
    }
    
    public func dismissViewController(_ animated: Bool = true, completion: (()-> Void)? = nil) {
        self.navigationController?.dismiss(animated: animated, completion: completion)
    }
    
    public func popupViewController(vc: UIViewController,
                                    modalPresentationStyle: UIModalPresentationStyle = .overFullScreen,
                                    modalTransitionStyle: UIModalTransitionStyle = .coverVertical,
                                    animated: Bool = true,
                                    completion: (()-> Void)? = nil) {
        vc.modalPresentationStyle = modalPresentationStyle
        vc.modalTransitionStyle = modalTransitionStyle
        
        self.present(vc, animated: animated, completion: completion)
    }
    
    public func dismissPopupViewController(_ animated: Bool = true, completion: (()-> Void)? = nil) {
        self.dismiss(animated: animated, completion: completion)
    }
    
    public func openBrowser(_ url: URL?) {
        guard let url = url else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
}


