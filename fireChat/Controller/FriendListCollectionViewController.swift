//
//  FriendListCollectionViewController.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/4/7.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
class FriendListCollectionViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout {
    
    private let cellId = "cellId"
    var channelRef: DatabaseReference = Database.database().reference().child("channels")
    var channelRefHandle: DatabaseHandle?
    private var channels: [Channel] = []
    let nowtime = Date()
    let timeFormat = DateFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        observeChannels()
        self.collectionView!.register(FriendCell.self, forCellWithReuseIdentifier: cellId)
        timeFormat.dateFormat = "yyyy年MM月dd日 HH:mm"
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channels.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FriendCell
        cell.nameLabel.text = channels[indexPath.row].name
        cell.messageLabel.text = channels[indexPath.row].text
        cell.profileImageView.sd_setImage(with: channels[indexPath.row].url, completed: nil) // 大頭貼設定
        cell.timeLabel.text = channels[indexPath.row].timeStamp
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 100)
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = channels[(indexPath as NSIndexPath).row]
        Messaging.messaging().subscribe(toTopic: channel.name!) { error in
            print("Subscribed to \(channel.name!) topic")
        }
        let vc = ChatViewController()
        vc.senderDisplayName = channels[indexPath.row].name
        vc.channel = channel
        vc.channelRef = channelRef.child(channel.id!)
        print(channel.name!)
        vc.hidesBottomBarWhenPushed = true
       self.navigationController?.pushViewController(vc, animated: true)
    }
    private func observeChannels() {
        // 觀察資料庫
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) -> Void in // 1
            let channelData = snapshot.value as! Dictionary<String, AnyObject> // 2
            let id = snapshot.key
            let text = channelData["newMsg"] as? String
            let urlStr = channelData["newSender"] as! String
            let url = URL(string: urlStr)
            var timeStamp = channelData["newTimeStamp"] as! String
            timeStamp = self.timeStampAction(msgTime: timeStamp)
            if let name = channelData["name"] as! String? { // 3
                self.channels.append(Channel(id: id, name: name, text:text ?? "", url:url!, timeStamp: timeStamp))
                self.collectionView.reloadData()
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    private func timeStampAction(msgTime:String) -> String{
        let currentTime = timeFormat.string(from: nowtime)
        let time = currentTime.prefix(11)
        if time == msgTime.prefix(11){
            return String(msgTime.suffix(5))
        }else{
            return msgTime.substring(with: 5..<11)
        }
    }
}
class FriendCell: BaseCell {
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        return imageView
    }()

    let dividerLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        return view
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .right
        return label
    }()
    
//    let hasReadImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 10
//        imageView.layer.masksToBounds = true
//        return imageView
//    }()
    
    override func setupViews() {
        
        addSubview(profileImageView)
        addSubview(dividerLineView)
        
        setupContainerView()
        
//        profileImageView.image = UIImage(named: "pain")
//        hasReadImageView.image = UIImage(named: "Banana")
        
        addConstraintsWithFormat(format: "H:|-12-[v0(68)]", views: profileImageView)
        addConstraintsWithFormat(format: "V:[v0(68)]", views: profileImageView)
        
        addConstraint(NSLayoutConstraint(item: profileImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        addConstraintsWithFormat(format: "H:|-82-[v0]|", views: dividerLineView)
        addConstraintsWithFormat(format: "V:[v0(1)]|", views: dividerLineView)
    }
    
    private func setupContainerView() {
        let containerView = UIView()
        addSubview(containerView)
        
        addConstraintsWithFormat(format: "H:|-90-[v0]|", views: containerView)
        addConstraintsWithFormat(format: "V:[v0(50)]", views: containerView)
        addConstraint(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
//        containerView.addSubview(hasReadImageView)
        
        containerView.addConstraintsWithFormat(format: "H:|[v0][v1(80)]-12-|", views: nameLabel, timeLabel)
        
        containerView.addConstraintsWithFormat(format: "V:|[v0][v1(24)]|", views: nameLabel, messageLabel)
        
        containerView.addConstraintsWithFormat(format: "H:|[v0]-8-|", views: messageLabel)
        // hasReadImageView
        
        containerView.addConstraintsWithFormat(format: "V:|[v0(24)]", views: timeLabel)
        
//        containerView.addConstraintsWithFormat(format: "V:[v0(20)]|", views: hasReadImageView)
    }
    
}

extension UIView {
    
    func addConstraintsWithFormat(format: String, views: UIView...) {
        
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated(){
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
}

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        backgroundColor = UIColor.blue
    }
}
extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
