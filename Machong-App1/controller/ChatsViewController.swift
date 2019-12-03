//
//  ChatsViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/30.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController {
    
    var recentChats : [NSDictionary] = []
    var filterdChats : [NSDictionary] = []
    
    var recentLisner : ListenerRegistration!
    
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        loadRecentChats()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       

     
    }
    
  
    
    //MARK: IBActions
    
    @IBAction func createNewChatsButtonPressed(_ sender: Any) {
        
        let usersVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "usersTableVIew") as! UsersTableViewController
        
        self.navigationController?.pushViewController(usersVC, animated: true)
    }
    
    
    //MARK: Load Chats
    
    func loadRecentChats() {
        
        recentLisner = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {return}
            
            self.recentChats = []
            
            if !snapshot.isEmpty {
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                
                for recent in sorted {
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                        self.recentChats.append(recent)
                        
                        print(self.recentChats.count)
                    }
                }
                self.tableView.reloadData()
            }
        })
        
    }
    
}

extension ChatsViewController : UITableViewDelegate, UITableViewDataSource {
    
    
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return 1
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentChatsTableViewCell
          
          return cell
      }
}
