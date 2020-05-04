//
//  LoginVC.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/1/6.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn

class LoginVC: BaseViewController,GIDSignInDelegate{
    
    @IBOutlet weak var account: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var FBBtn: FBButton!
    @IBOutlet weak var GoogleBtn: GIDSignInButton! // 5.0.0 Bug無法顯示
    var ref: DatabaseReference!
    // 連結Storage
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://firechat-74b64.appspot.com/")
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.title = "使用者登入"
        passwordTF.isSecureTextEntry = true // 將內容改 *******
        FBBtn.setTitle("FaceBook登入", for: .normal)
        // GoogleSingIn 委任 , 在5.0.0版以後 UIdelegate -> presentingViewController
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.delegate = self
//        GIDSignIn.sharedInstance()?.restorePreviousSignIn()  // 如果有登入過，會自動登入
        
    }
    
    // FireBase 登入
    @IBAction func loginAction(_ sender: Any) {
        Auth.auth().signIn(withEmail: "\(account.text!)", password: "\(passwordTF.text!)") { (AuthDataResult, error) in
            if let err = error {
                print("FireBase - 登入失敗:\(err.localizedDescription)")
                return
            }else{
                print("FireBase - 登入成功")
                let currentUser = Auth.auth().currentUser
                // 路徑為:user / avatar / UserUid
                self.ref = Database.database().reference().child("user").child("avatar").child(currentUser!.uid)
                // 一次性事件 - 透過此路徑檢查是否已有此使用者的資料
                self.ref.observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.exists(){
                        print("曾經登入過,資料庫有資料")
                    }else{
                        print("第一次登入")
                        let Item = [
                            "uid": "\(currentUser!.uid)",
                            "name":"\(Auth.auth().currentUser?.displayName!)",
                            "avatarUrl":"https://image.shutterstock.com/image-photo/portrait-surprised-beautifully-cat-on-260nw-1604783341.jpg"
                        ]
                        self.ref.setValue(Item)
                    }
                }
                self.pushViewController(vc: MainTabBarController())
            }
        }
    }
    // 第三方:FaceBook 登入
    @IBAction func facebookLogin(_ sender: Any) {
        let fbLoginManager = LoginManager()
        // 使用FB登入的SDK，並請求可以讀取用戶的基本資料和取得用戶email的權限
        fbLoginManager.logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            if let err = error{
                print("FaceBook - 登入失敗:\(err.localizedDescription) ")
            }else if AccessToken.current == nil{
                print("FaceBook - 拿不到 Token")
            }else{
                print("FaceBook - tokenString: \((AccessToken.current?.tokenString)!)")
                // 將用戶的access token，通過調用將其轉換為Firebase的憑證
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                // 呼叫Firebase的API處理登入的動作
                Auth.auth().signIn(with: credential, completion: { (user, error) in
                    if let err = error{
                        print("FaceBook - 已憑證方式登入失敗:\(err.localizedDescription)")
                    }else{
                        print("FaceBook - 登入成功")
                        let currentUser = Auth.auth().currentUser
                        // 路徑為:user / avatar / UserUid
                        self.ref = Database.database().reference().child("user").child("avatar").child(currentUser!.uid)
                        // 一次性事件 - 透過此路徑檢查是否已有此使用者的資料
                        self.ref.observeSingleEvent(of: .value) { (snapshot) in
                            if snapshot.exists(){
                                print("曾經登入過,資料庫有資料")
                            }else{
                                print("第一次登入")
                                let Item = [
                                    "uid": "\(currentUser!.uid)",
                                    "name":"\(user!.user.displayName!)",
                                    "avatarUrl":"\(user!.user.photoURL!)"
                                ]
                                self.ref.setValue(Item)
                            }
                        }
                        self.pushViewController(vc: MainTabBarController())
                    }
                })
            }
        }
    }
    
    @IBAction func GoogleLogin(_ sender: Any) {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    // 註冊頁面
    @IBAction func registerShow(_ sender: Any) {
        pushViewController(vc: RegisterVC())
    }
    // Google
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            print("Google登入錯誤:\(error.localizedDescription)")
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print("Google - 以憑證方式登入失敗:\(error.localizedDescription)")
                return
            }else{
                print("Google - 登入成功")
                let user: GIDGoogleUser = GIDSignIn.sharedInstance()!.currentUser
                let currentUser = Auth.auth().currentUser
                // 路徑為:user / avatar / UserUid
                self.ref = Database.database().reference().child("user").child("avatar").child(currentUser!.uid)
                // 一次性事件 - 透過此路徑檢查是否已有此使用者的資料
                self.ref.observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.exists(){
                        print("曾經登入過,資料庫有資料")
                    }else{
                        print("第一次登入")
                        let Item = [
                            "uid": "\(currentUser!.uid)",
                            "name":"\(user.profile.name!)",
                            "avatarUrl":"\(user.profile.imageURL(withDimension: 30)!)"
                        ]
                        self.ref.setValue(Item)
                    }
                }
                self.pushViewController(vc: MainTabBarController())
            }
        }
    }
}
