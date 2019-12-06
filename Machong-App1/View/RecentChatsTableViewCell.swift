//
//  RecentChatsTableViewCell.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/11/30.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import UIKit

protocol RecentChatsTableViewCellDelegate {
    func didAvatarTapped(indexPath : IndexPath)
}

class RecentChatsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullnamelabel: UILabel!
    
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var messageCounterLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var messageCounterBackgroundView: UIView!
    
    var indexPath : IndexPath!
    var delegate : RecentChatsTableViewCellDelegate?
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
    
    func generateCell(recentChat: NSDictionary, indexPath : IndexPath) {
        self.indexPath = indexPath
        
        self.fullnamelabel.text = recentChat[kWITHUSERFULLNAME] as? String
        self.lastMessageLabel.text = recentChat[kLASTMESSAGE] as? String
        self.messageCounterLabel.text = recentChat[kCOUNTER] as? String
        
        if let avatarImage = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarImage as! String) { (avatar) in
                self.avatarImageView.image = avatar!.circleMasked
            }
        }
        
        if recentChat[kCOUNTER] as! Int != 0 {
            self.messageCounterLabel.text = "\(recentChat[kCOUNTER] as! Int)"
            self.messageCounterBackgroundView.isHidden = false
            self.messageCounterLabel.isHidden = false
            
        } else {
            self.messageCounterBackgroundView.isHidden = true
            self.messageCounterLabel.isHidden = true
        }
        
        var date : Date!
        
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)!
            }
        } else {
            date = Date()
        }
        
        self.dateLabel.text = timeElapsed(date: date)

    }
    
    @objc func avatarTapped() {
        delegate?.didAvatarTapped(indexPath: indexPath)
    }

}
