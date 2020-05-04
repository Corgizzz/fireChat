//
//  ChatViewController.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/1/7.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import Photos
import SDWebImage
class ChatViewController: JSQMessagesViewController {
    var channel: Channel? {
        didSet {
            title = channel?.name
        }
    }
    var channelRef: DatabaseReference?
    var messages = [JSQMessage]()
    var avatars = [String: JSQMessagesAvatarImage]()
    // DataBase中的 "message"
    private lazy var messageRef: DatabaseReference = self.channelRef!.child("messages")
    // 使用DB必須init為 DatabaseHandle 類別
    private var newMessageRefHandle: DatabaseHandle?
    private var updatedMessageRefHandle: DatabaseHandle?
    // 訊息的View
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    private lazy var usersTypingQuery: DatabaseQuery =
        self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    // user本身是否輸入中的路徑
    private lazy var userIsTypingRef: DatabaseReference =
        self.channelRef!.child("typingIndicator").child(self.senderId) // 1
    // 連結Storage
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://firechat-74b64.appspot.com/")
    // image default
    private let imageURLNotSetKey = "NOTSET"
    // 判斷是否為打字中的布林
    private var localTyping = false // 2
    // 放Photo的 Array
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    // 放大頭貼Url的 Array
    private var avatarUrlArray: [String : URL] = [ : ]
    // User的名字
    private var currentUsername = ""
    var userMail :String = ""
    var user = Auth.auth().currentUser
    var ref: DatabaseReference!
    let nowtime = Date()
    let timeFormat = DateFormatter()
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = user?.uid
        self.userMail = user?.email ?? ""
        // 大頭貼的Img大小
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
        // 觀察FireBase中有無新字料 做到即時顯示
        observeMessages()
        // 配合上方的Func 新資料的 User大頭貼
        getAvatarData()
        timeFormat.dateFormat = "yyyy年MM月dd日 HH:mm"
    }
    override func viewDidAppear(_ animated: Bool) {
        finishReceivingMessage()
        // 觀察user是否正在打字
        observeTyping()
    }
    // 文字訊息
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    // 訊息筆數
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    // 訊息上方的Label (顯示UserName)
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        return NSAttributedString(string: "\(message.senderDisplayName!)")
    }
    // 每筆訊息的高
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    // Bubble 向內向外的形式
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    // Bubble 向內向外的形式
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        // 判斷在 左邊 還是 右邊 顯示
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    // User頭像
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        return avatars[message.senderId]
    }
    //在畫面新增 Message Func
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    // 每一筆的UICollectionViewCell設定
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == senderId { // 判斷訊息是否為自己發送
            cell.avatarImageView.sd_setImage(with: avatarUrlArray[senderId], completed: nil) // 大頭貼設定
            cell.avatarImageView.layer.cornerRadius = cell.avatarImageView.frame.width / 2 // 將View變成圓形
            cell.avatarImageView.clipsToBounds = true
            cell.textView?.textColor = UIColor.white //字體顏色
        } else{
            cell.avatarImageView.sd_setImage(with: avatarUrlArray[message.senderId], completed: nil)
            cell.avatarImageView.layer.cornerRadius = cell.avatarImageView.frame.width / 2
            cell.avatarImageView.clipsToBounds = true
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    // 按下發送觸發
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
            "type":"text",
            "senderId": senderId!,
            "senderName": currentUsername,
            "text": text!,
            "time":timeFormat.string(from: nowtime)
        ]
        itemRef.setValue(messageItem) // <- 新增的動作
        print("SBBBBB")
        print(avatarUrlArray[senderId]!)
        setNewState(sender: avatarUrlArray[senderId]!, Msg: text!, timeStamp: timeFormat.string(from: nowtime))
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 音效
        finishSendingMessage()
        isTyping = false
    }
    // 按下附件按鈕觸發
    override func didPressAccessoryButton(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        let imagePickerAlertController = UIAlertController(title: "上傳圖片", message: "請選擇要上傳的圖片", preferredStyle: .actionSheet)
        // 新增 UIAlertAction 在 UIAlertController actionSheet 的 動作 (action) 與標題
        let imageFromLibAction = UIAlertAction(title: "照片圖庫", style: .default) { (Void) in
            // 判斷是否可以從照片圖庫取得照片來源
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.photoLibrary)，並 present UIImagePickerController
                picker.sourceType = UIImagePickerController.SourceType.photoLibrary
                self.present(picker, animated: true, completion: nil)
            }
        }
        let imageFromCameraAction = UIAlertAction(title: "相機", style: .default) { (Void) in
            // 判斷是否可以從相機取得照片來源
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                // 如果可以，指定 UIImagePickerController 的照片來源為 照片圖庫 (.camera)，並 present UIImagePickerController
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }
        }
        // 新增一個取消動作，讓使用者可以跳出 UIAlertController
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (Void) in
            imagePickerAlertController.dismiss(animated: true, completion: nil)
        }
        // 將上面三個 UIAlertAction 動作加入 UIAlertController
        imagePickerAlertController.addAction(imageFromCameraAction)
        imagePickerAlertController.addAction(imageFromLibAction)
        imagePickerAlertController.addAction(cancelAction)
        // 當使用者按下 uploadBtnAction 時會 present 剛剛建立好的三個 UIAlertAction 動作與
        present(imagePickerAlertController, animated: true, completion: nil)
    }
    // 對FireBase監聽最新訊息
    private func observeMessages() {
        //到message集合內
        messageRef = channelRef!.child("messages")
        // 抓取最後100筆資料
        let messageQuery = messageRef.queryLimited(toLast: 100)
        // .observe < 用監聽的模式來抓取新的 Message
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 將值轉乘 Dictionary
            let messageData = snapshot.value as! Dictionary<String, String>
            // 文字訊息
            if let id = messageData["senderId"] as String?, let name = messageData["senderName"] as String?, let text = messageData["text"] as String?{
                // 在畫面是上新增訊息
                self.addMessage(withId: id, name: name, text: text)
                self.finishReceivingMessage()
            }else if let id = messageData["senderId"] as String?, // 圖片訊息
                let photoURL = messageData["photoURL"] as String?,
                let name = messageData["senderName"] as String? {
                // 判斷此圖是否為自己發送
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 在畫面上新增圖片
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem, name: name)
                    if photoURL.hasPrefix("gs://") {
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }else {
                print("Error! Could not decode message data")
            }
        })
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            if let photoURL = messageData["photoURL"] as String? { // 2
                if let mediaItem = self.photoMessageMap[key] { // 3
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                }
            }
        })
    }
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // 有沒有正在打字的Bool
        isTyping = textView.text != ""
    }
    // User是否正在打字
    private func observeTyping() {
        let typingIndicatorRef = channelRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery.observe(.value) { (data: DataSnapshot) in
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            self.showTypingIndicator = data.childrenCount > 0
//            self.scrollToBottom(animated: true)
        }
    }
    func sendPhotoMessage() -> String? {
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
            "type":"photo",
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            "senderName": currentUsername
        ]
        print("555")
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
//        setNewState(sender: "123", Msg: "123")
        finishSendingMessage()
        return itemRef.key
    }
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    func setNewState(sender: URL, Msg: String, timeStamp: String){
        let aaa = Database.database().reference().child("channels").child(channel!.name!)
        let senderUrl = "\(sender)"
        let item = ["newSender":senderUrl,
                    "newMsg":Msg,
                    "newTimeStamp":timeStamp]
        aaa.updateChildValues(item)
    }
    // 監聽所有的大頭貼資料
    func getAvatarData(){
        self.ref = Database.database().reference().child("user").child("avatar")
        self.ref.observe(.childAdded) { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let name = value?["name"] as! String
            let uid = value?["uid"] as! String
            let avatarUrl = value?["avatarUrl"] as! String
            let url = URL(string: avatarUrl)
            self.avatarUrlArray[uid] = url
            print(self.avatarUrlArray)
            print("=======================================================")
            if(self.senderId == uid){
                self.currentUsername = name
            }
        }
    }
    // 在畫面中新增圖片訊息
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem, name: String) {
        if let message = JSQMessage(senderId: id, displayName: name, media: mediaItem) {
            messages.append(message)
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            collectionView.reloadData()
        }
    }
    // 透過Url拿到圖片Data
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        let storageRef = Storage.storage().reference(forURL: photoURL)
        storageRef.downloadURL { (url, error) in
            if let error = error {
                print("error:\(error)")
            } else {
                print("apple:\(url)")
                NetworkController.shared.fetchImage(url: url!) {[weak self] (image) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        mediaItem.image = image
                        self.collectionView.reloadData()
                    }
                    guard key != nil else {
                        return
                    }
                    self.photoMessageMap.removeValue(forKey: key!)
                }
            }
        }
        // 下載資料
        //        storageRef.getData(maxSize: INT64_MAX){ (data, error) in
        //            if let error = error {
        //                print("Error downloading image data: \(error)")
        //                return
        //            }
        //            print("下載的Data:\(data)")
        //            //下載metadata
        //            storageRef.getMetadata(completion: { (metadata, metadataErr) in
        //                if let error = metadataErr {
        //                    print("Error downloading metadata: \(error)")
        //                    return
        //                }
        //                print("metadata:\(metadata)")
        //                print(metadata?.contentType)
        //                if (metadata?.contentType == "image/gif") {
        //                    mediaItem.image = UIImage.gif(data: data!)
        //                } else {
        //                    mediaItem.image = UIImage.init(data: data!)
        //                }
        //                self.collectionView.reloadData()
        //                guard key != nil else {
        //                    return
        //                }
        //                self.photoMessageMap.removeValue(forKey: key!)
        //            })
        //        }
    }
}
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // 按下附件按鈕後選取完圖片之動作
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]){
        var selectedImageFromPicker: UIImage?
        // 取得從 UIImagePickerController 選擇到的檔案
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageFromPicker = pickedImage
        }
        // 關閉圖庫
        dismiss(animated: true, completion: nil)
        var dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let nowtime = dateFormat.string(from: Date())
        // 將照片上傳到 Storage
        if let selectedImage = selectedImageFromPicker {
            print("\(selectedImage)")
            // 從 UserDefaults 取得登入者的 ID，該 ID 會被用來當成照片的檔名
            if let key = sendPhotoMessage() {
                // 第一個 child 的參數為「目錄名稱」；第二個 child 的參數為「圖片名稱」
                let storageRef = Storage.storage().reference().child("\(userMail)").child("\(nowtime).png")
                // 將圖片轉成 png 後上傳到 storage
                if let uploadData = selectedImage.pngData() {
                    // 將圖片上傳至 Storage
                    storageRef.putData(uploadData, metadata: nil, completion: { (data, error) in
                        //監控上傳
                        let uploadTask = storageRef.putData(uploadData)
                        let observer = uploadTask.observe(.progress) { snapshot in
                            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                                / Double(snapshot.progress!.totalUnitCount)
                            print(percentComplete)
                        }
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        // 將圖片Url新增至資料中
                        self.setImageURL(self.storageRef.child((data?.path)!).description, forPhotoMessageWithKey: key)
                    })
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
