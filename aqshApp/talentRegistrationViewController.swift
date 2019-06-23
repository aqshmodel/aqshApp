//
//  talentRegistrationViewController.swift
//  aqshApp
//
//  Created by Takahiro Tsukada on 2019/06/22.
//  Copyright © 2019 Takahiro Tsukada. All rights reserved.
//

import UIKit
import Firebase

class talentRegistrationViewController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var talentName: UITextField!
    @IBOutlet weak var genderText: UITextField!
    @IBOutlet weak var talentArea: UITextField!
    @IBOutlet weak var talentSkil: UITextField!
    
    //外部のファイルから書き換えられないようにprivate
    private var ref: DatabaseReference! //RealtimeDatabaseの参照
    private var user: User! //ユーザー
    private var handle: DatabaseHandle!//マネージャー側のハンドラ
    private var talentHandle: DatabaseHandle!//タレント側のハンドラ
    var key: String = ""  //データベース内の値を読むキー格納用
    var sendData: [String: Any] = [:] //Realtimeデータベースに書き込む内容を格納する辞書
    var readData: [[String: Any]] = []
    //UIPickerViewを定義するための変数
    var pickerView: UIPickerView = UIPickerView()
    let dataList = ["男性", "女性"]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference() //リファレンスの初期化
        user = Auth.auth().currentUser         //認証した現在のユーザーを格納
        talentName.delegate = self
        talentArea.delegate = self
        talentSkil.delegate = self
        // ピッカー設定
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.showsSelectionIndicator = true
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        
        // インプットビュー設定
        genderText.inputView = pickerView
        genderText.inputAccessoryView = toolbar

    }
    
    // エンターキーでテキストフィールドを隠すメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
        
    }
    
    @IBAction func nextTalentButton(_ sender: UIButton) {
        guard genderText.text! != "" ||
            talentName.text! != "" ||
            talentArea.text! != "" ||
            talentSkil.text! != ""
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
                self.genderText.text = ""
                self.talentName.text = ""
                self.talentArea.text = ""
                self.talentSkil.text = ""
            }
        }
        self.showAlert(message: "タレント\(self.talentName.text!)さんを登録しました")
        talentHandle = ref.child("AQSH").child("talent").queryOrdered(byChild: "talentId").observe(.value) { (snapshot: DataSnapshot) in
            DispatchQueue.main.async {
                self.snapshotToArray(snapshot: snapshot)
                let num = self.readData.count
                var talentCount = 0 //マネージメントしている登録タレントの数
                if num != 0   {
                    for i in 0 ... num-1 {
                        
                        if self.readData[i]["referralManagerId"]! as! String == self.key {
                            // タレント側データベースの値をreadDataに読み込み、紹介元マネージャーの数をカウント
                            talentCount += 1
                            guard talentCount < 3  else {
                                // 画面遷移の処理
                                self.performSegue(withIdentifier: "toSearchTalent", sender: self)//IDで識別
                                return}
                            
                        }
                    }
                }
            }
            }
    }
    
    
    
    //Firebaseに入力内容を保存するためのメソッド
    func sendUserRagistrationToFirebase(){
        if !sendData.isEmpty {sendData = [:] }//辞書の初期化
        let sendRef = ref.child("AQSH").child("talent").childByAutoId()//自動生成の文字列の階層までのDatabaseReferenceを格納
        let talentId = sendRef.key! //自動生成された文字列(AutoId)を格納
        let managerId = key
        sendData = [
            "talentId": talentId,
            "talentGender": genderText.text!, //タレント性別
            "referralManagerId": managerId, //紹介元マネージャーID
            "talentName": talentName.text!, //タレントニックネーム
            "talentArea": talentArea.text!, //タレント活動地域
            "talentSkil": talentSkil.text!  //タレントスキル
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
}

