//
//  ViewController.swift
//  aqshApp
//
//  Created by Takahiro Tsukada on 2019/06/20.
//  Copyright © 2019 Takahiro Tsukada. All rights reserved.
//
import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit


class ViewController: UIViewController, LoginButtonDelegate {
   
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let logo = UIImage(named: "AQSHlogo")
        logoImage.image = logo
    
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // ログイン済みかチェック
        if let token = AccessToken.current {
            let credential = FacebookAuthProvider.credential(withAccessToken: token.tokenString)
            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                if error != nil {
                    // ...
                    return
                }
//                // ログイン時の処理
//                 self.performSegue(withIdentifier: "toBasicRegistration", sender: self)//IDで識別
            }
            return
        }
    }
    
   
    
    // login callback
    func loginButton(_ loginButton: FBLoginButton!, didCompleteWith result: LoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print("Error")
            return
        }
        // ログイン時の処理
        self.performSegue(withIdentifier: "toBasicRegistration", sender: self)//IDで識別
    }
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBAction func fbLoginButton(_ sender: UIButton) {
        let fbLoginBtn = FBLoginButton()
        fbLoginBtn.permissions = ["public_profile", "email"]
        fbLoginBtn.delegate = self
        self.performSegue(withIdentifier: "toBasicRegistration", sender: self)//IDで識別
    }
    
    
    @IBAction func logoutButton(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    // Logout callback
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
    }
}



