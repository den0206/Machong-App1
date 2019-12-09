//
//  inComingMessage.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/07.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import Foundation
import MessageKit

class InComingMessage {
    
    var collectionView : MessagesCollectionView
    
    init(collectionView_ : MessagesCollectionView ) {
        collectionView = collectionView_
    }
    
    func createMessage(messageDictionary : NSDictionary, chatRoomID : String) -> Message? {
        var message : Message?
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kTEXT:
            message = creatTextMessage(messageDictionay: messageDictionary, chatRoomId: chatRoomID)
        default:
            print("Typeがわかりません")
        }
        
        if message != nil {
            
            return message
        }
        
        return nil
    }
    
    //MARK: Text Message
    
    func creatTextMessage(messageDictionay : NSDictionary, chatRoomId : String ) -> Message {
        
        let name = messageDictionay[kSENDERNAME] as? String
        let userid = messageDictionay[kSENDERID] as? String
        let messageId = messageDictionay[kMESSAGEID] as? String
        
        var date : Date!
        
        if let created = messageDictionay[kDATE] {
            if (created as! String).count !=  14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        let text = messageDictionay[kMESSAGE] as! String
        
        return Message(text: text, sender: Sender(senderId: userid!, displayName: name!), messageId: messageId!, date: date)
    }
}
