//
//  OthersViewController.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/4/9.
//  Copyright © 2020 Corgi. All rights reserved.
//

import UIKit
import Firebase
class OthersViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    @IBAction func signoutAction(_ sender: Any) {
        try! Auth.auth().signOut()
        pushViewController(vc: LoginVC())
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
