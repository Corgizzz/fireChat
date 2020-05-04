//
//  NetworkController.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/2/17.
//  Copyright © 2020 Corgi. All rights reserved.
//

import Foundation
import UIKit
class NetworkController {
    static let shared = NetworkController()
    
    let imageCache = NSCache<NSURL, UIImage>()
    
    func fetchImage(url: URL, completionHandler: @escaping (UIImage?) -> ()) {
        if let image = imageCache.object(forKey: url as NSURL) {
            completionHandler(image)
            print("暫存檔")
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let image = UIImage(data: data) {
                print("非暫存檔")
                self.imageCache.setObject(image, forKey: url as NSURL)
                completionHandler(image)
            } else {
                completionHandler(nil)
            }
        }.resume()
    }
}
