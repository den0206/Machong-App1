//
//  UsersTableViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/30.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

class UsersTableViewController: UITableViewController, UISearchResultsUpdating, UsersTabeleViewCellDelagate {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var userSegmentController: UISegmentedControl!
    
    var allUsers : [FUser] = []
    var filterUsers : [FUser] = []
    var allUsersGroup = NSDictionary() as! [String : [FUser]]
    var sectionTitleList : [String] = []
//    var scrollBeginingPoint: CGPoint!
    
    let searchController = UISearchController(searchResultsController: nil)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        
        navigationItem.searchController = searchController
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        
        loadUsers(filter: kCITY)
        
        // Swipe Actions
        
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        upSwipe.direction = .up
        upSwipe.delegate = self
        
        self.tableView.addGestureRecognizer(upSwipe)
        
        //
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return allUsersGroup.count
        }
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filterUsers.count
        } else {
            
            let sectionTitle = self.sectionTitleList[section]
            let users = self.allUsersGroup[sectionTitle]
            
            return users!.count
        }
        
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UsersTableViewCell
        var user : FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filterUsers[indexPath.row]
        } else {
            
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGroup[sectionTitle]
            
            user = users![indexPath.row]
        }
        
        cell.delegate = self
        cell.generateCellWith(fuser: user, indexPath: indexPath)
        
        return cell
    }
    
    //MARK: Select Row
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var user : FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filterUsers[indexPath.row]
        } else {
            
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = allUsersGroup[sectionTitle]
            
            user = users![indexPath.row]
        }
        
        startPrivateChat(user1: FUser.currentUser()!, user2: user)
        
        
    }
    
    //MARK: section Title
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return sectionTitleList[section]
        }
        
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            
            return self.sectionTitleList
        }
        
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    //MARK: loadUsers
    
    func loadUsers(filter : String) {
        
        ProgressHUD.show()
        
        var query : Query!
        
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.getDocuments { (snapshot, error) in
            
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGroup = [:]
            
            if error != nil {
                print(error?.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            
            guard let snapshot  = snapshot else {
                ProgressHUD.dismiss(); return
            }
            
            if !snapshot.isEmpty {
                
                for userDictionary in snapshot.documents {
                    
                    let useDIctionary = userDictionary.data() as NSDictionary
                    let user = FUser(_dictionary: useDIctionary)
                    
                    // exclude currentUser
                    
                    if user.objectId != FUser.currentId() {
                        self.allUsers.append(user)
                    }
                    
                }
                
                self.splitDataIntoSections()
                self.tableView.reloadData()
                
            }
            
            self.tableView.reloadData()
            ProgressHUD.dismiss()
            
        }
        
        
    }
    
    //MARK: Add sectiontitle
    
    fileprivate func splitDataIntoSections() {
        
        var sectionTitle : String = ""
        
        for i in 0 ..< self.allUsers.count {
            
            let currentUser = self.allUsers[i]
            let firstCharacter = currentUser.firstname.first!
            
            let firstCarString = "\(firstCharacter)"
            
            if firstCarString != sectionTitle {
                
                sectionTitle = firstCarString
                
                self.allUsersGroup[sectionTitle] = []
                self.sectionTitleList.append(sectionTitle)
            }
            
            self.allUsersGroup[firstCarString]?.append(currentUser)
        }
        
        
    }
    
    //MARK:
    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default :
            return
        }
        
    }
    
    //MARK: Search Protcole
    
    
    func filterContentForSearchText(searchText : String, scope: String = "All") {
        
        filterUsers = allUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filterContentForSearchText(searchText: searchController.searchBar.text!)
        
    }
    
    
    func didtappedAvatar(indexPath: IndexPath) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileTableViewController
        
        var user : FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filterUsers[indexPath.row]
        } else {
            
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGroup[sectionTitle]
            
            user = users![indexPath.row]
            
        }
        
        profileVC.user = user
        navigationController?.pushViewController(profileVC, animated: true)
        
    }
    
}

extension UsersTableViewController : UIGestureRecognizerDelegate {
    
 
    // Swipe Actions
       
       @objc func handleSwipe(_ sender : UISwipeGestureRecognizer) {
           
           switch sender.direction {
           case .up:
               print("up")
           default:
               break
           }
       }
       
       func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
           return true
       }
       
       //
    
}
