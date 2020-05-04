//
//  ChannelVC.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/1/7.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit
import Firebase
import Photos
class ChannelVC: BaseViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var channelTableView: UITableView!
    @IBOutlet weak var channelTF: UITextField!
    var senderDisplayName: String? // 1
    var newChannelTextField: UITextField? // 2
    private var channels: [Channel] = [] // 3
    var channelRef: DatabaseReference = Database.database().reference().child("channels")
    var channelRefHandle: DatabaseHandle?
    override func viewDidLoad() {
        super.viewDidLoad()
        channelTableView.delegate = self
        channelTableView.dataSource = self
        observeChannels()
        self.navigationItem.setHidesBackButton(true, animated: true)
        channelTableView.register(ChannelTableViewCell.loadFromNib(), forCellReuseIdentifier: "ChannelTableViewCell")
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
    }
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelTableViewCell", for: indexPath) as! ChannelTableViewCell
        cell.channelLab.text = channels[indexPath.row].name
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = channels[(indexPath as NSIndexPath).row]
        Messaging.messaging().subscribe(toTopic: channel.name!) { error in
            print("Subscribed to \(channel.name!) topic")
        }
        let vc = ChatViewController()
        vc.senderDisplayName = channels[indexPath.row].name
        vc.channel = channel
        vc.channelRef = channelRef.child(channel.id!)
        print(channel.name!)
        pushViewController(vc: vc)
    }
    @IBAction func addChannel(_ sender: Any) {
        let name = channelTF.text!
        let newChannelRef = channelRef.child("\(name)") // 2
        let channelItem = [ // 3
            "name": name,
            "newSender":"",
            "newMsg":""
        ]
        newChannelRef.setValue(channelItem) // 4
        print(newChannelRef)
    }
    private func observeChannels() {
        // 觀察資料庫
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) -> Void in // 1
            let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
//            let channelData2 = snapshot.value as? [String : AnyObject] ?? [:] // 2
//            print("channelData:\(channelData)")
            let id = snapshot.key
            if let name = channelData["name"] as! String? { // 3
//                self.channels.append(Channel(id: id, name: name, text: "123"))
                self.channelTableView.reloadData()
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
}

extension UIView{
    class func loadFromNib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
}
