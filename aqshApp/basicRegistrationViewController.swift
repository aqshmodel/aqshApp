//
//  basicRegistrationViewController.swift
//  aqshApp
//
//  Created by Takahiro Tsukada on 2019/06/22.
//  Copyright © 2019 Takahiro Tsukada. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit


class basicRegistrationViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource, LoginButtonDelegate {

    @IBOutlet weak var genderText: UITextField!
    @IBOutlet weak var managerPhoneNumber: UITextField!
    @IBOutlet weak var managerBirthDay: UITextField!
    @IBOutlet weak var managerArea: UITextField!
    
    
    //外部のファイルから書き換えられないようにprivate
    private var ref: DatabaseReference! //RealtimeDatabaseの参照
    private var user: User! //ユーザー
    private var handle: DatabaseHandle!//追加
    var key: String = ""  //データベース内の値を読むキー格納用
    var sendData: [String: Any] = [:] //Realtimeデータベースに書き込む内容を格納する辞書
    var readData: [[String: Any]] = []
    //UIPickerViewを定義するための変数
    var pickerView: UIPickerView = UIPickerView()
    //UIDatePickerを定義するための変数
    var datePicker: UIDatePicker = UIDatePicker()
    let dataList = ["男性", "女性"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference() //リファレンスの初期化
        user = Auth.auth().currentUser         //認証した現在のユーザーを格納
        // ピッカー設定
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.showsSelectionIndicator = true
        // Dateピッカー設定
        datePicker.datePickerMode = UIDatePicker.Mode.date
        datePicker.timeZone = NSTimeZone.local
        datePicker.locale = Locale(identifier: "ja-JP")
        managerBirthDay.inputView = datePicker
        
        
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let toolbarDate = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        let doneItemDate = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDate))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        toolbarDate.setItems([spacelItem, doneItemDate], animated: true)
        
        // インプットビュー設定
        genderText.inputView = pickerView
        genderText.inputAccessoryView = toolbar
        managerBirthDay.inputAccessoryView = toolbarDate
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // facebookにログイン済みかチェック
        if let token = AccessToken.current {
            let credential = FacebookAuthProvider.credential(withAccessToken: token.tokenString)
            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                if error != nil {
                    return
                }
                // ログインしていたら過去にユーザー登録をしていないかチェック
                self.handle = self.ref.child("AQSH").child("manager").queryOrdered(byChild: "managerId").observe(.value) { (snapshot: DataSnapshot) in
                    DispatchQueue.main.async {
                        self.snapshotToArray(snapshot: snapshot)
                        let num = self.readData.count
                        if num != 0   {
                            for i in 0 ... num-1 {
                                
                                if self.readData[i]["registerId"]! as! String == self.user!.uid {
                                    // データベースの値をreadDataに読み込み、過去のIDがあったら基本登録情報がないかチェック
                                    guard self.readData[i]["managerGender"] == nil else {
                                        self.performSegue(withIdentifier: "toTalentRegistration", sender: self)//IDで識別
                                        return
                                    }
                                    
                                } else {
                                    //過去にIDが無かったら自動生成の文字列の階層までのDatabaseReferenceを格納
                                    let sendRef = self.ref.child("AQSH").child("manager").childByAutoId()
                                    let managerId = sendRef.key! //自動生成された文字列(AutoId)を格納
                                    sendRef.setValue(["managerId": managerId,"registerId": self.user.uid]) //データベースにそれぞれ書き込み
                                }
                            }
                        }
                    }
                }
            }
            return
        }
    }
    
    // facebook login callback
    func loginButton(_ loginButton: FBLoginButton!, didCompleteWith result: LoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print("Error")
            return
        }
        // ログイン時の処理
    }
    // Logout callback
    func loginButtonDidLogOut(_ loginButton: FBLoginButton!) {
    }
    
    
    @IBAction func basicRegistrationButton(_ sender: UIButton) {
        guard genderText.text! != "" ||
            managerPhoneNumber.text! != "" ||
            managerBirthDay.text! != "" ||
            managerArea.text! != ""
            else {
                showAlert(message: "未入力の項目があります")
                return}
        /*** 行頭の"handle = "を追加！ -> DatabaseHandleを取得 ***/
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
                // データベースへの書き込み
                self.sendUserRagistrationToFirebase()
                // 画面遷移の処理
                self.performSegue(withIdentifier: "toTalentRegistration", sender: self)//IDで識別
            }
        }
        
    }
    
    //Firebaseに入力内容を保存するためのメソッド
    func sendUserRagistrationToFirebase(){
        if !sendData.isEmpty {sendData = [:] }//辞書の初期化
        sendData = [
            "managerGender": genderText.text!, //性別
            "managerPhoneNumber": managerPhoneNumber.text!, //マネージャー電話番号
            "managerBirthDay": managerBirthDay.text!, //マネージャーの生年月日
            "managerArea": managerArea.text! //マネージャー活動地域
        ]
        ref.child("AQSH/manager/\(key)").updateChildValues(sendData) //ここでAQSH/manager/認証しているマネージャIDの階層に書き込んでいます
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
    
    // アラートを表示する関数
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
        alert.addAction(close)
        present(alert, animated: true, completion: nil)
    }
    
    // UIPickerViewの列の数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // UIPickerViewの行数、要素の全数
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        return dataList.count
    }
    
    // UIPickerViewに表示する配列
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        
        return dataList[row]
    }
    
    // UIPickerViewのRowが選択された時の挙動
    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        // 処理
    }
    // 決定ボタン押下
    @objc func done() {
        genderText.endEditing(true)
        genderText.text = "\(dataList[pickerView.selectedRow(inComponent: 0)])"
        
    }
    @objc func doneDate() {
        managerBirthDay.endEditing(true)
        
        // 日付のフォーマット
        let formatter = DateFormatter()
        
        //"yyyy年MM月dd日"を"yyyy/MM/dd"したりして出力の仕方を好きに変更できる
        formatter.dateFormat = "yyyy年MM月dd日"
        
        //(from: datePicker.date))を指定してあげることで
        //datePickerで指定した日付が表示される
        managerBirthDay.text = "\(formatter.string(from: datePicker.date))"
    }
   
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

