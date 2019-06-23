//
//  searchTalentViewController.swift
//  aqshApp
//
//  Created by Takahiro Tsukada on 2019/06/22.
//  Copyright © 2019 Takahiro Tsukada. All rights reserved.
//

import UIKit
import Firebase

class searchTalentViewController: UIViewController {
    
    //外部のファイルから書き換えられないようにprivate
    private var ref: DatabaseReference! //RealtimeDatabaseの参照
    private var user: User! //ユーザー
    private var handle: DatabaseHandle!//マネージャー側のハンドラ
    private var talentHandle: DatabaseHandle!//タレント側のハンドラ
    var key: String = ""  //データベース内の値を読むキー格納用
    var readData: [[String: Any]] = []
    
    
    //データベースから読み込んだデータを配列(readData)に格納するメソッド
    func snapshotToArray(snapshot: DataSnapshot){
        if !readData.isEmpty {readData = [] }
        if snapshot.children.allObjects as? [DataSnapshot] != nil  {
            let snapChildren = snapshot.children.allObjects as? [DataSnapshot]
            for snapChild in snapChildren! {
                if let postDict = snapChild.value as? [String: Any] {
                    self.readData.append(postDict)
                }
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference() //リファレンスの初期化
        user = Auth.auth().currentUser         //認証した現在のユーザーを格納
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = ref.child("AQSH").child("manager").queryOrdered(byChild: "managerId").observe(.value) { (snapshot: DataSnapshot) in
            DispatchQueue.main.async {
                self.snapshotToArray(snapshot: snapshot)
                let num = self.readData.count
                if num != 0   {
                    for i in 0 ... num-1 {
                        
                        if self.readData[i]["registerId"]! as! String == self.user!.uid {
                            // データベースの値をreadDataに読み込み、認証しているユーザーIDでマネージャーIDを得る
                            self.key = self.readData[i]["managerId"]! as! String
                        }
                    }
                }
                
            }
        }
        talentHandle = ref.child("AQSH").child("talent").queryOrdered(byChild: "talentId").observe(.value) { (snapshot: DataSnapshot) in
            DispatchQueue.main.async {
                self.snapshotToArray(snapshot: snapshot)
                var num = self.readData.count
                if num != 0   {
                    for i in 0 ... num-1 {
                        
                        if self.readData[i]["referralManagerId"]! as! String == self.key {
                        //タレント側データベースの値をreadDataに読み込み、紹介元マネージャーが自分だったらデータ削除
//                            self.readData.remove(at: i)
//                            num -= 1
                        }
                    }
                }
            }
        }
    }

}
