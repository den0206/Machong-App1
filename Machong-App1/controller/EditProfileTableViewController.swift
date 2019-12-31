//
//  EditProfileTableViewController.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/30.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class EditProfileTableViewController: UITableViewController {
    
    @IBOutlet weak var saveButtonOutlet: UIBarButtonItem!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var surNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet var avatarTapGestureRecognizer: UITapGestureRecognizer!
    
    var avatarImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        setupUI()
        

        
    }
    
    //MARK: IBActions
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        
        if firstNameTextField.text != "" && surNameTextField.text != "" && emailTextField.text != "" {
            
            ProgressHUD.show("Saving...")
            saveButtonOutlet.isEnabled = false
            
            let fullname = firstNameTextField.text! + " " + surNameTextField.text!
            var withValues = [kFIRSTNAME : firstNameTextField.text!,
                              kLASTNAME :surNameTextField.text!,
                              kFULLNAME : fullname,
                              kEMAIL : emailTextField.text!]
            
            if avatarImage != nil {
                let avatarData = avatarImage!.jpegData(compressionQuality: 0.3)
                let avatarString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                withValues[kAVATAR] = avatarString
            }
            
            updateCurrentUserInFirestore(withValues: withValues) { (error) in
                
                if error != nil {
                    DispatchQueue.main.async {
                        ProgressHUD.showError(error?.localizedDescription)
                        print("couldn't update user \(error!.localizedDescription)")
                    }
                    self.saveButtonOutlet.isEnabled = true
                    return
                }
                ProgressHUD.showSuccess("Save!")
                
                self.saveButtonOutlet.isEnabled = true
                self.navigationController?.popViewController(animated: true)
            }
            
        } else {
            ProgressHUD.showError("全ての項目を埋めてください。")
        }
        
    }

    // MARK: - Table view data source

    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: Setup UI
    
    func setupUI() {
        
        let currentUser = FUser.currentUser()
        
        avatarImageView.isUserInteractionEnabled = true
        
        firstNameTextField.text = currentUser?.firstname
        surNameTextField.text = currentUser?.lastname
        emailTextField.text = currentUser?.email
        
        if currentUser?.avatar != "" {
            imageFromData(pictureData: currentUser!.avatar) { (avatar) in
                
                if avatar != nil {
                    avatarImageView.image = avatar?.circleMasked
                }
                
            }
        }
    }

}

//MARK: Imagepicker Delegate

extension EditProfileTableViewController : ImagePickerDelegate {
    
    @IBAction func avatarTap(_ sender: Any) {
          
          let imagePicker = ImagePickerController()
          imagePicker.delegate = self
          imagePicker.imageLimit = 1
          
          present(imagePicker,animated: true,completion: nil)
      }
    
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = images.first?.circleMasked
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
