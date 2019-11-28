//
//  FinishRegistrationViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/28.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit

class FinishRegistrationViewController: UIViewController {
    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var surNameTextField: UITextField!

    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var cityTextField: UITextField!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    var email : String!
    var password : String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(email!, password!)
      
    }
    
    //MARK: IBActions
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        
        dissmisKeyBoard()
        cleanTextField()
        
        self.dismiss(animated: true, completion: nil)
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
    

}
