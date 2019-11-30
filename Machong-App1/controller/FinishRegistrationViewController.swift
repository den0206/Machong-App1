//
//  FinishRegistrationViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/28.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import ProgressHUD

class FinishRegistrationViewController: UIViewController {
    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var surNameTextField: UITextField!

    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var cityTextField: UITextField!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    var email : String!
    var password : String!
    var avatarImage : UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(email!, password!)
      
    }
    
    //MARK: IBActions
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        dissmisKeyBoard()
        ProgressHUD.show("Loading")
        
        if nameTextField.text != "" && surNameTextField.text != "" && countryTextField.text != "" && cityTextField.text != "" && phoneTextField.text != "" {
            
            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surNameTextField.text!) { (error) in
                
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error?.localizedDescription)
                }
                
                // no error
                
                self.registerUser()
                
                
            }
            
        } else {
            ProgressHUD.showError("全ての項目を埋めてください")
            return
        }
        
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        
        dissmisKeyBoard()
        cleanTextField()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func registerUser() {
        
        let fullName = nameTextField.text! + " " + surNameTextField.text!
        
        var tempDictionary : Dictionary = [
            kFIRSTNAME :  nameTextField.text!,
            kLASTNAME : surNameTextField.text!,
            kFULLNAME : fullName,
            kCOUNTRY : countryTextField.text!,
            kCITY : cityTextField.text!,
            kPHONE : phoneTextField.text!] as [String : Any]
        
        if avatarImage == nil {
            
            imageFromInitials(firstName: nameTextField.text!, lastName: surNameTextField.text) { (avatarInitial) in
                
                let avatarDate = avatarInitial.jpegData(compressionQuality: 0.5)
                let avatar = avatarDate?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                tempDictionary[kAVATAR] = avatar
                
                self.finishRegistration(withValue: tempDictionary)
                
            }
            
        } else {
            
            let avatarDate = avatarImage?.jpegData(compressionQuality: 0.5)
            let avatar = avatarDate?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            tempDictionary[kAVATAR] = avatar
            
            self.finishRegistration(withValue: tempDictionary)
        }
        
    }
    
    func finishRegistration(withValue : [String : Any]) {
        
        updateCurrentUserInFirestore(withValues: withValue) { (error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError(error?.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
            
            self.goToApp()
            
        }
    }
    
    
    //MARK: clean
    
    func dissmisKeyBoard() {
        self.view.endEditing(true)
    }
    
    func cleanTextField() {
        
        nameTextField.text = ""
        surNameTextField.text = ""
        countryTextField.text = ""
        cityTextField.text = ""
        phoneTextField.text = ""
        
    }
    
    func goToApp() {
        
        cleanTextField()
        dissmisKeyBoard()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])

        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainApplication") as! UITabBarController
        
        self.present(mainView,animated: true,completion: nil)
    }
    

}
