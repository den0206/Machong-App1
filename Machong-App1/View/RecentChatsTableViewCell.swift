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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

 
    }

}
