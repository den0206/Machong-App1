//
//  WelcomeVIewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/28.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

class WelcomeVIewController: UIViewController {
    
    
    @IBOutlet weak var emailaTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var repeatTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    //MARK: login & register
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        if emailaTextField.text != "" && emailaTextField.text != "" {
            
            loginUser()
            
        } else {
            ProgressHUD.showError("Eメールかパスワードが空欄です。")
        }
        
        dissmisKeyBoard()
    }
    
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        dissmisKeyBoard()
        
        if emailaTextField.text != "" && passwordTextField.text != "" && repeatTextField.text != "" {
            
            if passwordTextField.text == repeatTextField.text {
                
                // segue finish registe
                registerUser()
                
            } else {
                ProgressHUD.showError("パスワードが一致しません")
            }
            
        } else {
            ProgressHUD.showError("全項目を埋めてください")
            
        }
    }
    
  func loginUser() {
        ProgressHUD.show("Login...")
        
        FUser.loginUserWith(email: emailaTextField.text!, password: passwordTextField.text!) { (error) in
            
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            
            self.goToApp()
        }
    }
    
    func registerUser() {
        
        performSegue(withIdentifier: "welocomeToFinishRegistration", sender: self)
        
        cleanTextField()
        dissmisKeyBoard()
    }
    
    func goToApp() {
        ProgressHUD.dismiss()
        
        cleanTextField()
        dissmisKeyBoard()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        //present APP
        
        let mainVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainApplication") as! UITabBarController
        self.present(mainVC, animated: true,completion: nil)
        
        
    }
    
    //MARK: clean
    
    @IBAction func backGroundTapped(_ sender: UITapGestureRecognizer) {
        dissmisKeyBoard()
    }
    
    func dissmisKeyBoard() {
        self.view.endEditing(true)
    }
    
    func cleanTextField() {
        
        emailaTextField.text = ""
        passwordTextField.text = ""
        repeatTextField.text = ""
    }
    //MARK: perform segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "welocomeToFinishRegistration" {
            let vc = segue.destination as! FinishRegistrationViewController
            
            vc.email = emailaTextField.text!
            vc.password = passwordTextField.text!
        }
    }
    
    
}
