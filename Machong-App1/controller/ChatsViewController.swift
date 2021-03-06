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
    
    let searchController = UISearchController(searchResultsController: nil)
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // for View
    
    override func viewWillAppear(_ animated: Bool) {
        loadRecentChats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        recentLisner.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        self.navigationController?.navigationBar.barTintColor =  UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        
        tableView.tableFooterView = UIView()
        
        

     
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
                        
                       
                    }
                }
                self.tableView.reloadData()
            }
        })
         
    }
    
}

//MARK: TableView Delegate

extension ChatsViewController : UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filterdChats.count
        } else {
            return recentChats.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentChatsTableViewCell
        
        cell.delegate = self
        
        var recent : NSDictionary!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filterdChats[indexPath.row]
        } else {
            
            recent = recentChats[indexPath.row]
        }
        
        cell.generateCell(recentChat: recent, indexPath: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        var recent : NSDictionary!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            recent = filterdChats[indexPath.row]
        } else{
            recent = recentChats[indexPath.row]
        }
        
        restartRecentChat(recent: recent)
        
        let messageVC = MessageViewController()
        messageVC.chatRoomId = (recent[kCHATROOMID] as? String)!
        messageVC.memberIds = (recent[kMEMBERS] as? [String])!
        messageVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
        
        
        navigationController?.pushViewController(messageVC, animated: true)
        
    }
    
    //MARK: Edit & Delete
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var tempRecent : NSDictionary!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            tempRecent = filterdChats[indexPath.row]
        } else {
            tempRecent = recentChats[indexPath.row]
        }
        
        var muteTitle = "Unmute"
        var mute = false
        
        if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()) {
            muteTitle = "Mute"
            mute = true
        }
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            self.recentChats.remove(at: indexPath.row)
            deleteRecentChat(recentChatDictionary: tempRecent)
            
            tableView.reloadData()
        }
        
        let muteAction = UITableViewRowAction(style: .default, title: muteTitle) { (action, indexPath) in
            self.updatePushMembers(recent: tempRecent, mute: mute)
        }
        
        muteAction.backgroundColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        deleteAction.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        
        return [deleteAction,muteAction]
        
    }
    
    func updatePushMembers(recent : NSDictionary, mute : Bool) {
        
        var membersToPush = recent[kMEMBERSTOPUSH] as! [String]
        
        if mute {
            let index = membersToPush.firstIndex(of: FUser.currentId())!
            membersToPush.remove(at: index)
        } else {
            membersToPush.append(FUser.currentId())
        }
        
        
        // save Firestore
        updateExistingRecentWithNewValuies(chatRoomId: recent[kCHATROOMID] as! String, members: recent[kMEMBERS] as! [String], withValues: [kMEMBERSTOPUSH : membersToPush])
        
    }
}



//MARK: RecentChatCell Delegate

extension ChatsViewController : RecentChatsTableViewCellDelegate {
    func didAvatarTapped(indexPath: IndexPath) {
        
        var recent : NSDictionary!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filterdChats[indexPath.row]
        } else {
            recent = recentChats[indexPath.row]
        }
        
        if recent[kTYPE] as! String == kPRIVATE {
            reference(.User).document(recent[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
                guard let snapshot = snapshot else {return}
                
                if snapshot.exists {
                    let userDictionary = snapshot.data() as! NSDictionary
                    let tempUser = FUser(_dictionary: userDictionary)
                    
                    self.goProfile(user: tempUser)
                }
            }
        }
    }
    
    func goProfile(user : FUser) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileTableViewController
        
        profileVC.user = user
        
        navigationController?.pushViewController(profileVC, animated: true)
        
    }
    
    
}

//MARK: searchResuleUpdating

extension ChatsViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
        filterContentForText(searchText: searchController.searchBar.text!)
        
    }
    
    func filterContentForText(searchText : String, scope : String = "All") {
        
        filterdChats = recentChats.filter({ (recentChat) -> Bool in
            return (recentChat[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    
}
