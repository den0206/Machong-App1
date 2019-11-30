//
//  SettingTableViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/30.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit


class SettingTableViewController: UITableViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var fullnameLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        
        if FUser.currentUser() != nil {
            setupUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    // MARK: - Table view data source

       override func numberOfSections(in tableView: UITableView) -> Int {
           // #warning Incomplete implementation, return the number of sections
           return 4
       }

       override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           // #warning Incomplete implementation, return the number of rows
           
           if section == 1 {
               return 5
           }
           
           return 2
           
       }

    
    //MARK: IBActions
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        
        FUser.logOutCurrentUser { (success) in
            
            if success {
                self.showWelcomeView()
            }
        }
        
    }
    
    func showWelcomeView() {
        
        let welcomeView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "welcome")
        
        self.present(welcomeView,animated: true, completion: nil)
    }
    
    
    func setupUI() {
        
        let currentUser = FUser.currentUser()!
        
        fullnameLabel.text = currentUser.fullname
        
        if currentUser.avatar != "" {
            imageFromData(pictureData: currentUser.avatar) { (avatar) in
                self.avatarImageView.image = avatar!.circleMasked
            }
        }
    }

   
  

}
