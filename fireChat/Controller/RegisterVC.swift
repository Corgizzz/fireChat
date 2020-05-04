//
//  RegisterVC.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/1/6.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit
import Firebase
class RegisterVC: BaseViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var avatarImgView: UIImageView!
    @IBOutlet weak var accountTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    var imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.avatarImgView.image = UIImage(named: "person.jpg")
        self.avatarImgView.layer.borderWidth = 1
        self.avatarImgView.layer.borderColor = UIColor.gray.cgColor
        self.avatarImgView.layer.cornerRadius = avatarImgView.frame.height/2
        self.avatarImgView.clipsToBounds = true //超出範圍的裁減掉
        
        self.avatarImgView.isUserInteractionEnabled = true //觸發後回傳Boolean
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(uploadAction))
        self.avatarImgView.addGestureRecognizer(gesture)
    }
    
    @IBAction func registerAction(_ sender: Any) {
        Auth.auth().createUser(withEmail: "\(accountTF.text!)", password: "\(passwordTF.text!)") { (AuthDataResult, Error) in
            print(Auth.auth().currentUser?.email)
            let user = Auth.auth().currentUser
            let uid = user?.uid
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = "Corgi"
            changeRequest?.commitChanges(completion: { (error) in
                if let error = error{
                    print(error.localizedDescription)
                }else{
                    print("使用者個人資料更新成功")
                    print(Auth.auth().currentUser?.displayName)
                    self.pushViewController(vc: LoginVC())
                }
            })
            
        }
    }
    @objc func uploadAction(){
        let alert = UIAlertController(title: "選擇上傳方式", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Photo", style: .default, handler: { _ in
            self.openGallary()
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil) //顯示以上設定
    }
    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
        {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera //相機
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openGallary()
    {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = true // 可否編輯
        self.present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage //抓到剛剛上傳的圖片資訊
        print("123123")
        self.avatarImgView.image = pickedImage
        print("\(pickedImage)")
        //        performSegue(withIdentifier: "Second", sender: nil)
        picker.dismiss(animated: true, completion: nil) // 退出相機介面
    }
}
