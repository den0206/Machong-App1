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
        case kPICTURE :
            message = createPictureMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomID)
            
        case kVIDEO :
            message = createVideoMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomID)
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
    
    //MARK: Picture Message
    
    func createPictureMessage(messageDictionary : NSDictionary, chatRoomId : String) -> Message? {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userid = messageDictionary[kSENDERID] as? String
        let messageId = messageDictionary[kMESSAGEID] as? String
        
     
        let date : Date!
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count !=  14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
            
        }
        
        let image = downLoadImage(imageUrl: messageDictionary[kPICTURE] as! String)
        
        if image != nil {
            return Message(image: image!, sender: Sender(senderId: userid!, displayName: name!), messageId: messageId!, date: date)
        } else {
            print("写真が見つかりません")
            
            // noimagePalceholder picture Message
            
//            let errorPicture = UIImage(named: "error")
//            return Message(image: errorPicture, sender: Sender(senderId: userid!, displayName: name!), messageId: messageId!, date: date)
            return nil
        }

    }
    
    //MARK: Video Message
    func createVideoMessage(messageDictionary : NSDictionary, chatRoomId : String) -> Message?{
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userid = messageDictionary[kSENDERID] as? String
        let messageId = messageDictionary[kMESSAGEID] as? String
        
        
        let date : Date!
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count !=  14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        let videoURL = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        var videoItem = MockVideoItem(withFileUrl: videoURL)
        
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String) { (isRadyToPlay, filename) in
            
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectry(filename: filename))
            videoItem.fileUrl = url
            
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String) { (image) in
                videoItem.image = image
            }
        }
        
        if videoItem.fileUrl != nil && videoItem.image != nil {
            return Message(media: videoItem, sender: Sender(senderId: userid!, displayName: name!), messageId: messageId!, date: date)
        } else {
            return nil
            
            
            // noimagePalceholder picture Message
            
        }
        
    }
}
