//
//  MainTabBarController.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/4/6.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit
import Firebase
class MainTabBarController: UIViewController,UITabBarDelegate {
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var myTabBar: UITabBar!
    var channelRef: DatabaseReference = Database.database().reference().child("channels")
    var channelRefHandle: DatabaseHandle?
    let layout = UICollectionViewLayout()
    let vc = [FriendListCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout()),
              OthersViewController()]
    let nowtime = Date()
    let timeFormat = DateFormatter()
    let defaulturl = "https://image.shutterstock.com/image-photo/portrait-surprised-beautifully-cat-on-260nw-1604783341.jpg"
    // 要用UICollectionViewFlowLayout 不能用 UICollectionViewLayout
    override func viewDidLoad() {
        super.viewDidLoad()
        myTabBar.delegate = self
        updateView(0)
        self.myTabBar.items?[0].title = "聊天"
        self.myTabBar.items?[0].image = .add
        self.myTabBar.items?[1].title = "用戶"
        self.myTabBar.items?[1].image = .strokedCheckmark
        timeFormat.dateFormat = "yyyy年MM月dd日 HH:mm"
        self.navigationItem.setHidesBackButton(true, animated: true)
        // Do any additional setup after loading the view.
    }
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0{
            updateView(0)
        }else if item.tag == 1{
            updateView(1)
        }
    }
    private func updateView(_ index: Int) {
        if children.first(where: { String(describing: $0.classForCoder) == String(describing: vc) }) == nil {
            addChild(vc[index])
            container.addSubview(vc[index].view ?? UIView())
            vc[index].view.frame = container.bounds
            self.navigationItem.title = ViewTitle.allCases[index].title
            if index == 0 {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(channelAlertAction))
            }else{
                self.navigationItem.rightBarButtonItem = nil
            }
        } else {
            view.bringSubviewToFront(vc[index].view)
        }
    }
    func addChannel(name:String) {
        let name = name
        let newChannelRef = channelRef.child("\(name)") // 2
        let channelItem = [ // 3
            "name": name,
            "newSender":defaulturl,
            "newMsg":"",
            "newTimeStamp":timeFormat.string(from: nowtime)
            
        ]
        newChannelRef.setValue(channelItem) // 4
    }
    @objc private func channelAlertAction(){
        let controller = UIAlertController(title: "新增頻道", message: nil, preferredStyle: .alert)
        let channelTF = UITextField()
        let okAction = UIAlertAction(title: "新增", style: .default){(true) in
            self.addChannel(name:controller.textFields![0].text!)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .destructive, handler: nil)
        controller.addAction(okAction)
        controller.addAction(cancelAction)
        controller.addTextField { (TF) in
            TF.placeholder = "請輸入頻道名稱"
        }
        present(controller, animated: true, completion: nil)
    }
}
