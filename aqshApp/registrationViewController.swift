//
//  registrationViewController.swift
//  aqshApp
//
//  Created by Takahiro Tsukada on 2019/06/21.
//  Copyright © 2019 Takahiro Tsukada. All rights reserved.
//

import UIKit
import Firebase

class registrationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var managerFamilyName: UITextField!
    @IBOutlet weak var managerFirstName: UITextField!
    @IBOutlet weak var familyNamePhonetic: UITextField!
    @IBOutlet weak var firstNamePhonetic: UITextField!
    @IBOutlet weak var managerMailAddress: UITextField!
    @IBOutlet weak var managerPassword: UITextField!
    @IBOutlet weak var confirmationPassword: UITextField!
    
    //外部のファイルから書き換えられないようにprivate
    private var ref: DatabaseReference! //RealtimeDatabaseの参照
    private var user: User! //ユーザー
    private var handle: DatabaseHandle!//追加
    var sendData: [String: Any] = [:] //Realtimeデータベースに書き込む内容を格納する辞書
    var readData: [[String: Any]] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference() //リファレンスの初期化
        user = Auth.auth().currentUser         //認証した現在のユーザーを格納
        managerMailAddress.delegate = self
        managerPassword.delegate = self
        confirmationPassword.delegate = self
        
    }
    
    // エンターキーでテキストフィールドを隠すメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
        
    }
    //Firebaseに入力内容を保存するためのメソッド
    func sendUserRagistrationToFirebase(){
        if !sendData.isEmpty {sendData = [:] }//辞書の初期化
        let sendRef = ref.child("AQSH").child("manager").childByAutoId()//自動生成の文字列の階層までのDatabaseReferenceを格納
        let managerId = sendRef.key! //自動生成された文字列(AutoId)を格納
        
        sendData = [
            "managerMailAddress": managerMailAddress.text!, //登録メールアドレス
            "managerPassword": managerPassword.text!, //マネージャーパスワード
            "managerFamilyName": managerFamilyName.text!, //マネージャーの姓
            "managerFirstName": managerFirstName.text!, //マネージャーの名
            "familyNamePhonetic": familyNamePhonetic.text!, //フリガナ セイ
            "firstNamePhonetic": firstNamePhonetic.text!, //フリガナ メイ
            "managerId": managerId, //マネージャーのID
            "registerId": user.uid //ユーザーID
        ]
        sendRef.setValue(sendData) //ここで実際にデータベースに書き込んでいます
    }
    
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
    
    
    @IBAction func registrationButton(_ sender: UIButton) {
        guard managerPassword.text! == confirmationPassword.text!
            else {
                showAlert(message: "パスワードが一致しません")
                return}
        guard managerMailAddress.text! != "" ||
              managerPassword.text! != "" ||
              managerFamilyName.text! != "" ||
              managerFirstName.text! != "" ||
              familyNamePhonetic.text! != "" ||
              firstNamePhonetic.text! != ""
              else {
            showAlert(message: "未入力の項目があります")
            return}
        
        /*** 行頭の"handle = "を追加！ -> DatabaseHandleを取得 ***/
        handle = ref.child("AQSH").child("manager").queryOrdered(byChild: "managerMailAddress").observe(.value) { (snapshot: DataSnapshot) in
            DispatchQueue.main.async {
                self.snapshotToArray(snapshot: snapshot)
                let num = self.readData.count
                if num != 0   {

                for i in 0 ... num-1 {
                    if self.readData[i]["managerMailAddress"]! as! String == self.managerMailAddress.text! {
                        self.showAlert(message: "同じメールアドレスの登録があります")
                        return
                    }
                    
                }
                }
                // データベースへの書き込み
                self.sendUserRagistrationToFirebase()
                // 画面遷移の処理
                self.performSegue(withIdentifier: "toBasicRegistration", sender: self)//IDで識別
                }
        }
    }
    
    // アラートを表示する関数
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        alert.addAction(close)
        present(alert, animated: true, completion: nil)
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
