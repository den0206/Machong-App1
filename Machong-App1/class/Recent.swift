//
//  Recent.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/01.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import Foundation

func startPrivateChat(user1 : FUser, user2 : FUser) -> String {
    
    let userId1 = user1.objectId
    let userId2 = user2.objectId
    
    var chatRoomId = ""
    
    let value = userId1.compare(userId2).rawValue
    
//    print(value)
    
    if value < 0 {
        chatRoomId = userId1 + userId2
    } else {
        chatRoomId = userId2 + userId1
    }
    
    let members = [userId1,userId2]
    
//    print(chatRoomId)
    createRecentChat(members: members, chatRoomId: chatRoomId, withUserName: "", type: kPRIVATE, users: [user1, user2], avatarofGroup: nil)
    
    return chatRoomId
    
    
}

func createRecentChat(members : [String], chatRoomId : String, withUserName: String, type: String, users : [FUser]?,avatarofGroup : String?) {
    
    var tempMembers = members
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else {return}
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                
                let currentRecent = recent.data() as NSDictionary
                
                if let currentUserId = currentRecent[kUSERID] {
                    if members.contains(currentUserId as! String) {
                        tempMembers.remove(at: tempMembers.firstIndex(of: currentUserId as! String)!)
                    }
                }
            }
        }
        
        for userId in tempMembers{
            createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserName: withUserName, type: type, users: users, avatarOfGroup: nil)
            
        }
    }
}

func createRecentItem(userId : String, chatRoomId : String, members : [String], withUserName : String, type : String, users : [FUser]?, avatarOfGroup : String?) {
    
    let localReference = reference(.Recent).document()
    let recentId = localReference.documentID
    
    let date = dateFormatter().string(from: Date())
    
    var recent : [String : Any]!
    
   
    
    if type == kPRIVATE {
        
        // for Private
        
        var withUser : FUser?
        
        if users != nil && users!.count > 0 {
            
            if userId == FUser.currentId() {
                withUser = users?.last!
            } else {
                withUser = users?.first!
            }
        }
        
        recent = [kRECENTID : recentId,
                  kUSERID : userId,
                  kCHATROOMID : chatRoomId,
                  kMEMBERS : members,
                  kMEMBERSTOPUSH : members,
                  kWITHUSERFULLNAME : withUser!.fullname,
                  kWITHUSERUSERID : withUser!.objectId,
                  kLASTMESSAGE : "",
                  kCOUNTER : 0,
                  kDATE : date,
                  kTYPE : type,
                  kAVATAR : withUser!.avatar ] as [String : Any]
        
        
    } else {
        // for Group
    }
    
    localReference.setData(recent)
    
}

func restartRecentChat(recent : NSDictionary) {
    
    // for private
    
    if recent[kTYPE] as! String == kPRIVATE {
        createRecentChat(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserName: FUser.currentUser()!.firstname, type: kPRIVATE, users: [FUser.currentUser()!], avatarofGroup: nil)
    }
    
    // for Group
}

func updateRecent(chatRoomId : String, lastMessage : String) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else {return}
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                
                let currentRecent = recent.data() as NSDictionary
                
                if currentRecent[kUSERID] as? String == FUser.currentId() {
                    updateRecentItem(recent: currentRecent, lastMessage: lastMessage)
                }
                
            }
        }
        
    }
}

func updateRecentItem(recent : NSDictionary, lastMessage : String) {
    
    let date = dateFormatter().string(from: Date())
    
    var counter = recent[kCOUNTER] as! Int
    
    if recent[kUSERID] as? String == FUser.currentId() {
        counter += 1
    }
    
    let values = [kLASTMESSAGE : lastMessage, kCOUNTER : counter, kDATE : date] as [String : Any]
    
    reference(.Recent).document(recent[kCHATROOMID] as! String).updateData(values)
    
    
    
}
