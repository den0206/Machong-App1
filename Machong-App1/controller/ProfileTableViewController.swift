//
//  ProfileTableViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/01.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit


class ProfileTableViewController: UITableViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var messageButtonOutlet: UIButton!
    @IBOutlet weak var blockUserOutlet: UIButton!
    
    var user : FUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        
        return 30
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    //MARK: setupUI
    
    func setupUI() {
        
        if user != nil {
            
            self.title = "Profile"
            
            fullnameLabel.text = user!.fullname
            phoneNumberLabel.text = user!.phoneNumber
            
            updateBlockUsers()
            
            imageFromData(pictureData: user!.avatar) { (avatar) in
                self.avatarImageView.image = avatar?.circleMasked
            }
        }
    }
    
    
    //MARK: IBActions
    
    @IBAction func callButtonPressed(_ sender: UIButton) {
        print("call")
    }
    
    @IBAction func messageButtonPressed(_ sender: UIButton) {
        print("message")
    }
    
    @IBAction func blockButtonPressed(_ sender: UIButton) {
        
        var currentBlockId = FUser.currentUser()!.blockedUsers
        
        if currentBlockId.contains(user!.objectId) {
            currentBlockId.remove(at: currentBlockId.firstIndex(of: user!.objectId)!)
        } else {
            currentBlockId.append(user!.objectId)
        }
        
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentBlockId]) { (error) in
            
            if error != nil {
                print(error?.localizedDescription)
                return
            }
           
            self.updateBlockUsers()
        }
    }
    
    func updateBlockUsers() {
        
        if user!.objectId != FUser.currentId() {
            callButtonOutlet.isHidden = false
            messageButtonOutlet.isHidden = false
            blockUserOutlet.isHidden = false
        } else {
            callButtonOutlet.isHidden = true
            messageButtonOutlet.isHidden = true
            blockUserOutlet.isHidden = true
        }
        
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId) {
            blockUserOutlet.setTitle("UNBLOCK", for: .normal)
        } else {
            blockUserOutlet.setTitle("BLOCK", for: .normal)
        }
    }
    
}
