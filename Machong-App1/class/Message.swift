import Foundation
import CoreLocation
import MessageKit
import AVFoundation



private struct MockLocationItem: LocationItem {

    var location: CLLocation
    var size: CGSize

    init(location: CLLocation) {
        self.location = location
        self.size = CGSize(width: 240, height: 240)
    }
}

struct MockMediaItem: MediaItem {
   
    
  
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    var fileUrl: NSURL?
   
    

    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}

struct MockVideoItem: MediaItem {

    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    var fileUrl : NSURL?
    
    init(withFileUrl : NSURL, thumbnail : UIImage) {
       self.fileUrl = withFileUrl
       self.size = CGSize(width: 240, height: 240)
       self.placeholderImage = UIImage()
        self.image = thumbnail
    
   }
    
    init(withFileUrl : NSURL) {
        self.fileUrl = withFileUrl
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
     
    }
    
    
}

struct MockAudioItem : AudioItem {
    
    var duration: Float
  
    var fileUrl: NSURL
    
    var size: CGSize
    
    var audioData : Data?
    
    init(fileUrl : NSURL) {
        self.fileUrl = fileUrl
     
        self.size = CGSize(width: 160, height: 35)
        // compute duration
        let audioAsset = AVURLAsset(url: fileUrl as URL)
        self.duration = Float(CMTimeGetSeconds(audioAsset.duration))
        

        
    }
    
    
}



internal struct Message: MessageType {
    var sender: SenderType
    var messageId: String
 
    var sentDate: Date
    var kind: MessageKind
    
   
    
    
    

    private init(kind: MessageKind, sender: Sender, messageId: String, date: Date) {
        self.kind = kind
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
        
    }

    init(text: String, sender: Sender, messageId: String, date: Date) {
        self.init(kind: .text(text), sender: sender, messageId: messageId, date: date)
    }

    init(attributedText: NSAttributedString, sender: Sender, messageId: String, date: Date) {
        self.init(kind: .attributedText(attributedText), sender: sender, messageId: messageId, date: date)
    }

    init(media : MockMediaItem, sender: Sender, messageId: String, date: Date) {
        self.init(kind: .photo(media), sender: sender, messageId: messageId, date: date)
    }

    init(thumbnail: UIImage, sender: Sender, messageId: String, date: Date, fileUrl : NSURL) {
        var mediaItem = MockMediaItem(image: thumbnail)
        mediaItem.fileUrl = fileUrl
        self.init(kind: .video(mediaItem), sender: sender, messageId: messageId, date: date)
    }

    init(location: CLLocation, sender: Sender, messageId: String, date: Date) {
        let locationItem = MockLocationItem(location: location)
        self.init(kind: .location(locationItem), sender: sender, messageId: messageId, date: date)
    }

    init(emoji: String, sender: Sender, messageId: String, date: Date) {
        self.init(kind: .emoji(emoji), sender: sender, messageId: messageId, date: date)
    }
    
    init(media : MockVideoItem, sender: Sender, messageId: String, date: Date) {
        self.init(kind: .video(media), sender: sender, messageId: messageId, date: date)
    }
    
    init(audioItem : MockAudioItem , sender: Sender, messageId: String, date: Date) {
        self.init(kind: .audio(audioItem), sender: sender, messageId: messageId, date: date)
    }
}

