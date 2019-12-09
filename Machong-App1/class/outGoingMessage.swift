//
//  outGoingMessage.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/07.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import Foundation

class OutGoingMessage {
    
    let messageDictionary : NSMutableDictionary
    
     // text
    
    init(message :String, senderId : String, senderName : String, status : String,
         type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, senderId,senderName,status,type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying,kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    //MARK: functions
    
    
    func sendMessage(chatRoomId : String, messageDictionary :NSMutableDictionary, membersId : [String], memberToPush : [String]) {
        
        let messageId = UUID().uuidString
        
        let date = dateFormatter().string(from: Date())
        
        messageDictionary[kMESSAGEID] = messageId
        messageDictionary[kDATE] = date
        
        for memberid in membersId {
            reference(.Message).document(memberid).collection(chatRoomId).document(messageId).setData(messageDictionary as! [String : Any])
        }
        
        updateRecent(chatRoomId: chatRoomId, lastMessage: messageDictionary[kMESSAGE] as! String)
        
    }
    
    // update ReadDate
    
    class func updateMessage(withId : String, chatRoomId : String, memberIds : [String]) {
        
        let readDate = dateFormatter().string(from: Date())
        let value = [kSTATUS : kREAD, kREADDATE : readDate]
        
        for userId in memberIds {
            reference(.Message).document(userId).collection(chatRoomId).document(withId).getDocument { (snapshot, error) in
                
                guard let snapshot = snapshot else {return}
                
                if snapshot.exists {
                    reference(.Message).document(userId).collection(chatRoomId).document(withId).updateData(value)
                }
            }
        }
        
    }
}
