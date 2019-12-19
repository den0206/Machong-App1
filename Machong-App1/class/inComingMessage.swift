//
//  inComingMessage.swift
//  Machong-App1
//
//  Created by 酒井ゆうき on 2019/12/07.
//  Copyright © 2019 Yuuki sakai. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation
import AVFoundation

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
            self.collectionView.reloadData()
        case kVIDEO :
            message = createVideoMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomID)
            self.collectionView.reloadData()
        case kLOCATION :
            message = createLocationMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomID)
            
        case kAUDIO :
            message = createAudioMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomID)
            self.collectionView.reloadData()
           
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
        let thumbnail = downloadImageFromData(pictureData: messageDictionary[kPICTURE] as! String)
        
        var videoItem = MockVideoItem(withFileUrl: videoURL, thumbnail: thumbnail!)
   
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String) { (isRadyToPlay, filename) in
            
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectry(filename: filename))
            videoItem.fileUrl = url
            
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String) { (image) in
                if image != nil {
                     videoItem.image = image
                }
                self.collectionView.reloadData()
            }
            self.collectionView.reloadData()
        }
        
        if videoItem.fileUrl != nil && videoItem.image != nil {
            return Message(media: videoItem, sender: Sender(senderId: userid!, displayName: name!), messageId: messageId!, date: date)
        } else {
            return nil
            
            
            // noimagePalceholder picture Message
            
        }
        
    }
    
    func createAudioMessage(messageDictionary : NSDictionary, chatRoomId : String) -> Message {

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
        
        let audioUrl = NSURL(fileURLWithPath: messageDictionary[kAUDIO] as! String)
        var audioItem = MockAudioItem(fileUrl: audioUrl)
        
        
        
        downloadAudio(audioUrl: messageDictionary[kAUDIO] as! String) { (audioLink) in
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectry(filename: audioLink))
            audioItem.fileUrl = url

            
            let audioData = try? Data(contentsOf: url as URL)
            audioItem.audioData = audioData!
           
        }
        
        
        
        return Message(audioItem: audioItem, sender: Sender(senderId: userid!, displayName: name!), messageId: messageId!, date: date)



    }
    
    //MARK: Location Message
    
    func createLocationMessage(messageDictionary : NSDictionary, chatRoomId : String) -> Message? {

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
        
        let lat = messageDictionary[kLATITUDE] as? Double
        let long = messageDictionary[kLONGITUDE] as? Double
        
        let location : CLLocation? = CLLocation(latitude: lat!, longitude: long!)
        
        if location != nil {
            return Message(location: location!, sender: Sender(senderId: userid!, displayName: name!), messageId: messageId!, date: date)
        } else {
            return nil
        }
        
      
        
    }
}

