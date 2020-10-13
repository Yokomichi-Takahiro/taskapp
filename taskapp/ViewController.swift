//
//  ViewController.swift
//  taskapp
//
//  Created by 横道貴浩 on 2020/10/05.
//  Copyright © 2020 Takahiro.Yokomichi. All rights reserved.
//

import UIKit
import RealmSwift //データベース追加した
import UserNotifications 

class ViewController: UIViewController,UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    //レルムのインスタンスを取得する
    let realm = try! Realm() //インスタンスを取得←追加した
    
    // DB内のタスクが格納されるリスト。
    // 日付の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
            //try!　Realm () は レルムクラスを取り出す記述 objectsはRealmで作成したクラス※今回はTaskだけ作成したので                     objects(Task.self)と記述 （selfはこのファイルViewcontrollerで使うという事）sortedは並び替えの事でその対象は    date※日付、ascending:　は上昇という意味でtrueにすると日付が近い順に並び替えをして一番上に来るという事
   
    //（課題）セクションの数を表示させるために作った
//    var categoryArray = try! Realm().objects(Task.self).sorted(byKeyPath: "category", ascending: true)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
    }
    
    //課題のカテゴリをセクションで追加する設定をしたい　ここから...
    //categoryの数だけ表示してねと指示
//    func numberOfSections(in tableView: UITableView) -> Int {
//      return categoryArray.count
//    }
//    //セクションの高さを変えた
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 45
//    }
//    
//    //セクションの色を変えた
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let view = UIView()
//        view.backgroundColor = UIColor.lightGray
//
//        return view
//    }
    //ここまで
    
    //データの数(＝セルの数)を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  taskArray.count //セルの数を返しセルが更新されるとセルの数で数字が決まる
    }
    //各セルに内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なセルを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
       
            
        //セルに値を設定する
       let task = taskArray[indexPath.row]
       cell.textLabel?.text = task.title
        
        print(task.title)

       let formatter = DateFormatter()
       formatter.dateFormat = "yyyy-MM-dd HH:mm"

       let dateString:String = formatter.string(from: task.date)
       cell.detailTextLabel?.text = dateString
       return  cell
    }
    
    //各セルを選択した時に実行させるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil) // ←追加する
    }

    //セルが削除可能なことを伝えるメソッド
   func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
       return .delete
   }
    // Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    // --- ここから ---
    if editingStyle == .delete {
        
        // 削除するタスクを取得する
        let task = self.taskArray[indexPath.row]

        // ローカル通知をキャンセルする
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

        // データベースから削除する
        try! realm.write {
            self.realm.delete(self.taskArray[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
                       }
                   }
                
            
        }
        
    }
    //入力画面から戻ってきた時に　TabelView　を更新させる
   override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       tableView.reloadData()
   }
    
    
    
    // segue で画面遷移する時に呼ばれる
      override func prepare(for segue: UIStoryboardSegue, sender: Any?){
             let inputViewController:InputViewController = segue.destination as! InputViewController
        
        

             if segue.identifier == "cellSegue" {
                 let indexPath = self.tableView.indexPathForSelectedRow
                 inputViewController.task = taskArray[indexPath!.row]
             } else {
                 let task = Task()

                 let allTasks = realm.objects(Task.self)
                 if allTasks.count != 0 {
                     task.id = allTasks.max(ofProperty: "id")! + 1
                 }

                 inputViewController.task = task
           }
       }
   
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.isEmpty {
            taskArray = realm.objects(Task.self)
        } else {
            taskArray = realm
                .objects(Task.self)
        
                .filter("category CONTAINS %@", searchText)
        
        }
            // Reaimのデータを条件で絞り込むために.filterメソッドを使い検索バーに入力された文字列を使って
            // 部分一致で検索するにはBEGINSWITH（前方一致）、ENDSWITH（後方一致）、CONTAINS（部分一致）を使います。
            // ※.filter()はcategory(Taskクラス)とsearchText(検索Barの中と照らし合わせて)一部(CONTAINS)でも一致したら表示するということ。
            //※tableView.reloadData()はUISearchBarの入力をトリガーにして検索を実行し、画面に反映するには、
            //UISearchBarDelegateのテキストが入力されたら呼ばれるメソッドで処理をします。
            //TableViewのデータソースに使っているResultsオブジェクトを、入力された文字列を使って検索したものに更新し
            //表示に反映させるためにTableViewをリロードします
            tableView.reloadData()
    }

    
    
}
    

 
