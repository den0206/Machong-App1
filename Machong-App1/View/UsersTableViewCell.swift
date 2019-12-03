//
//  UsersTableViewCell.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/30.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit

protocol UsersTabeleViewCellDelagate {
    func didtappedAvatar(indexPath : IndexPath)
}

class UsersTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var delegate : UsersTabeleViewCellDelagate?
    var indexPath : IndexPath!
    
    let tapGesture = UITapGestureRecognizer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tapGesture.addTarget(self, action: #selector(avatarTapped))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func generateCellWith(fuser : FUser, indexPath :IndexPath) {
        self.indexPath = indexPath
        self.fullnameLabel.text = fuser.fullname
        
        if fuser.avatar != "" {
            imageFromData(pictureData: fuser.avatar) { (avatar) in
                if avatar != nil {
                    self.avatarImageView.image = avatar?.circleMasked
                }
            }
        }
    }
    
    @objc func avatarTapped() {
        delegate!.didtappedAvatar(indexPath: indexPath)
    }

}
